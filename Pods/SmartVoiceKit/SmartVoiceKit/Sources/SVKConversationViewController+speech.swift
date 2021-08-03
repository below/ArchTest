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
import AVKit
import MediaPlayer

internal let recommendationHackNbMax: Int = 5

extension SVKConversationViewController {
    
    internal func removeThinkingIndicator() {
        DispatchQueue.main.safeAsync {
            guard self.conversation.lastElement?.contentType == .waitingIndicator else {
                return
            }
            // save the indexPath of the row to delete before remove the data
            let indexPath = self.conversation.lastElementIndexPath
            self.conversation.removeLastElement()
            
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
            
            if self.conversation.sections[self.conversation.sections.count - 1].elements.count == 0 {
                let indexset = IndexSet(integer: self.conversation.sections.count - 1)
                self.tableView.beginUpdates()
                self.conversation.removeLastSection()
                self.tableView.deleteSections(indexset, with: .none)
                self.tableView.endUpdates()
            }
        }
    }
    
    internal func addThinkingIndicator(_ style: SVKBubbleStyle = .default(.left)) {
        DispatchQueue.main.safeAsync {
            var thinkingDescription:SVKBubbleDescription = style == .default(.left) ? SVKAssistantBubbleDescription(type: .waitingIndicator) : SVKUserBubbleDescription(type: .waitingIndicator)
            thinkingDescription.origin = .conversation
            var descriptions: [SVKBubbleDescription] = [thinkingDescription]
            self.insertBubbles(from: &descriptions,scrollEnabled: true,animation: .fade)
        }
    }
}

extension SVKConversationViewController: SVKAudioInputDelegate , SVKSpeechTransactionExchangeDelegate{
    internal func removePartialCell() {
        DispatchQueue.main.safeAsync {
            guard self.conversation.lastElement?.contentType == .partialText else {
                return
            }
            // save the indexPath of the row to delete before remove the data
            let indexPath = self.conversation.lastElementIndexPath
            self.conversation.removeLastElement()
            
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
            
            if self.conversation.sections[self.conversation.sections.count - 1].elements.count == 0 {
                let indexset = IndexSet(integer: self.conversation.sections.count - 1)
                self.tableView.beginUpdates()
                self.conversation.removeLastSection()
                self.tableView.deleteSections(indexset, with: .none)
                self.tableView.endUpdates()
            }
        }
    }
    
