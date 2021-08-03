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

import UIKit

public protocol SVKAudioRecorderDelegate {
    /// Called when the audio input controller did start recognition
    func didStartRecognition()

    /// Called when the audio input controller did stop recognition
    func didStopRecognition()
    
    /// Called when the autio input controller did finish a transaction
    func didFinishRecognition()
        
    /// Called when a response has been received
    func didReceive(_ invokeResult: SVKInvokeResult)
    
    /// Called when a response has been received
    func didReceive(_ partialText: String)
    
}

public final class SVKAudioRecorderViewController: UIViewController {
    
    @IBOutlet var inputViewContainer: UIView!

    internal var audioInputViewController: SVKAudioInputViewController?
    
    var isMainNotificationAudioTriggerAssistantReceiver = false
    
    public var delegate: SVKConversationProtocol?
    
    public var delegateAudioRecorder: SVKAudioRecorderDelegate?
    
    public var resizableDelegate : SVKAudioInputSizableDelegate?
    var sessionId: String?
    
    public var isSoundEffectsEnabled: Bool = true {
        didSet {
            audioInputViewController?.isSoundEffectsEnabled = isSoundEffectsEnabled
        }
    }

    public var isVocalizationEnabled: Bool = true

    public var context = SVKContext()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        performSegue(withIdentifier: SVKAudioRecorderSegue.segueIdentifier, sender: self)
    }
    public override func viewWillAppear(_ animated: Bool) {        
        super.viewWillAppear(animated)
        view.backgroundColor = SVKConversationAppearance.shared.backgroundColor
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = audioInputViewController {
            vc.clearNotification()
        }
        if segue is SVKAudioRecorderSegue {
            let viewController = segue.source as? SVKAudioRecorderViewController
            audioInputViewController = segue.destination as? SVKAudioInputViewController
            audioInputViewController?.inputMode = .audio
            audioInputViewController?.delegate = self
            audioInputViewController?.resizableDelegate = resizableDelegate
            audioInputViewController?.context = self.context
            audioInputViewController?.isStretchableSizeImage = true
            audioInputViewController?.isMainNotificationAudioTriggerAssistantReceiver = isMainNotificationAudioTriggerAssistantReceiver
            if let audioInputViewController = audioInputViewController {
                viewController?.addChild(audioInputViewController)
            }
            
        }
    }
    public func refreshAudioInputUI(){
        audioInputViewController?.updateUI()
    }
    
    public func reloadAudioRecorderUI(){
        audioInputViewController?.cancelWasAlreadyPresented()
    }
    
    public func setUpAnimationType(animationType: SVKAudioInputAnimationType = .barGraph){
        audioInputViewController?.inputAnimationMode = animationType
    }
    
    private func playMedia(at url: URL, from: Float, tag: Int) {
        SVKMusicPlayer.shared.prepareToPlayMedia(at: url, from: from, tag: tag)
        SVKMusicPlayer.shared.playMedia(completionHandler: nil)
    }

    private func play(from description: SVKAssistantBubbleDescription) {
        if let mediaUrlString = description.card?.data?.mediaUrl,
           let url = URL(string: mediaUrlString) {
            playMedia(at: url, from: description.seekTime, tag: description.bubbleKey)
        }
    }
}

extension SVKAudioRecorderViewController : SVKPushToTalkDelegate {
    func willStartPTTransaction() {
    }
    
    func didFinishPTTransaction() {
    }
    
    
}

extension SVKAudioRecorderViewController : SVKInputDelegate {
    func didStartRecognition() {
        delegateAudioRecorder?.didStartRecognition()
    }
    
    func didStopRecognition() {
        delegateAudioRecorder?.didStopRecognition()
    }
    
    func didFinishRecognition() {
        delegateAudioRecorder?.didFinishRecognition()
    }
    
    func inputController(_ controller: SVKConversationInputProtocol, didReceive message: SVKInvokeResult, isActiveController: Bool) {
        let isActive = isActiveController
        delegateAudioRecorder?.didReceive(message)
        DispatchQueue.main.safeAsync {
            self.delegate?.translateCard(message, completionHandler: { (resultMessage,card) in
                // TODO : we should transmit the parametrer active controller to manage the action an resuming audio
                self.didReceiveResponse(resultMessage, card: card, isActiveController: isActive)
            })
        }
    }
    
    func inputController(_ controller: SVKConversationInputProtocol, partialText: String) {
        delegateAudioRecorder?.didReceive(partialText)
    }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
        self.delegate?.supportedCodecFormat(completionHandler: completionHandler)
    }
    
    func inputController(_ controller: SVKConversationInputProtocol, didAccept text: String, from producer: SVKTextProducer) {
    }
    
