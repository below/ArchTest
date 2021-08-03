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

public struct SVKSpeechConfiguration: Codable {
    public enum CodingKeys: String, CodingKey {
        case sttCodecFormat
    }
    public var sttCodecFormat = "wav/16khz/16bit/1"
    
    public init(sttCodecFormat: String) {
        self.sttCodecFormat = sttCodecFormat
    }
    
    /**
     Returns the status of the current structure.
     Check if each field of the structure, except port, is filled.
     If yes, the configuration is valid.
     returns: true if the configuration is valid
     */
    public func isValid() -> Bool {
        return !sttCodecFormat.isEmpty
    }
}

public enum SVKSpeechState {
    case idle
    case running
    case speaking
    case stopping
    case unavailable
}

protocol SVKSpeechObserverDelegate {
    func transactionDidFinish(_: SVKSpeechTransaction)
    func transactionDidStop(_: SVKSpeechTransaction, with error: Error?)
    func transactionWillStartRecording(_: SVKSpeechTransaction)
    func transactionDidStartRecording(_: SVKSpeechTransaction)
    func transaction(_: SVKSpeechTransaction, didReceive message: SVKSttWsMessage, rawText: String)
    func sessionState(_: SVKSpeechState)
    func getHashValue() -> Int
 }


class SVKSpeechSession : SVKSpeechTransactionDelegate {


    private var queue = DispatchQueue.init(label: "startVocalize")
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
    }
    
    func transactionDidFinish(_ transaction: SVKSpeechTransaction) {
        observers.forEach { (observer) in
            observer.transactionDidFinish(transaction)
        }
        if state != .speaking {
            state = .idle
        }
    }
    
    func transactionDidStop(_ transaction: SVKSpeechTransaction, with error: Error?) {
        observers.forEach { (observer) in
            observer.transactionDidStop(transaction,with:error)
        }
        if state != .speaking {
            state = .idle
        }
    }
    
    func transactionWillStartRecording(_ transaction: SVKSpeechTransaction) {
        observers.forEach { (observer) in
            observer.transactionWillStartRecording(transaction)
        }
    }
    
    func transactionDidStartRecording(_ transaction: SVKSpeechTransaction) {
        observers.forEach { (observer) in
            observer.transactionDidStartRecording(transaction)
        }
    }
    
    func transaction(_ transaction: SVKSpeechTransaction, didReceive message: SVKSttWsMessage, rawText: String) {
        observers.forEach { (observer) in
            observer.transaction(transaction, didReceive: message,rawText: rawText)
        }
    }
    
    var sessionId: String?
    
    var transaction: SVKSpeechTransaction?
    
    private init() {
        
    }
    
    public var audioLevel: Float? {
        get {
            guard let audioLevel = transaction?.audioLevel else {
                return nil
            }
            return audioLevel
        }
    }
    
    func recognize(_ exchangeDelegate:SVKSpeechTransactionExchangeDelegate) -> SVKSpeechTransaction? {
        if state == .idle {
            transaction = SVKSpeechTransaction(transactionDelegate: self,exchangeDelegate: exchangeDelegate)
        } else {
            return nil
        }
        state = .running
        transaction?.recognize()
        return transaction
    }
    
    func stopRecognize() {
        transaction?.stopRecognize()
    }
    
    func cancelRequest() {
        transaction?.cancelRequest()
    }
    
    public static let shared = SVKSpeechSession()
    
    private var state = SVKSpeechState.idle {
        didSet {
            DispatchQueue.main.async {
                self.observers.forEach { (observer) in
                    observer.sessionState(self.state)
                }
            }
        }
    }
    
    private var observers :[SVKSpeechObserverDelegate] = []
    
    public func addObserver(_ observer:SVKSpeechObserverDelegate) {
        self.observers.append(observer)
    }
    
    public func removeObserver(_ observer:SVKSpeechObserverDelegate) {
        let index = self.observers.firstIndex(where: { (item) -> Bool in
            if item.getHashValue() == observer.getHashValue() {
                return true
            } else {
                return false
            }
        })
        if let index = index {
            self.observers.remove(at: index)
        }
    }
    func stopVocalize() {
        if state == .speaking {
            SVKAudioPlayer.shared.stop()
            state = .idle
        }
    }
    
    func stopRunning() {
        if state == .running {
            SVKAudioPlayer.shared.stop()
            state = .idle
        }
    }
    
    public func didVocalizeText(_ text: String, stream: Data) {
        SVKLogger.debug("saying text: \(text)")
        
        SVKAudioPlayer.shared.enqueue(stream)
    }
    
    func startVocalize(_ text: String, stream: Data) {
        SVKLogger.debug("saying text: \(text)")
        state = .speaking
        SVKAudioPlayer.shared.stop()
        
        queue.async {
            
            let operationQueue = OperationQueue()
            
            // A speak operation that depends of the vocalized operation
            let speakOperation = BlockOperation {
                let semaphore = SVKAudioPlayer.shared.enqueue(stream)
                semaphore.wait()
                
            }
            operationQueue.addOperation(speakOperation)
            
            // wait for the end of all vocalizations
            operationQueue.waitUntilAllOperationsAreFinished()
            
            self.state = .idle
            /// Notify delegate that Push to talk is completely terminated
            SVKAudioPlayer.shared.resumeSystemMusicPlayer()
        }
    }
    
    func startVocalize(_ descriptions: [SVKBubbleDescription], delegateConversation: SVKConversationProtocol?, completionHandler: @escaping (() -> Void)) {
            state = .speaking
            let dc = delegateConversation
            queue.async {

                let operationQueue = OperationQueue()
                var vocalizedData = [Int : AudioData]()
                var containsAudioController: Bool = false
                
                for (index, description) in descriptions.enumerated() {
                    
                    containsAudioController = description.contentType == .audioController || containsAudioController
                    
                    // only not empty text bubbles are vocalized
                    guard let description = description as? SVKAssistantBubbleDescription,
                        description.contentType == .text || description.contentType == .errorText || description.contentType == .disabledText,
                        let text = description.contentType == .text ? description.invokeResult?.text ?? description.text : description.text,
                        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }
                    
                    // A vocalize block operation
                    let vocalizeOperation = BlockOperation {
                        let semaphore = DispatchSemaphore(value: 0)
                        
                        SVKLogger.debug("vocalizing: '\(text)'")
                        
                        dc?.vocalizeText(text) { data in
                            if data == nil {
                                SVKAnalytics.shared.log(event: "conversation_answer_vocalization_error")
                            }
                            vocalizedData[index] = data
                            semaphore.signal()
                        }
                        _  = semaphore.wait(timeout: .now() + .seconds(30))
                    }
                    operationQueue.addOperation(vocalizeOperation)
                    
                    
                    // A speak operation that depends of the vocalized operation
                    let speakOperation = BlockOperation {
                        if let audioData = vocalizedData[index] {
                            let semaphore = SVKAudioPlayer.shared.enqueue(audioData)
                            semaphore.wait()
                        }
                    }
                    speakOperation.addDependency(vocalizeOperation)
                    
                    operationQueue.addOperation(speakOperation)
                    break
                }
                
                // wait for the end of all vocalizations
                operationQueue.waitUntilAllOperationsAreFinished()
                self.state = self.transaction?.isFinished ?? true ? .idle : .stopping
                
                /// Notify delegate that Push to talk is completely terminated
                SVKAudioPlayer.shared.resumeSystemMusicPlayer(completionHandler)
            }
        }
}