    func inputController(_ controller: SVKConversationInputProtocol, partialText: String) {
        DispatchQueue.main.safeAsync {
            if self.conversation.lastElement?.contentType == .waitingIndicator {
                self.removeThinkingIndicator()
            }
            if self.conversation.lastElement?.contentType == .partialText {
                let indexPath = self.conversation.lastElementIndexPath
                if var description = self.conversation[indexPath] as? SVKUserBubbleDescription {
                    description.oldText = description.text
                    description.text = partialText
                    self.conversation[indexPath] = description
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                }
            } else {
                var partialDescription:SVKBubbleDescription = SVKUserBubbleDescription(text:partialText, type: .partialText)
                partialDescription.origin = .conversation
                var descriptions: [SVKBubbleDescription] = [partialDescription]
                self.insertBubbles(from: &descriptions)
            }
        }
    }
    
    
    /**
     Sends the current input text to the delegate
     - parameter controller: The input controller
     - parameter message: The SVKInvokeResult received from ther cvi
     */
    internal func inputController(_ controller: SVKConversationInputProtocol, didReceive message: SVKInvokeResult, isActiveController: Bool) {
        DispatchQueue.main.safeAsync {
            self.removeThinkingIndicator()
            if let text = message.sttCandidates?.data.first?.text, !text.isEmpty {
                if self.conversation.lastElement?.contentType == .partialText {
                    let indexPath = self.conversation.lastElementIndexPath
                    if var description = self.conversation[indexPath] as? SVKUserBubbleDescription {
                        let formatter = SVKTools.iso8061DateFormatter
                        formatter.timeZone = TimeZone(abbreviation: "UTC")!
                        description.oldText = nil
                        description.text = text
                        description.deliveryState = .delivered
                        description.origin = .conversation
                        description.contentType = .text
                        self.conversation[indexPath] = description
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                } else {
                    let formatter = SVKTools.iso8061DateFormatter
                    formatter.timeZone = TimeZone(abbreviation: "UTC")!

                    var userDescription = SVKUserBubbleDescription(bubbleStyle: .default(.left), text: text, timestamp: formatter.string(from: Date()))
                    // set isTimestampHidden property
                    if let requestIndexPath = self.conversation.indexPath(before: self.conversation.lastElementIndexPath) {
                        let lastestDescription = self.conversation[requestIndexPath]
                        if let currentDate = formatter.date(from: userDescription.timestamp),
                            let previousDate = formatter.date(from: lastestDescription.timestamp) {
                            userDescription.isTimestampHidden = currentDate.timeIntervalSince(previousDate) <= self.groupedMessageDelay * 60
                        }
                    }
                    userDescription.deliveryState = .delivered
                    userDescription.origin = .conversation
                    var descriptions: [SVKBubbleDescription] = [userDescription]
                    self.insertBubbles(from: &descriptions)
                }
            } else {
                self.removePartialCell()
            }

            self.delegate?.translateCard(message, completionHandler: { (resultReponse,card) in
                // TODO : we should transmit the parametrer active controller to manage the action an resuming audio
                if (resultReponse.quickReplies?.replies.isEmpty ?? true) && self.isResponseContainsError(status: resultReponse.status)  {
                    self.delegate?.getCatalog(completionHandler: { (shSkillsCatalog) in
                        if let shSkillsCatalog = shSkillsCatalog, !shSkillsCatalog.skillCatalog.isEmpty  {
                            //Get quick replies for SVK assistant
                            let newResultResponse = self.delegate?.getQuickReplyBubble(invokeResult: resultReponse)
                            DispatchQueue.main.safeAsync {
                                if let isQuickRepliesEmpty = newResultResponse?.quickReplies?.replies.isEmpty, isQuickRepliesEmpty {
                                    self.didReceiveResponse(resultReponse, card: card, isActiveController: isActiveController)
                                } else {
                                    self.didReceiveResponse(newResultResponse ?? resultReponse, card: card, isActiveController: isActiveController)
                                }
                            }
                        } else {
                            DispatchQueue.main.safeAsync {
                                self.didReceiveResponse(resultReponse, card: card, isActiveController: isActiveController)
                            }
                        }
                    })
                    
                } else {
                    self.didReceiveResponse(resultReponse, card: card, isActiveController: isActiveController)
                }
            })
        }
    }
    
    func isResponseContainsError(status: String) -> Bool {
        return ((SVKConstant.isResponseContainsMisunderstoodError(status: status) && self.context.isEmptyRequestRecommendationHackEnable) || ((SVKConstant.isResponseContainsSkillError(status: status) && self.context.isMisunderstoodRequestRecommendationHackEnable)))
    }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
        self.delegate?.supportedCodecFormat(completionHandler: completionHandler)
    }
    
    func didStartRecognition() {
        // TODO : put a parameter for listening all transactions or only the dedicated transaction
        addThinkingIndicator(.default(.right))
    }
    
    func didStopRecognition() {
        removeThinkingIndicator()
    }
    
    func didFinishRecognition() {
        removeThinkingIndicator()
    }
}

protocol SVKPushToTalkDelegate {
    
    /// Called when the speech has been accepted
    func didAcceptSpeech()

    /// Called when the push to talk transaction is going to start
    func willStartPTTransaction()

    /// Called when the push to talk transaction has began
    func didStartPTTransaction()
    
    /// Called when the push to talk transaction is terminated
    func didFinishPTTransaction()
}

extension SVKPushToTalkDelegate {
    func didAcceptSpeech() {}
    func didStartPTTransaction() {}
}

extension SVKConversationViewController: SVKPushToTalkDelegate {
    
    func willStartPTTransaction() {
        SVKLogger.debug("PTT will start")
        removeRecoBubbles()
        SVKAudioPlayer.shared.stop(resumeMusic: false)
    }

    func didFinishPTTransaction() {
        DispatchQueue.main.async {
            SVKAudioPlayer.shared.resumeSystemMusicPlayer()
        }
    }

}
