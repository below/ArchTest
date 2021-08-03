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
import AVFoundation
import AudioToolbox
import Accelerate

protocol SVKSpeechTransactionDelegate {    
    func transactionDidFinish(_: SVKSpeechTransaction)
    func transactionDidStop(_: SVKSpeechTransaction, with error: Error?)
    func transactionWillStartRecording(_: SVKSpeechTransaction)
    func transactionDidStartRecording(_: SVKSpeechTransaction)
    func transaction(_: SVKSpeechTransaction, didReceive message: SVKSttWsMessage, rawText: String)
// TODO remove this var
    var sessionId: String? { get }
// TODO remove this function
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?)
}

protocol SVKSpeechTransactionExchangeDelegate {
    var sessionId: String? { get }
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?)
}


class SVKSpeechTransaction: NSObject {
    
    var delegate: SVKSpeechTransactionDelegate?
    var exchangeDelegate: SVKSpeechTransactionExchangeDelegate?
    var sttWebSocketRequest: SVKAPISttWebSocketRequest?

    let chunkMaxSize = 1280
    var converter: AVAudioConverter?
    var captureSession: AVCaptureSession?

    let audioEngine = AVAudioEngine()
    var audioLevel: Float? = nil

    var defaultCodecFormat: String = ""
    var isWaveFormat = false
    var dataChunkId = 0
    
    var isFinished = false
    
    init(delegate: SVKSpeechTransactionDelegate) {
        self.delegate = delegate
    }

    init(transactionDelegate: SVKSpeechTransactionDelegate,exchangeDelegate: SVKSpeechTransactionExchangeDelegate) {
        self.delegate = transactionDelegate
        self.exchangeDelegate = exchangeDelegate
    }

    public func setupWebSocket(completionHandler: @escaping (NSError?) -> Void) {

        self.exchangeDelegate?.supportedCodecFormat(completionHandler: { (codec) in
            if let codec = codec {
                self.defaultCodecFormat = codec
                if self.defaultCodecFormat == "wav/16khz/16bit/1" {
                    self.isWaveFormat = true
                }
                self.sttWebSocketRequest = SVKAPISttWebSocketRequest(codec: self.defaultCodecFormat,sessionId: self.exchangeDelegate?.sessionId)
                self.sttWebSocketRequest?.delegate = self
                self.sttWebSocketRequest?.connect()
                completionHandler(nil)
            } else {
                let error =  NSError(domain: "codec is nil", code: 0, userInfo: [:])
                completionHandler(error)
            }
        })
        
    }

