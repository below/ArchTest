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
import AudioToolbox

/**
 A SVKTableViewCell delegation protocol
 */
protocol SVKActionDelegate: SVKAudioControllerDelegate, SVKCardV3Delegate {
    func prepareAction(from description: SVKAssistantBubbleDescription)
    func executeAction(from description: SVKAssistantBubbleDescription, completionHandler: ((Bool) -> Void)?)
}

/*
 An protocol extension that allows to have nil as default value for completionHandler
 */
extension SVKActionDelegate {
    func executeAction(from description: SVKAssistantBubbleDescription, completionHandler: ((Bool) -> Void)? = nil ) {
        executeAction(from: description, completionHandler: completionHandler)
    }
    func prepareAction(from description: SVKAssistantBubbleDescription) {
        prepareAction(from: description)
    }
}

protocol SVKActionErrorDelegate {
    func toggleAction(from description: SVKHeaderErrorBubbleDescription)
}

extension SVKConversationViewController: UIGestureRecognizerDelegate {
    func addGestureRecognizers() {
            self.addLongGestureRecognizer()
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            self.tableView.addGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer.delegate = self
        }
        
    func addLongGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.delegate = self
    }
    
    func removeLongGestureRecognizer() {
        self.tableView.gestureRecognizers?.filter { $0 is UILongPressGestureRecognizer }.forEach {
            if let _ = $0.delegate as? SVKConversationViewController {
                self.tableView.removeGestureRecognizer($0)
            }
        }
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer) {
        
        guard sender.state == .ended else { return }

        guard let indexPath = self.tableView.indexPathForRow(at: sender.location(in: self.tableView)),
                    let cell = self.tableView.cellForRow(at: indexPath) as? SVKTableViewCellProtocol,
                    let bubble = cell.concreteBubble() else { return }

        let sectionDescription = self.conversation[indexPath.section]

        if !isEditing {
            if bubble.frame.contains(sender.location(in: cell as? SVKTableViewCell)) {
                let description = conversation[indexPath]
                if let userBubbleDescription = description as? SVKUserBubbleDescription, userBubbleDescription.contentType == .recoText {
                    self.sendText(userBubbleDescription.text ?? "", from: .speechToText,replaceReco: indexPath)
                } else {
                // perform details action
                bubble.tapAction?(bubble, ["description" : description,
                                           "sectionDescription" : sectionDescription,
                                           "indexPath" : indexPath])
                }
            }
            SVKSpeechSession.shared.stopVocalize()
        }
    }
    /**
     Handles a long press gesture on the tableView
     */
    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            if let indexPath = self.tableView.indexPathForRow(at: gesture.location(in: self.tableView)),
                let cell = self.tableView.cellForRow(at: indexPath) as? SVKTableViewCellProtocol,
                let bubble = cell.concreteBubble() {
                
                // if the touch is in the bubble
                if bubble.bounds.contains(gesture.location(in: bubble)), !(self.conversation[indexPath] is SVKHeaderErrorBubbleDescription), (self.conversation[indexPath] as? SVKUserBubbleDescription)?.contentType != .recoText {
                    UISelectionFeedbackGenerator().selectionChanged()
                    bubble.longPressAction?(bubble, ["indexPath":indexPath, "cell":cell])
                }
            }
        }
    }
        
    // see https://stackoverflow.com/questions/33338726/reload-tableview-section-without-scroll-or-animation
    func reloadSectionWithoutScroll(at indexSet: IndexSet) {
        UIView.performWithoutAnimation {
            self.tableView.reloadSections(indexSet, with: .none)
        }
    }

    /**
     Set the bubble long press closure action
     */
    func setLongPressAction(for bubble: SVKBubble) {
        bubble.longPressAction = { bubble, userInfo in
            
            guard let contentView = bubble.superview,
                let userInfo = userInfo as? [String:Any],
                let indexPath = userInfo["indexPath"] as? IndexPath,
                let cell = userInfo["cell"] as? SVKTableViewCell else {
                    return
            }
            
            let presentationClosure = { (completionHandler: (()->Void)?) in
                if let capture = contentView.snapshotView(afterScreenUpdates: true) {
                    
                    // present the action controller
                    let presentActionViewController = { (contentViewOrigin: CGPoint, completionHandler: (()->Void)?) in
                        let actionViewController = self.storyboard?.instantiateViewController(withIdentifier: "SVKActionSheetViewController") as! SVKActionSheetViewController
                        actionViewController.delegate = self
                        actionViewController.actionIndexPath = indexPath
                        actionViewController.completionHandler = completionHandler
                        
                        self.view.window?.addSubview(actionViewController.view)
                        self.addChild(actionViewController)
                        
                        // remove the comment/feedback and delete button if there is no historyId
                        let bubbleDescription = self.conversation[indexPath]
                        if bubbleDescription.historyID == nil || !SVKAppearanceBox.shared.appearance.features.actions.useMisunderstood {
                            actionViewController.removeButton(identifiedBy: .comment)
                        }
                        if bubbleDescription.historyID == nil || !SVKAppearanceBox.shared.appearance.features.actions.useDelete {
                            actionViewController.removeButton(identifiedBy: .delete)
                        }
                        // remove the code button
                        if self.context.isDevelopmentEnabled == false {
                            actionViewController.removeButton(identifiedBy: .code)
                        }
                        
                        // remove the resend button if it's a djingo bubble
                        if self.isAssistantBubbleConversation(at: indexPath) || !SVKAppearanceBox.shared.appearance.features.actions.useResend {
                            actionViewController.removeButton(identifiedBy: .resend)
                        }
                                                
                        // remove enunicate button is it's a user conversation bubble
                        if !self.displayMode.contains(.conversation) || !SVKAppearanceBox.shared.appearance.features.actions.usePlay {
                            actionViewController.removeButton(identifiedBy: .enunciate)
                        } else {
                            var indexPathToVocalized = indexPath
                            if let description = self.conversation[indexPathToVocalized] as? SVKUserBubbleDescription {
                                let indexPaths = self.conversation.indexPathOfElements(from: indexPath, groupedBy: { $0.historyID == description.historyID || $0.smarthubTraceId == description.smarthubTraceId })
                                if indexPaths.count > 1 {
                                    indexPathToVocalized = indexPaths[1]
                                }
                            }
                            if let description = self.conversation[indexPathToVocalized] as? SVKAssistantBubbleDescription {
                                if let text = description.invokeResult?.text ?? description.text,
                                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  {
                                    actionViewController.removeButton(identifiedBy: .enunciate)
                                }
                            } else {
                                actionViewController.removeButton(identifiedBy: .enunciate)
                            }
                        }
                                               
                        if !SVKAppearanceBox.shared.appearance.features.actions.useShare {
                            actionViewController.removeButton(identifiedBy: .share)
                        }
                        capture.frame.origin = contentView.convert(contentView.frame.origin, to: actionViewController.view)
                        actionViewController.view.addSubview(capture)
                        
                        let correction = bubbleDescription is SVKUserBubbleDescription ? (bubbleDescription.origin == .conversation && bubbleDescription.appearance.userBubbleAppearance.isCheckmarkEnabled ? 0: -14)   :0
                        
                        let alignment: SVKHorizontalAlignement = bubbleDescription is SVKAssistantBubbleDescription ? .left(SVKAppearanceBox.HorizontalAlignment.avatar) : .right(SVKAppearanceBox.HorizontalAlignment.right + CGFloat(correction))
                        
                        var origin = capture.frame.origin
                        
                        // if the timestamp is displayed modifies the origin.y and hide the timestamp
                        if !cell.isTimestampHidden {
                            origin.y += (cell.expandedTopSpaceConstant - cell.defaultTopSpaceConstant)
                        }
                        actionViewController.setToolBarPosition(relativePosition: origin, alignment: alignment)
                    }
                    
                    
                    // compute the position of the action view then present it
                    var contentViewOrigin = contentView.convert(contentView.frame.origin, to: self.view)
                    if contentViewOrigin.y < 0 {
                        let visibleRect = contentView.convert(contentView.frame, to: self.tableView).offsetBy(dx: 0, dy: -14)
                        self.tableView.scrollRectToVisible(visibleRect, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                            contentViewOrigin = contentView.convert(contentView.frame.origin, to: self.view)
                            presentActionViewController(contentViewOrigin, completionHandler)
                        }
                    } else {
                        presentActionViewController(contentViewOrigin, completionHandler)
                    }
                    
                } else {
                    SVKLogger.warn("Fail to capture bubble: \(bubble)")
                }
            }
            
            // if the timestamp is displayed modifies the origin.y and hide the timestamp
            if !cell.isTimestampHidden {
                cell.timestamp.alpha = 0
                presentationClosure { cell.timestamp.alpha = 1 }
            } else {
                presentationClosure(nil)
            }
        }
    }
}

