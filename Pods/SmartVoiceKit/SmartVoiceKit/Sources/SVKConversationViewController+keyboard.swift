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
import MediaPlayer

extension SVKConversationViewController: SVKInputDelegate {
    
    /**
     Register to keyboards notifications
     */
    func registerToKeyboardNotifications() {

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { notification in
            // Called when the keyboard is going to be displayed
            if self.conversation.sections.count > 0 {
                let timeout = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
                UIView.animate(withDuration: timeout) {
                    self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentSize.height - self.tableView.frame.height)
                }
            }
        }
        self.tableView.keyboardDismissMode = .interactive
    }

    /**
     Deregister from notifications
     */
    func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     Sends the current input text to the delegate
     - parameter controller: The input controller
     - parameter text: The text accepted by the textField
     */
    internal func inputController(_ controller: SVKConversationInputProtocol, didAccept text: String, from producer: SVKTextProducer) {
        guard text.count > 0 else { return }

        // save the music playback state for this transaction. It will be restitued after TTS
        systemMusicPlaybackState = MPMusicPlayerController.systemMusicPlayer.playbackState
        
        if controller.state == .kbdTypingText {
            SVKAudioPlayer.shared.play(resource: "sent.m4a")
        }

        let formatter = SVKTools.iso8061DateFormatter
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        var messageDescription = SVKUserBubbleDescription(bubbleStyle: .default(.left), text: text, timestamp: formatter.string(from: Date()))
       
        // set isTimestampHidden property
        if let requestIndexPath = self.conversation.indexPath(before: conversation.lastElementIndexPath) {
            let lastestDescription = conversation[requestIndexPath]
            if let currentDate = formatter.date(from: messageDescription.timestamp),
                let previousDate = formatter.date(from: lastestDescription.timestamp) {
                messageDescription.isTimestampHidden = currentDate.timeIntervalSince(previousDate) <= self.groupedMessageDelay * 60
            }
        }
        
        let thinkingDescription = SVKAssistantBubbleDescription(bubbleStyle: .default(.left), type: .waitingIndicator, timestamp: formatter.string(from: Date()))
        var descriptions: [SVKBubbleDescription] = []
        descriptions.append(thinkingDescription)
        descriptions.append(messageDescription)
        
        self.insertBubbles(from: &descriptions)
        self.setEmptyMessageHidden(true, animated: false)
        
        self.state = producer == .keyboard ? .kbdSendingText : .sttSendingText
        delegate?.sendText(text, with: self.context.sessionId)
    }
    
    /**
     Sends the current input text to the delegate
     - parameter controller: The input controller
     - parameter text: The text accepted by the textField
     */ // todo rename this function
    internal func sendText(_ text: String, from producer: SVKTextProducer, replaceReco indexPathReco: IndexPath) {
        guard text.count > 0 else { return }

        // save the music playback state for this transaction. It will be restitued after TTS
        systemMusicPlaybackState = MPMusicPlayerController.systemMusicPlayer.playbackState
        
        var indexPathRecos = [IndexPath]()
        
        for (indexPath, element) in self.conversation.enumerated().reversed() {
            if element.contentType == .recoText, indexPath != indexPathReco {
                indexPathRecos.append(indexPath)
            }
        }
        if self.isSoundEffectsEnabled {
            SVKAudioPlayer.shared.play(resource: "sent.m4a")
        }

        let formatter = SVKTools.iso8061DateFormatter
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        var messageDescription = SVKUserBubbleDescription(bubbleStyle: .default(.left), text: text, timestamp: formatter.string(from: Date()))
       
        // set isTimestampHidden property
        if let requestIndexPath = self.conversation.indexPath(before: conversation.lastElementIndexPath) {
            let lastestDescription = conversation[requestIndexPath]
            if let currentDate = formatter.date(from: messageDescription.timestamp),
                let previousDate = formatter.date(from: lastestDescription.timestamp) {
                messageDescription.isTimestampHidden = currentDate.timeIntervalSince(previousDate) <= self.groupedMessageDelay * 60
            }
        }
        self.conversation[indexPathReco] = messageDescription
        tableView.reloadRows(at: [indexPathReco], with: .fade)
        removeRow(from: indexPathRecos)
        
        let thinkingDescription = SVKAssistantBubbleDescription(bubbleStyle: .default(.left), type: .waitingIndicator, timestamp: formatter.string(from: Date()))
        var descriptions: [SVKBubbleDescription] = []
        descriptions.append(thinkingDescription)
        self.insertBubbles(from: &descriptions,scrollEnabled: true,animation: .fade)
        self.setEmptyMessageHidden(true, animated: false)
        
        self.state = producer == .keyboard ? .kbdSendingText : .sttSendingText
        delegate?.sendText(text, with: self.context.sessionId)
    }
    
    var sessionId: String? {
        return self.context.sessionId
    }
    
}


extension SVKConversationViewController {

    func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        guard self.isViewLoaded else { return }
        
        if toolbar.isHidden && !hidden {
            self.view.constraints.first { $0.identifier == "TableViewBottomSafeArea" }?.constant = self.toolbar.frame.height
            if animated {
                self.toolbar.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    self.toolbar.superview?.layoutIfNeeded()
                }
            } else {
                toolbar.isHidden = false
            }
            
        } else if !toolbar.isHidden && hidden {
            self.view.constraints.first { $0.identifier == "TableViewBottomSafeArea" }?.constant = 0
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.toolbar.superview?.layoutIfNeeded()
                }) { _ in
                    self.toolbar.isHidden = true
                }
            } else {
                toolbar.isHidden = true
            }
        }
    }
    
    // Setup the UI with the selected inputViewControler
    func setToolbarStyle(animated: Bool) {
        if displayMode.contains(.conversation), !inputMode.isEmpty {
            setToolbarHidden(false, animated: animated)
            
            if inputMode.contains(.text) {
                performSegue(withIdentifier: SVKInputSelectionSegue.text, sender: self)
            } else if inputMode.contains(.audio) {
                performSegue(withIdentifier: SVKInputSelectionSegue.audio, sender: self)
            }
        } else {
            setToolbarHidden(true, animated: animated)
        }
    }
}