// TODO : refactor this code with DCConversationViewController
    public func didReceiveResponse(_ response: SVKInvokeResult, card: SVKCard?, isActiveController: Bool) {
        SVKLogger.debug("\n<RESPONSE>\n:\(response)\n</RESPONSE>")
        SVKLogger.debug("\n<CARD>\n\(String(describing: card))\n</CARD>")

        var descriptions = [SVKBubbleDescription]()
        var execDescription: SVKAssistantBubbleDescription?
        
        DispatchQueue.main.async {
            defer {
                if (isActiveController && self.isVocalizationEnabled) {
                    SVKSpeechSession.shared.startVocalize(descriptions,delegateConversation: self.delegate) {
                        if let execDescription = execDescription {
                            if execDescription.card != nil {
                                self.play(from: execDescription)
                            } else {
                                self.executeAction(from: execDescription, completionHandler: nil)
                            }
                        }
                    }
                } else if isActiveController {
                    if let execDescription = execDescription {
                        if execDescription.card != nil {
                            self.play(from: execDescription)
                        } else {
                            self.executeAction(from: execDescription, completionHandler: nil)
                        }
                    }
                }
            }
            let text: String = response.text.process(with: .escape)
                .process(with: .removeUnknownTags(keepTags: ["speak","audio","sub","p","s"]))
                .process(with: .removeTag("speak"))
                .process(with: .removeTag("audio"))
                .process(with: .removeTag("sub"))
                .process(with: .removeTagValue(tag: "s", attributeName: "display", attributeValue: "none"))
                .replacingOccurrences(of: "\u{1B}", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            if let cardData = card {
                let textDescription = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
                let description = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, type: .genericCard,
                                                                card: cardData, invokeResult: response)
                descriptions.append(description)
                if self.context.dedicatedPreFixLocalisationKey == "djingo" {
                    descriptions.append(textDescription)
                }
                execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                return
            }
            
            if let kit = response.skill?.data?.kit {
                SVKLogger.debug("kit type: \(kit.type)")
                switch kit.type {
                case .deezer:
                    if let urls = kit.parameters?.urls, urls.count > 0, let card = card, let data = card.data, !data.isEmpty() {
                        // a top left text bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response))
                        
                        // a bottom left music card bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, card: card, invokeResult: response))
                    } else {
                        // a default left text bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .default(.left), text: text, invokeResult: response))
                    }
        
                    // execute the card action if possible
                    if descriptions.count == 2, let cardDescription = descriptions.last as? SVKAssistantBubbleDescription {
                        execDescription = cardDescription
                    }
                    return

//                case .audioPlayer:
//                    let description = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
//                    let audioControllerDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), type: .audioController, invokeResult: response)
//                    descriptions.append(description)
//                    descriptions.append(audioControllerDescription)
//                    execDescription = descriptions[1] as? SVKAssistantBubbleDescription
//                    return

                case .system:
                    let description = SVKAssistantBubbleDescription(bubbleStyle: .default(.left), text: text, invokeResult: response)
                    descriptions.append(description)
                    execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                    return

                case .timer:
                    var description = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
                    description.origin = .conversation
                    descriptions.append(description)
                    if let card = card, let data = card.data, !data.isEmpty() {
                        let timerDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, card: card, invokeResult: response)
                        descriptions.append(timerDescription)
                        execDescription = descriptions[1] as? SVKAssistantBubbleDescription
                    } else {
                        execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                    }
                    return

                default:
                    SVKLogger.warn("Kit '\(kit.name)' not implemented")
                }
            }
            let timestamp = SVKTools.iso8061DateFormatter.string(from: Date())
            var bubbleIndex = 0
            descriptions = buildDescriptions(text, timestamp, nil, response, card, &bubbleIndex, false, self.context.dedicatedPreFixLocalisationKey)

            if let card = card, let data = card.data, !data.isEmpty() {
                var djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left),
                                                                        text: text, timestamp: timestamp,
                                                                        card: card, invokeResult: response)
                djingoBubbleDescription.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                descriptions.append(djingoBubbleDescription)
            }
            if card?.data?.layout == .mediaPlayer {
                let description = descriptions.first {
                    if let bubbleDescription = $0 as? SVKAssistantBubbleDescription,
                        let _ = bubbleDescription.skill as? SVKGenericAudioPlayerSkill {
                        return true
                    }
                    return false
                }
                
                execDescription = description as? SVKAssistantBubbleDescription
                if let execDescription = execDescription, isActiveController {
                    self.prepareAction(from: execDescription)
                }
            }

            /// Sets the bubbles style
            descriptions.setBubblesStyle()
            
            // insert the bubbles in the table view
            
            // get the session id
            if descriptions.count > 0, let sessionDescription = descriptions[0] as? SVKAssistantBubbleDescription {
                self.context.sessionId = sessionDescription.sessionID
            }
            
        }
    }
  
    public func didVocalizeText(_ text: String, stream: Data) {
        SVKLogger.debug("saying text: \(text)")
        SVKAudioPlayer.shared.enqueue(stream)
    }
}

// TODO refactor this code
extension SVKAudioRecorderViewController {
//    extension SVKAudioRecorderViewController: SVKActionDelegate {

    /**
     Execute an action from a bubble description.
     
     The action associated to the bubble's description is executed and then the completionHandler is called.
     - parameter description: The **SVKAssistantBubbleDescription** related to the action to execute.
     - parameter completionHandler: A closure call at the end of the execution. It's called with
     an argument representing the status of the execution, true if the execution succeeded false otherwise
     */
    func executeAction(from description: SVKAssistantBubbleDescription, completionHandler: ((Bool) -> Void)? = nil) {
        SVKLogger.debug("executing action from description: \(String(describing: description))")
        description.skill?.execute(completionHandler: completionHandler)
    }

    /**
     Prepare an action to be executed from a bubble description.
     
     The action associated to the bubble's description will be executed
     - parameter description: The **SVKAssistantBubbleDescription** related to the action to execute.
     - parameter completionHandler: A closure call at the end of the execution. It's called with
     an argument representing the status of the execution, true if the execution succeeded false otherwise
     */
    func prepareAction(from description: SVKAssistantBubbleDescription) {
        SVKLogger.debug("preparing action from description: \(String(describing: description))")
        description.skill?.prepare()
    }
}