//MARK: SVKActionDelegate
extension SVKConversationViewController: SVKActionDelegate {
    
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

extension SVKConversationViewController: SVKCardV3Delegate {
    func switchCollapseExpandSubText(for tag: Int) {
        if let indexPath = self.conversation.firstIndex(where: { $0.bubbleKey == tag }),
            var description = self.conversation[indexPath.section].elements[indexPath.row] as? SVKAssistantBubbleDescription {
            
            description.cardV3SubTextIsExpanded = !description.cardV3SubTextIsExpanded
            self.conversation[indexPath.section].elements[indexPath.row] = description
            
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            if !description.cardV3SubTextIsExpanded {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    func open(url: String, bubbleDescription: SVKAssistantBubbleDescription?) {
        SVKAnalytics.shared.log(event: "myactivity_item_action_link_clicked")
        let result = self.delegate?.open(url: url, bubbleDescription: bubbleDescription)
        if result == .unprocessed,
           let URL = URL(string: url) {
            if UIApplication.shared.canOpenURL(URL){
                UIApplication.shared.open(URL, options: [:])
            } else {
                return
            }
        }
    }
}

// MARK: tableView Edition
extension SVKConversationViewController {
    
    public func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.conversation[indexPath].contentType == .genericCard, let bubbleDescription = self.conversation[indexPath] as? SVKAssistantBubbleDescription,  bubbleDescription.card?.data?.layout == .some(.mediaPlayer), let skillMedia = bubbleDescription.skill as? SVKGenericAudioPlayerSkill, skillMedia.duration > 0.0 {
            return false
        }
        
        return self.conversation[indexPath].contentType != .audioController && self.conversation[indexPath].contentType != .recoText
    }
    
    public func tableView(_: UITableView, commit _: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        deleteBubble(at: indexPath)
    }
    
    // Fix white color for swippe image
    // https://stackoverflow.com/questions/46398910/ios11-uicontextualaction-place-the-image-color-text
    @available(iOS 11.0, *)
    private func injectImage(named: String, in contextualAction: inout UIContextualAction){
        if let image = UIImage(named: named, in: SVKBundle, compatibleWith: nil),
            let cgImage = image.cgImage
        {
            // https://stackoverflow.com/a/55706586
            let actionImage = SVKImageWithoutRender(cgImage: cgImage,
                                                scale: UIScreen.main.nativeScale,
                                                orientation: image.imageOrientation)
            contextualAction.image = actionImage
        }
    }
    @available(iOS 11.0, *)
    private func inject(image: UIImage?, in contextualAction: inout UIContextualAction){
        if let image = image,
            let cgImage = image.cgImage
        {
            // https://stackoverflow.com/a/55706586
            let actionImage = SVKImageWithoutRender(cgImage: cgImage,
                                                scale: UIScreen.main.nativeScale,
                                                orientation: image.imageOrientation)
            contextualAction.image = actionImage
        }
    }
    /*
     Returns the swipe actions to display on the leading edge of the row.
     */
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var actions = [UIContextualAction]()
        
        if context.isDevelopmentEnabled {
            var codeAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.displayBubbleJSON(at: indexPath)
                actionPerformed(true)
            }
            codeAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            injectImage(named: "code-button", in: &codeAction)
            actions.append(codeAction)
        }
        var addVocalizationAction = false
        if self.isAssistantBubbleConversation(at: indexPath),
            let description = self.conversation[indexPath] as? SVKAssistantBubbleDescription,
            self.displayMode.contains(.conversation),
            let text = description.invokeResult?.text ?? description.text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addVocalizationAction = true
        } else if self.displayMode.contains(.conversation) {
            var indexPathToVocalized = indexPath
            if let description = self.conversation[indexPathToVocalized] as? SVKUserBubbleDescription {
                let indexPaths = self.conversation.indexPathOfElements(from: indexPath, groupedBy: { $0.historyID == description.historyID || $0.smarthubTraceId == description.smarthubTraceId })
                if indexPaths.count > 1 {
                    indexPathToVocalized = indexPaths[1]
                }
            }
            if let description = self.conversation[indexPathToVocalized] as? SVKAssistantBubbleDescription,
                let text = description.invokeResult?.text ?? description.text,
                    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  {
                    addVocalizationAction = true
                }
        }
        
