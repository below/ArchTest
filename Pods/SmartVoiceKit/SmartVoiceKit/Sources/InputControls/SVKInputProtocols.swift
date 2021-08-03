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

/**
 A text producer type
 */
enum SVKTextProducer {
    case keyboard
    case speechToText
}

enum SVKTTSState: CustomStringConvertible {
    case idle
    case speaking

    public var description: String {
        switch self {
        case .idle: return ".idle"
        case .speaking: return ".speaking"
        }
    }
}
/**
 The conversation input states
 */
enum SVKConverstationInputState {
    case idle
    case sttStarting        // A stt process is starting
    case sttListening       // The user voice is listening
    case sttStopping        // A recognition is stopping
    case sttWaitUntilDisconnection   // waiting for the deconnection
    case sttRecognizing     // A speech is being recognized
    case sttSendingText     // A text is being sent to Djingo
    case kbdSendingText     // An stt text is being sent to Djingo
    case kbdTypingText      // A text is being typed
    case ttsRunning
    case disabled           // state where user can not interact with mic
}

/**
 A protocol for any objects which handles audio inputs
 */
protocol SVKAudioInputDelegate {
    /// Called when the audio input controller did start recognition
    func didStartRecognition()

    /// Called when the audio input controller did stop recognition
    func didStopRecognition()
    
    /// Called when the autio input controller did finish a transaction
    func didFinishRecognition()
        
    /// Called when a response has been received
    func inputController(_ controller: SVKConversationInputProtocol, didReceive: SVKInvokeResult, isActiveController: Bool)
    
    /// Called when a response has been received
    func inputController(_ controller: SVKConversationInputProtocol, partialText: String)
    
    var sessionId: String? { get }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?)
}

/**
 A protocol for any objects which handles text inputs
 */
protocol SVKInputTextDelegate {
    /// Called when some text has been validated
    func inputController(_ controller: SVKConversationInputProtocol, didAccept text: String, from producer: SVKTextProducer)
}
/**
 A protocol for any objects which handles inputs
 */
protocol SVKInputDelegate: SVKAudioInputDelegate, SVKInputTextDelegate {
}

/**
 A protocol any concrete input controller must conforms to
 */
protocol SVKConversationInputProtocol {
    /// The input mode of the input controller
    var inputMode: SVKConversationInputMode { set get }
    
    /// The state of the input view controller
    var state: SVKConverstationInputState { set get }
    
    var isHistoryRefreshing: Bool { set get }
    
    /// Resign the first responder
    @discardableResult
    func resignFirstResponder() -> Bool
}

protocol SVKInputViewProtocol {
    /// the content inset
    var contentInsets: UIEdgeInsets { get }
}