    /// The audio session category to use
    internal var audioSessionCategory: AVAudioSession.Category = .playAndRecord {
        didSet {
            do {
                try AVAudioSession.sharedInstance().setCategory(audioSessionCategory, mode: .default, options: [.allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch let error {
                SVKLogger.error("\(error)")
            }
        }
    }

    func recognize() {
        audioSessionCategory = .playAndRecord
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        // The user has previously granted access to the mic.
        case .authorized:
            setupWebSocket() { error in
                if error != nil {
                    DispatchQueue.main.safeAsync {
                        self.delegate?.transactionDidStop(self, with: error)
                    }
                } else {
                    DispatchQueue(label: "com.orange.stt.queue").async {
                        self.setupCaptureSession()
                    }
                }
            }
        
        // The user has not yet been asked for mic access.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    self.recognize()
                } else {
                    let userInfo = ["message" : "Failed to get access, the user refuses"]
                    let error = NSError(domain: "com.djingoconversationkit.speech.transaction", code: 9500, userInfo: userInfo)
                    DispatchQueue.main.safeAsync {
                        self.delegate?.transactionDidStop(self, with: error)
                    }
                }
            }

        default:
            
            
            let alert = UIAlertController(title: "DCalert.audio.rightsaccess.title".localized, message: "DCalert.audio.rightsaccess.message".localized, preferredStyle: .alert)
            
            
            let CancelAction = UIAlertAction(title: "DCalert.audio.rightsaccess.cancel".localized, style: .default, handler: { (action) in
                let userInfo = ["message" : "Failed to get access to the mic unknown error"]
                let error = NSError(domain: "com.djingoconversationkit.speech.transaction", code: 9000, userInfo: userInfo)
                DispatchQueue.main.safeAsync {
                    self.delegate?.transactionDidStop(self, with: error)
                }
            })
            
            let settingsAction = UIAlertAction(title: "DCalert.audio.rightsaccess.settings".localized, style: .default, handler: { (action) in
                let userInfo = ["message" : "Failed to get access to the mic unknown error"]
                let error = NSError(domain: "com.djingoconversationkit.speech.transaction", code: 9000, userInfo: userInfo)
                DispatchQueue.main.safeAsync {
                    let urlString =  UIApplication.openSettingsURLString
                    if let url = URL(string: urlString),
                        UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:])
                    }
                    self.delegate?.transactionDidStop(self, with: error)
                }
            })
            alert.addAction(CancelAction)
            alert.addAction(settingsAction)
            
            DispatchQueue.main.async {
                if let presented = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
                    presented.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                }

            }
            
        }
    }
    
    func cancelRequest() {
        sttWebSocketRequest?.cancelRequest()
        delegate?.transactionDidStop(self, with: nil)
        self.delegate = nil
    }
    
    func cancel() {
        sttWebSocketRequest?.disconnect()
        delegate?.transactionDidStop(self, with: nil)
        self.delegate = nil
    }

    public func stopRecognize() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        sttWebSocketRequest?.stopReconize()
    }
    func setupCaptureSession() {

        delegate?.transactionWillStartRecording(self)
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: AVAudioChannelCount(1), interleaved: false),
            let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                let userInfo = ["message" : "Failed to setup the capture session"]
                let error = NSError(domain: "com.djingoconversationkit.speech.transaction", code: 6000, userInfo: userInfo)
                DispatchQueue.main.safeAsync {
                    self.delegate?.transactionDidStop(self, with: error)
                }
                return
        }
        let inf = inputNode.inputFormat(forBus: 0)
        if inf.sampleRate == 0 {
            DispatchQueue.main.safeAsync {
                let currentRootVc = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                let title:String = "DC.error.micro.notAvailable".localized

                let firstStepAS:UIAlertController = UIAlertController(title: title, message: "", preferredStyle: .alert)
                currentRootVc?.present(firstStepAS, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3500), execute: {
                    firstStepAS.dismiss(animated: true, completion: nil)
                })
            }
            let userInfo = ["message" : "Failed to setup the capture session"]
            let error = NSError(domain: "com.djingoconversationkit.speech.transaction", code: 7000, userInfo: userInfo)
            DispatchQueue.main.safeAsync {
                self.delegate?.transactionDidStop(self, with: error)
            }
            return
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, time in
            var newBufferAvailable = true

            // First block we should send the wav header
            if self.isWaveFormat, self.dataChunkId == 0 {
                self.sttWebSocketRequest?.write(data: Data().wrapIntoWAVContainer(), completion: nil)
           }

            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            let frameCapacity = AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity)!

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)

            // 16kHz buffers!
            let channelCount = 1 // given PCMBuffer channel count is 1
            let channels = UnsafeBufferPointer(start: convertedBuffer.int16ChannelData, count: channelCount)
            let exportData = NSData(bytes: UnsafeMutableRawPointer(channels[0]), length: Int(convertedBuffer.audioBufferList.pointee.mBuffers.mDataByteSize))
            var seek = 0
            let pointerData = exportData.bytes // as Unsa

            repeat {
                let nb_copy = Int(min((Int(convertedBuffer.audioBufferList.pointee.mBuffers.mDataByteSize) - seek), self.chunkMaxSize))
                let sendData = NSData(bytes: pointerData + seek, length: Int(nb_copy))

                self.sttWebSocketRequest?.write(data: sendData as Data, completion: nil)
                seek += nb_copy
            } while seek < convertedBuffer.audioBufferList.pointee.mBuffers.mDataByteSize

            self.audioLevel = buffer.audioLevel
            self.dataChunkId += 1
        }
       
        delegate?.transactionDidStartRecording(self)
    }
}

extension SVKSpeechTransaction: SVKAPISttDelegate {
    
    func didReceiveMessage(_ message: SVKSttWsMessage, rawText: String) {
        DispatchQueue.main.safeAsync {
            self.delegate?.transaction(self, didReceive: message,rawText: rawText)
        }
    }

    func didConnect() {
        do {
            // The mainMixerNode needs to be access before start the engine to prevents crashs
            // https://forums.developer.apple.com/thread/44833
            let _ = audioEngine.mainMixerNode
            
            try audioEngine.start()
            
        } catch let error {
            
            SVKLogger.error("\(error)")
            audioEngine.inputNode.removeTap(onBus: 0)

            self.sttWebSocketRequest = nil
            isFinished = true
            delegate?.transactionDidStop(self, with: error)
        }
    }

    func didDisconnect() {
        isFinished = true
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        DispatchQueue.main.safeAsync {
            self.delegate?.transactionDidFinish(self)
        }
    }

    func didReceiveData() {
    }
}

extension AVAudioPCMBuffer {
    var audioLevel: Float {
        guard let channelData = floatChannelData else {
            return 0
        }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = Swift.stride(from: 0,
                                           to: Int(frameLength),
                                           by: stride).map { channelDataValue[$0] }
        
        
        let rms = channelDataValueArray.map{ $0 * $0 }.reduce(0, +) / Float(frameLength)
        let avgPower = 20 * log10(sqrt(rms))
        
        return avgPower
    }
}

extension UIViewController {
    public func topMostViewController() -> UIViewController {
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        
        if let tab = self as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