        if addVocalizationAction, SVKAppearanceBox.shared.appearance.features.actions.usePlay {
            var enunciateAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.enunciateBubble(at: indexPath)
                actionPerformed(true)
            }
            enunciateAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            inject(image: SVKAppearanceBox.Assets.swipePlay, in: &enunciateAction)
            actions.append(enunciateAction)
        }
        
        if self.isUserBubbleConversation(at: indexPath), SVKAppearanceBox.shared.appearance.features.actions.useResend {
            var resendAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.resendBubble(at: indexPath)
                actionPerformed(true)
            }
            resendAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            inject(image: SVKAppearanceBox.Assets.swipeResend, in: &resendAction)
            actions.append(resendAction)
        }
    
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    /*
     Returns the swipe actions to display on the trailing edge of the row.
     */
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var actions = [UIContextualAction]()
        
        // delete button
        if self.conversation[indexPath].historyID != nil, SVKAppearanceBox.shared.appearance.features.actions.useDelete {
            var deleteAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.deleteBubble(at: indexPath)
                actionPerformed(true)
            }
            deleteAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            inject(image: SVKAppearanceBox.Assets.swipeDelete, in: &deleteAction)
            actions.append(deleteAction)
        }
        // copy share button
        var shouldAddCopyShareIcon = false
        if let _ = self.conversation[indexPath] as? SVKAssistantBubbleDescription  {
            shouldAddCopyShareIcon = true
        }
        if let _ = self.conversation[indexPath] as? SVKUserBubbleDescription {
            shouldAddCopyShareIcon = true
        }
        
        if shouldAddCopyShareIcon, SVKAppearanceBox.shared.appearance.features.actions.useShare {
            // copy button should be hidden: DJNA-3071
//            var copyAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
//                self.copyBubble(at: indexPath)
//                actionPerformed(true)
//            }
//            copyAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
//            inject(image: SVKAppearanceBox.Assets.swipeCopy, in: &copyAction)
//            actions.append(copyAction)
            
            var shareAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.shareBubble(at: indexPath)
                actionPerformed(true)
            }
            shareAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            inject(image: SVKAppearanceBox.Assets.swipeShare, in: &shareAction)
            actions.append(shareAction)
        }
        
        // add the feedback button only if there is a historyId
        if self.conversation[indexPath].historyID != nil, SVKAppearanceBox.shared.appearance.features.actions.useMisunderstood {
            var feedbackAction = UIContextualAction(style: .normal, title: nil) { (_, _, actionPerformed) in
                self.provideFeedbackOnBubble(at: indexPath)
                actionPerformed(true)
            }
            feedbackAction.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            inject(image: SVKAppearanceBox.Assets.swipeMisunderstood, in: &feedbackAction)
            actions.append(feedbackAction)
        }
        
        return UISwipeActionsConfiguration(actions: actions)
    }

}

