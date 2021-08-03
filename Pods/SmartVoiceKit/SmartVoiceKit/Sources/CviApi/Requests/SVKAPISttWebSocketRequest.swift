//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2020 Orange
//
// This software is confidential and proprietary information of Orange.
// You are not allowed to disclose such Confidential Information nor to copy, use,
// modify, or distribute it in whole or in part without the prior written
// consent of Orange.
//
// Author: The current developers of this code can be
// found in the authors.txt file at the root of the project
//
// Software description: Smart Voice Kit is the iOS SDK that allows to
// integrate the Smart Voice Hub voice assistant into your app.
//
// Module description: The main framework for the Smart Voice Kit is the iOS SDK
// to integrate the Smart Voice Hub Audio Assistant inside your App.
//

import Foundation
import Starscream

public protocol SVKAPISttDelegate {

    func didConnect()
    func didDisconnect()
    func didReceiveMessage(_ message: SVKSttWsMessage,rawText: String)
    func didReceiveData() // mettre les params
}

public class SVKAPISttWebSocketRequest: WebSocketDelegate, WebSocketAdvancedDelegate {

    private var url: URL?
    public var delegate: SVKAPISttDelegate?
    var webSocket: WebSocket?
    var defaultCodecFormat: String
    /// The sessionId for ping pong conversations
    var sessionId: String?
    
    var isReady = false
    var isCancelRequest = false

    public init(codec: String, sessionId: String? = nil) {
        let url = SVKAPIClient.baseURL + "/cvi/dm/api/v2/invoke/audio/json"
        self.url = Foundation.URL(string: url)
        self.defaultCodecFormat = codec
        self.sessionId = sessionId
    }

    public func connect() {
        guard let url = self.url else {
            delegate?.didDisconnect()
            return
        }
        guard let token = SVKAPIClient.shared.getToken() else {
            delegate?.didDisconnect()
            return
        }

        SVKLogger.debug("---------> URL \(String(describing: self.url))")
        SVKLogger.debug("---------> token  \(String(describing: SVKAPIClient.shared.token))")
        // the api key is no longer visible
        
        var httpRequest = URLRequest(url: url)
        //        sRequest = myRequest

        httpRequest.setValue(SVKAPIClient.apiKey, forHTTPHeaderField: "apikey")
        httpRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        httpRequest.setValue("1", forHTTPHeaderField: "X-B3-Flags")
        httpRequest.timeoutInterval = TimeInterval(30)
        httpRequest.allowsCellularAccess = true

        // TODO update the log for httpRequest to remove ApiKey
        SVKLogger.debug("---------> Request \(httpRequest)")

        webSocket = WebSocket(request: httpRequest)
        webSocket?.enableCompression = false
        webSocket?.delegate = self
        webSocket?.disableSSLCertValidation = false
        webSocket?.callbackQueue = DispatchQueue(label: "webSocket.callbackQueue")
        webSocket?.connect()
    }

    public func write(data: Data, completion: (() -> Void)?) {
        if (webSocket?.isConnected ?? false) && isReady {
            webSocket?.write(data: data, completion: completion)
        } else {
            completion?()
        }
    }
    
    public func cancelRequest() {
        webSocket?.disconnect()
        delegate = nil
        isCancelRequest = true
    }

    public func disconnect() {
        webSocket?.disconnect()
    }

    public func stopReconize() {
        let audioMsg = SVKSttAudioEndWsMessage(type: "audio_end")
        if let data = try? JSONEncoder().encode(audioMsg),
            let jsonString = String(data: data, encoding: .utf8) {
            SVKLogger.debug(jsonString)
            webSocket?.write(string: jsonString)
        }
    }
    
    public func websocketDidConnect(socket _: WebSocketClient) {
        SVKLogger.debug("----------> websocketDidConnect (socket: WebSocketClient)")
        let mdata = SVKAPIClient.clientMetadata
        let serial = SVKSttClientMetaData(serialNumber: SVKUserIdentificationManager.shared.serialNumber,deviceName: SVKUserIdentificationManager.shared.deviceName ,data: mdata)
        let deviceCapabilities = SVKSttDeviceCapabilities(ssml: true, ncs: true)
        let enableBos = self.defaultCodecFormat == "wav/16khz/16bit/1" ? true : false

        let connectWsMessage = SVKSttConnectWsMessage(type: "connect", clientMetadata: serial, deviceCapabilities: deviceCapabilities, wakeUpWord: nil, enableBoS: enableBos,
                                                     sessionId: self.sessionId, includeIntent: true, includeSkill: true, enablePartialTranscription: true)
        

        if let data = try? JSONEncoder().encode(connectWsMessage), let jsonString = String(data: data, encoding: .utf8) {
            SVKLogger.debug(jsonString)
            webSocket?.write(string: jsonString)
        }
        let audioMsg = SVKSttAudioBeginWsMessage(type: "audio_begin", codec: self.defaultCodecFormat)
        
        if let data = try? JSONEncoder().encode(audioMsg), let jsonString = String(data: data, encoding: .utf8) {
            SVKLogger.debug(jsonString)
            webSocket?.write(string: jsonString)
        }

        isReady = true
        delegate?.didConnect()
        
        if isCancelRequest {
            webSocket?.disconnect()
        }
    }

    public func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        SVKLogger.debug("----------> websocketDidDisconnect \(String(describing: error))")
        DispatchQueue.main.async {
            self.delegate?.didDisconnect()
        }
    }

    public func websocketDidReceiveMessage(socket _: WebSocketClient, text: String){
        SVKLogger.debug("----------> websocketDidReceiveMessage \(text)")
        let (response, error) = self.decode(SVKSttWsMessage.self, from: text)
        if error == nil, let response = response {
            DispatchQueue.main.async {
                self.delegate?.didReceiveMessage(response, rawText: text)
            }
        }
    }

    public func websocketDidReceiveData(socket _: WebSocketClient, data _: Data) {
        SVKLogger.debug("----------> websocketDidReceiveData")
        DispatchQueue.main.async {
            self.delegate?.didReceiveData()
        }
    }

    public func websocketDidConnect(socket: WebSocket) {
        SVKLogger.debug("----------> websocketDidConnect \(socket)")
    }

    public func websocketDidDisconnect(socket _: WebSocket, error: Error?) {
        SVKLogger.debug("----------> websocketDidDisconnect \(String(describing: error))")
    }

    public func websocketDidReceiveMessage(socket _: WebSocket, text _: String, response _: WebSocket.WSResponse) {
        SVKLogger.debug("----------> websocketDidReceiveMessage")
    }

    public func websocketDidReceiveData(socket _: WebSocket, data _: Data, response _: WebSocket.WSResponse) {
        SVKLogger.debug("----------> websocketDidReceiveData")
    }

    public func websocketHttpUpgrade(socket: WebSocket, request: String) {
        SVKLogger.debug("----------> websocketHttpUpgrade \(socket) \(request)")
    }

    public func websocketHttpUpgrade(socket: WebSocket, response: String) {
        SVKLogger.debug("----------> websocketHttpUpgrade \(socket) \(response)")
    }

    func decode<T>(_ type: T.Type, from data: String) -> (T?, Error?) where T: Decodable {
        do {
            if let data = data.data(using: .utf8) {
                let decodedObject = try JSONDecoder().decode(type, from: data)
                return (decodedObject, nil)
            }
        } catch let error {
            SVKLogger.error("\(error)")
            SVKLogger.debug(data)
            return (nil, error)
        }
        return (nil, nil)
    }
}
