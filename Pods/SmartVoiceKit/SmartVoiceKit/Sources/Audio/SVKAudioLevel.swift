//
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
public protocol SVKAudioLevelDelegate {
    // notifies the end of the audio session
    func onFinished()
    // returns the sound level
    func getAudio(level: Float)
    // The HashKey allows to identify the observer, if we add a new observer with the same key it will be replaced by the new one.
    func getHashKey() -> String
}
public class SVKAudioLevel {
    // The current speech session
    private var session: SVKSpeechSession?
    // The current speech transaction
    private var transaction: SVKSpeechTransaction?
    //  replace Timer by CADisplayLink (in order to create a smoother animation.)
    /**
     var displayLink: CADisplayLink?
     displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
     displayLink?.add(to: RunLoop.main, forMode: .common)
     displayLink?.isPaused = true
     displayLink?.invalidate()
     */
    
    // A timer for audio level polling
    private var skAudioTimer: Timer?
    public static let shared = SVKAudioLevel()
    
    private var observers :[String:SVKAudioLevelDelegate] = [:]
    
    public func addObserver(_ observer:SVKAudioLevelDelegate) {
        self.observers[observer.getHashKey()] = observer
    }
    
    public func removeObserver(_ observer:SVKAudioLevelDelegate) {
        let index = self.observers.firstIndex(where: { (key,item) -> Bool in
            if item.getHashKey() == observer.getHashKey() {
                return true
            } else {
                return false
            }
        })
        if let index = index {
            self.observers.remove(at: index)
        }
    }
    
    
    init() {
        session = SVKSpeechSession.shared
        session?.addObserver(self)
    }
    @objc private func collectAudioLevel() {
        if let audioLevel = SVKSpeechSession.shared.audioLevel {
            observers.forEach { (_,observer) in
                observer.getAudio(level: -20 + audioLevel)
            }
        }
    }
    
    public func mineAudioLevel(){
        skAudioTimer?.invalidate()
        skAudioTimer = nil
        
        if skAudioTimer == nil {
            let timer = Timer(timeInterval: 0.05,
                                 target: self,
                                 selector: #selector(collectAudioLevel),
                                 userInfo: nil,
                                 repeats: true)

            RunLoop.current.add(timer, forMode: .common)
            timer.tolerance = 0.1
            skAudioTimer = timer
        }
        
    }
    public func start(){
        transaction = session?.recognize(self)
    }
    public func stop(){
        SVKSpeechSession.shared.stopRecognize()
        skAudioTimer?.invalidate()
    }
}

extension SVKAudioLevel: SVKSpeechObserverDelegate {
    func transactionDidFinish(_: SVKSpeechTransaction) {
        SVKLogger.info("🏁finished")
        observers.forEach { (_,observer) in
            observer.onFinished()
        }
    }
    
    func transactionDidStop(_: SVKSpeechTransaction, with error: Error?) {
    }
    
    func transactionWillStartRecording(_: SVKSpeechTransaction) {
        
    }
    
    func transactionDidStartRecording(_: SVKSpeechTransaction) {
    }
    
    func transaction(_: SVKSpeechTransaction, didReceive message: SVKSttWsMessage, rawText: String) {
    }
    
    func sessionState(_: SVKSpeechState) {
        
    }
    
    func getHashValue() -> Int {
        return 78792
    }
    
    
}
extension SVKAudioLevel: SVKSpeechTransactionExchangeDelegate{
    var sessionId: String? {
        nil
    }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
        completionHandler?("pcm/16khz/16bit/1/s")
        
    }
    
}