extension SVKConversationViewController: SVKActionErrorDelegate {
    func toggleAction(from description: SVKHeaderErrorBubbleDescription) {
        let key = description.bubbleKey
        if let index = self.conversation.firstIndex(where: { (description) -> Bool in
            return description.bubbleKey == key
        }) {
            let isExpandable = !description.isExpanded
            if var newDescription = self.conversation[index] as? SVKHeaderErrorBubbleDescription {
                newDescription.isExpanded = isExpandable
                if newDescription.isExpanded {
                    var errorDescriptionEntries = newDescription.bubbleDescriptionEntries
                    let idForScrool = errorDescriptionEntries.first?.historyID
                    let nextIndex = self.conversation.index(after: index)
                    insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: true,idForScrool: idForScrool, animation: .fade)
                    newDescription.bubbleDescriptionEntries = errorDescriptionEntries
                } else {
                    let nextIndex = self.conversation.index(after: index)
                    removeErrorBubbleCollapsed(from: nextIndex)
                }
                self.conversation[index] = newDescription
            }
        }
    }
    
    func removeErrorBubbleCollapsed(from index: IndexPath) {
        var rowsToDelete = [IndexPath]()
        var currentIndex = index
     
        var foundLast = false
        while (!foundLast && (currentIndex != self.conversation.endIndex)) {
            let description = self.conversation[currentIndex]
            if let errorCode = description.errorCode, SVKConstant.filteredErrorCode.contains(errorCode) {
                rowsToDelete.append(currentIndex)
                currentIndex = self.conversation.index(after: currentIndex)
            } else {
                foundLast = true
            }
        }
        
        removeRow(from: rowsToDelete)
 
    }
    
    func removeRow(from rowsToDelete: [IndexPath]) {
        var sectionsToDelete = IndexSet()
        
        self.tableView.beginUpdates()
        self.conversation.remove(at: rowsToDelete)
        
        rowsToDelete.forEach { (i) in
            if !sectionsToDelete.contains(i.section), self.conversation.sections[i.section].isEmpty {
                sectionsToDelete.insert(i.section)
            }
        }
        sectionsToDelete.reversed().forEach { (i) in
            self.conversation.sections.remove(at: i)
        }
        self.tableView.deleteRows(at: rowsToDelete, with: .fade)
        self.tableView.deleteSections(sectionsToDelete, with: .fade)
        self.tableView.endUpdates()
        
    }
}



// MARK: SVKActionSheetViewControllerDelegate
extension SVKConversationViewController: SVKActionSheetViewControllerDelegate, SVKFeedbackViewControllerDelegate {
    /**
     Called when the user do authorize feedbacks
     - parameter completionHander: A completionHandler called at the end of the authorization request
     */
    public func authorizeFeedback(completionHandler: @escaping (_ success: Bool)->Void) {
        delegate?.authorizeFeedback(completionHandler: completionHandler)
    }
    
    
    /**
     Informs the delegate that a feedback has been selected
     - parameter feedback: the feedback to send
     - parameter historyId: the id of the concerned entry
     - parameter completionHandle: A completionHandler called at the end of the feedback update request
     */
    func didSelect(_ feedback: SVKFeedback, for historyId: String,completionHandler: @escaping (_ success: Bool)->Void) {
        delegate?.sendFeedback(feedback, on: historyId) { (entry) in
            if let entry = entry {
                var indexPaths = [IndexPath]()
                for (indexPath, var description) in self.conversation.enumerated() {
                    if description.historyID == historyId {
                        description.vote = entry.vote
                        self.conversation[indexPath] = description
                        indexPaths.append(indexPath)
                        if !self.isHideErrorInteractionsEnabled, description.contentType == .errorText {
                            var currentIndex = indexPath
                            while let searchIndex = self.conversation.indexPath(before: currentIndex) {
                                if var headerDescription = self.conversation[searchIndex] as? SVKHeaderErrorBubbleDescription {
                                    if let voteIndex = headerDescription.bubbleDescriptionEntries.firstIndex(where: { (descriptionEntry) -> Bool in
                                        return description.bubbleKey == descriptionEntry.bubbleKey
                                    }) {
                                        headerDescription.bubbleDescriptionEntries[voteIndex] = description
                                        self.conversation[searchIndex] = headerDescription
                                    }
                                    break
                                } else {
                                    currentIndex = searchIndex
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                }
                
                DispatchQueue.main.safeAsync {
                    let toastData = SVKToastData(with: .confirmation, message: "feedback.thanks".localized, offset: Float(self.inputViewContainer.bounds.height))
                    
                    self.view.showToast(with: toastData)
                }
                
                completionHandler(true)
            } else {
                SVKAnalytics.shared.log(event: "myactivity_feedback_confirmation_error")
                DispatchQueue.main.safeAsync {
                    let toastData = SVKToastData(with: .default, message: "SVK.toast.feedback.error.message".localized, offset: Float(self.inputViewContainer.bounds.height))
                    
                    self.view.showToast(with: toastData)
                }
                completionHandler(false)
            }
            
        }
    }
    
    /**
     Provide a feedback to send
     
     - parameter indexPath: The indexPath of the bubble involved
     */
    func provideFeedbackOnBubble(at indexPath: IndexPath) {
        
        delegate?.canSendFeedback()  { (feedbacksAuthorized: Bool?) in
            DispatchQueue.main.async {
                if feedbacksAuthorized == true {
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackViewController") as? SVKFeedbackViewController {
                        viewController.delegate = self
                        viewController.bubbleDescription = self.conversation[indexPath]
                        viewController.modalPresentationStyle = .fullScreen
                        SVKAnalytics.shared.log(event: "myactivity_item_feedback_open")
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                    
                } else if feedbacksAuthorized == false {
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "SVKFeedbackOptInViewController") as? SVKFeedbackOptInViewController {
                        viewController.prefixFeedbackOptinBodyKey = self.context.dedicatedPreFixLocalisationKey
                        viewController.delegate = self
                        viewController.bubbleDescription = self.conversation[indexPath]
                        let kitConfiguration = Bundle.main.object(forInfoDictionaryKey: "SmartVoiceKit") as? NSDictionary
                        viewController.trustBadgeDeeplink = kitConfiguration?["SVKTrustBadgeDeeplink"] as? String
                        viewController.shouldDisplayBadge = SVKAppearanceBox.shared.appearance.showTrustBadge
                        viewController.shouldDropShadow = !SVKAppearanceBox.shared.appearance.showTrustBadge // if there is no trustbadge
                        viewController.fonts = self.context.feedbackScreenfontType
                        viewController.modalPresentationStyle = .fullScreen
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                } else {
                    DispatchQueue.main.safeAsync {
                        let toastData = SVKToastData(with: .default, message: "SVK.toast.feedback.error.message".localized, offset: Float(self.inputViewContainer.bounds.height))
                        
                        self.view.showToast(with: toastData)
                    }
                }
            }
        }
    }
    
    /**
     Copy the content of a bubble
     
     - parameter indexPath: The indexPath of the bubble to copy
     */
    func copyBubble(at indexPath: IndexPath) {
        let bubbleDescription = self.conversation[indexPath]
        if let (content, type) = bubbleDescription.content,
            let value = content {
            // store the content into the pasteboard
            UIPasteboard.general.setValue(value, forPasteboardType: type)
        }
    }
    
    /**
     Share the content the bubble at indexPath
     
     - parameter indexPath: The indexPath of the bubble to copy
     */
    func shareBubble(at indexPath: IndexPath) {
        let bubbleDescription = self.conversation[indexPath]
        if let (content, _) = bubbleDescription.content,
            let valueToShare = content {
            let ac = UIActivityViewController(activityItems: [valueToShare], applicationActivities: [])
            ac.excludedActivityTypes = [.saveToCameraRoll] //we don't have permission for that
            // avoid crash on iPad
            var sourceView = view
            
            if let cellView = tableView.cellForRow(at: indexPath) {
                sourceView = cellView
                let rect =  cellView.convert(cellView.bounds, to: view)
                ac.popoverPresentationController?.sourceRect = rect
            }
            
            ac.popoverPresentationController?.sourceView = sourceView
            ac.popoverPresentationController?.permittedArrowDirections = []            
            
            present(ac, animated: true)
            SVKAnalytics.shared.log(event: "myactivity_item_sharing_clicked")
        } else {
            if let cellView = tableView.cellForRow(at: indexPath),
               let cell = cellView as? SVKTableViewCellProtocol,
               let bubble = cell.concreteBubble(),
               let image = SVKTools.image(with: bubble),
               let data = image.pngData()
            {
                
                let fileManager = FileManager.default
                let tempDirectory = fileManager.temporaryDirectory
                let date = Date()
                let time = SVKTools.assistantTimeFormatter.string(from: date)
                let formatter = Foundation.DateFormatter()
                formatter.dateStyle = .short
                formatter.doesRelativeDateFormatting = false
                let day = formatter.string(from: date)
                let dateFormated = "\(day)-\(time)".replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
                let filename = tempDirectory.appendingPathComponent( (SVKUserIdentificationManager.shared.deviceName ?? "Image") + "-" + dateFormated + ".png")
                try? data.write(to: filename)
                let ac = UIActivityViewController(activityItems: [filename], applicationActivities: [])
                ac.excludedActivityTypes = [.saveToCameraRoll] //we don't have permission for that
                // avoid crash on iPad
                var sourceView = view
                sourceView = cellView
                let rect =  cellView.convert(cellView.bounds, to: view)
                ac.popoverPresentationController?.sourceRect = rect
                
                ac.popoverPresentationController?.sourceView = sourceView
                ac.popoverPresentationController?.permittedArrowDirections = []
                
                present(ac, animated: true)
                SVKAnalytics.shared.log(event: "myactivity_item_sharing_clicked")
            }
        }
    }
    
    /**
     Delete a bubble
     
     - parameter indexPath: The indexPath of the bubble to delete
     */
    func deleteBubble(at indexPath: IndexPath) {
        
        let bubbleDescriptions = self.conversation[indexPath.section].elements
        let row = indexPath.row
        let historyId = bubbleDescriptions[row].historyID
        
        if let historyId = historyId {
            DispatchQueue.main.safeAsync {
                let message = String(format: "DC.toast.delete.message.format.single".localized, 1)
                
                let toastData = SVKToastData(with: .confirmation, message: message, offset: Float(self.inputViewContainer.bounds.height), action: SVKAction(title: "DC.toast.delete.action".localized))
                
                self.view.showToast(with: toastData) {
                    
                    self.delegate?.deleteHistoryEntries(ids: [historyId]) { success in
                        if success {
                            SVKAnalytics.shared.log(event: "myactivity_item_delete")
                            // Removes the concerned bubble's descriptions and rows
                            DispatchQueue.main.async {
                                self.updateConverstation(withDeleted: [indexPath])
                                self.groupingErrors()
                            }
                        } else {
                            SVKAnalytics.shared.log(event: "myactivity_item_delete_error")
                            DispatchQueue.main.safeAsync {
                                let toastData = SVKToastData(with: .default, message: "SVK.toast.deletion.error.message".localized, offset: Float(self.inputViewContainer.bounds.height))
                                
                                self.view.showToast(with: toastData)
                            }
                        }
                    }
                }
            }
        }
    }
    /**
     Display a debug view of the bubble

     - parameter indexPath: The indexPath of the bubble
     */
    func displayBubbleJSON(at indexPath: IndexPath) {
        
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "SVKInspectorViewController") as? SVKInspectorTableViewController {
            
            var indexPaths = [IndexPath]()
            
            if let historyId = self.conversation[indexPath].historyID {
                indexPaths = self.conversation.indexPathOfElements(from: indexPath) {
                    return $0.historyID == historyId
                }
            } else if let smarthubTraceId =  self.conversation[indexPath].smarthubTraceId {
                indexPaths = self.conversation.indexPathOfElements(from: indexPath) {
                    return $0.smarthubTraceId == smarthubTraceId
                }
            }
            
            // snapshots the bubbles
            var offsetY: CGFloat = 0
            indexPaths.forEach { (indexPath) in
                
                if let cell = self.tableView.cellForRow(at: indexPath) as? SVKTableViewCellProtocol,
                    let bubble = cell.concreteBubble() {
                    
                    let snapshot = bubble.superview?.snapshotView(afterScreenUpdates: false) ?? UIView()
                    
                    viewController.bubbleDescription = self.conversation[indexPath] as? SVKAssistantBubbleDescription
                    viewController.bubblesView.addSubview(snapshot)
                    snapshot.frame = snapshot.frame.offsetBy(dx: 0, dy: offsetY)
                    
                    var frame = viewController.bubblesView.frame
                    frame.size.width = snapshot.frame.maxX
                    frame.size.height = snapshot.frame.maxY
                    viewController.bubblesView.frame = frame
                    
                    offsetY = frame.size.height
                }
            }
            viewController.modalPresentationStyle = .overFullScreen
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    /**
     Enunciate the text at the index path

     - parameter indexPath: The indexPath of the bubble
    */    
    
    func enunciateBubble(at indexPath: IndexPath) {
        var indexPathToVocalized = indexPath
        if let description = self.conversation[indexPathToVocalized] as? SVKUserBubbleDescription {
            
            let indexPaths = self.conversation.indexPathOfElements(from: indexPath, groupedBy: { $0.historyID == description.historyID || $0.smarthubTraceId == description.smarthubTraceId })
            if indexPaths.count > 1 {
                indexPathToVocalized = indexPaths[1]
            }
            
        }
        guard let description = self.conversation[indexPathToVocalized] as? SVKAssistantBubbleDescription,
            let text = description.invokeResult?.text ?? description.text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
        }
        SVKAudioPlayer.shared.stop(resumeMusic: false)

        SVKLogger.debug("vocalizing: '\(text)'")
        SVKAnalytics.shared.log(event: "conversation_answer_replay")
        self.delegate?.vocalizeText(text) { data in
            if let audioData = data {
                SVKSpeechSession.shared.startVocalize(text, stream: audioData)
            } else {
                SVKAnalytics.shared.log(event: "conversation_answer_vocalization_error")
            }
        }
    }
    
    func removeRecoBubbles() {
        var indexPathRecos = [IndexPath]()
        
        for (indexPath, element) in self.conversation.enumerated().reversed() {
            if element.contentType == .recoText {
                indexPathRecos.append(indexPath)
            }
        }
        
        self.removeRow(from: indexPathRecos)
    }
    /**
     Re-send the text at the index Path
     
     - parameter: indexPath: the IndexPath of the bubble
     */
    func resendBubble(at indexPath: IndexPath) {
        guard let description = self.conversation[indexPath] as? SVKUserBubbleDescription,
            description.contentType == .text,
            let text = description.content?.0 as? String,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
        }
        SVKLogger.debug("resendText: '\(text)'")
        SVKAnalytics.shared.log(event: "conversation_question_resend")
        
        removeRecoBubbles()
        if let userInputViewController = self.userInputViewController {
            self.inputController(userInputViewController, didAccept: text, from: .keyboard)
        } else {
            SVKLogger.debug("resendText: '\(text)' failed: no userInputViewController")
        }
    }
    
    func recoverBubbleView(at indexPath: IndexPath)-> UIView?{

        guard let cellView = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        switch cellView {
        case is SVKAssistantTextTableViewCell:
            return (cellView as? SVKAssistantTextTableViewCell)?.bubble
        case is SVKAssistantDisabledTextTableViewCell:
            return (cellView as? SVKAssistantDisabledTextTableViewCell)?.bubble
        case is SVKAssistantImageTableViewCell:
            return (cellView as? SVKAssistantImageTableViewCell)?.bubble
        case is SVKAssistantGenericTableViewCell:
            return (cellView as? SVKAssistantGenericTableViewCell)?.bubble
        case is SVKUserTextTableViewCell:
            return (cellView as? SVKUserTextTableViewCell)?.bubble
        default:
            return nil
        }
    }
}
