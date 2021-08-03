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

open class SVKUserTextTableViewCell: SVKAssistantTextTableViewCell {

    @IBOutlet var bubbleTrailingToAvatar: NSLayoutConstraint?
    var origin: SVKBubbleDescriptionType = .history

    private var votesUsed: [SVKFeedback] {
        if dedicatedPreFixLocalisationKey == "djingo" {
            return [.speechMisunderstoodRightSkillInvoked,
                     .speechMisunderstoofWrongSkillInvoked,
                     .unintededActivation]
        } else {
            return [.speechUnderstoodWrongSkillInvoked,
                    .speechMisunderstoodRightSkillInvoked,
                     .speechMisunderstoofWrongSkillInvoked,
                     .unintededActivation,
                     .speechVocalisedWrongly]
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        self.bubble.foregroundColor = UIColor.defaultUserColor
        self.bubble.textColor = UIColor.defaultUserText
    }

    override func setBubbleStyle(_ style: SVKBubbleStyle) {
        bubble.style = style
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        signalFlag.isHidden = true
        origin = .history
    }
    
    override open func setEditing(_ editing: Bool, animated: Bool) {
        guard let tableView = self.superview as? UITableView else {
                return
        }
        
        if editing, tableView.allowsMultipleSelectionDuringEditing {
            avatar.alpha = origin != .conversation ? 0.0 : 1.0
            if isCellSelectable {
                selectorImageView?.isHidden = false
                selectorImageView?.image = isCellSelected ? SVKAppearanceBox.Assets.checkboxOn : SVKAppearanceBox.Assets.checkBoxOff
            }
        } else {
            avatar.alpha = origin != .conversation || tableView.isEditing ? 0.0 : 1.0
        }
    }
    
    internal override func updateCellHighlight(highlighted: Bool) {
        if highlighted {
            cellLeadingConstraint?.constant = -2
        } else {
            cellLeadingConstraint?.constant = 8
        }
    }
    
    //MARK: Reusable conforms
    override func fill<T>(with content: T) {
        super.fill(with: content)
        self.signalFlag.image = SVKAppearanceBox.Assets.flag?.withRenderingMode(.alwaysTemplate)
        if let bubbleDescription = content as? SVKUserBubbleDescription {
            let appearance = bubbleDescription.appearance
            var bubbleAppearance = appearance.userBubbleAppearance
            if bubbleDescription.contentType == .errorText, let errorCode = bubbleDescription.errorCode, SVKConstant.filteredErrorCode.contains(errorCode) {
                bubbleAppearance = appearance.userErrorBubbleAppearance
            } else if bubbleDescription.contentType == .recoText {
                bubbleAppearance = appearance.recoBubbleAppearance
            }
            
            bubble.textColor = bubbleAppearance.textColor
            setBubbleStyle(bubbleDescription.bubbleStyle)
            if let sharedPrefix = bubbleDescription.oldText {
                if let text = bubbleDescription.text, let commonText = bubbleDescription.text?.sharedPrefix(with: sharedPrefix) {
                    let index = text.index(text.startIndex, offsetBy: commonText.count)
                    let newText = text[index...]
                    let attrColor =  SVKAppearanceBox.typingTextColor
                    
                    let attrString = NSMutableAttributedString(string: text)
                    let attributes = [NSAttributedString.Key.strokeColor: attrColor,
                                      NSAttributedString.Key.foregroundColor: attrColor,
                        NSAttributedString.Key.strokeWidth: -1.5] as [NSAttributedString.Key : Any]
                    
                    attrString.addAttributes(attributes, range: NSRange(location: commonText.count, length: newText.count))
                    bubble.attributedText = attrString
                } else {
                    bubble.text = bubbleDescription.text
                }
            } else {
                bubble.text = bubbleDescription.text
            }
            if (bubbleDescription.deviceName?.isEmpty ?? true) || bubbleDescription.isDefaultDeviceNameHide {
                    setTimestampDetailsText(SVKTools.formattedDateTime(from: bubbleDescription.timestamp))
            } else {
                let date = SVKTools.formattedDateTime(from: bubbleDescription.timestamp)
                let deviceName = " - " + (bubbleDescription.deviceName ?? "")
                let text = date + deviceName
                let attrString = NSMutableAttributedString(string: text)
                if let timestampDetails = self.timestampDetails {
                    let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: timestampDetails.font.pointSize, weight: .bold)] as [NSAttributedString.Key : Any]
                    attrString.addAttributes(attributes, range: NSRange(location: date.count, length: deviceName.count))
                    timestampDetails.attributedText = attrString
                }
            }
            setErrorMessageText(nil)
            isTimestampDetailsHidden = bubbleDescription.isTimestampDetailsHidden
            signalFlag.tintColor = bubbleAppearance.flagColor
            signalFlag.isHidden = !votesUsed.contains(bubbleDescription.vote)
            origin = bubbleDescription.origin
            
            var hideSentStatusIndicator = bubbleAppearance.isCheckmarkEnabled == false
            
            var imageStatus: UIImage? = nil
            
            switch (bubbleDescription.origin, bubbleDescription.deliveryState)  {
            case (.history, _):
                hideSentStatusIndicator = true
                
            case (.conversation, .delivered):
                imageStatus = SVKTools.imageWithName("message-delivered")
                
            case (.conversation, .beingDelivered):
                imageStatus = SVKTools.imageWithName("message-being-delivered")
                
            case (.conversation, .notDelivered ):
                imageStatus = SVKTools.imageWithName("message-not-delivered")
                setErrorMessageText("conversation.message.not.delivered".localized)
            }
            
            avatar.isHidden = hideSentStatusIndicator
            bubbleTrailingToAvatar?.constant = hideSentStatusIndicator ? -16 : 2
            avatar.image = imageStatus

            bubble.foregroundColor = bubbleAppearance.foregroundColor
            bubble.cornerRadius = bubbleAppearance.cornerRadius
            bubble.font = bubbleAppearance.font
            bubble.pinStyle = bubbleAppearance.pinStyle
            bubble.borderColor = bubbleAppearance.borderColor
            bubble.layerBorderWidth = bubbleAppearance.borderWidth
            if let contentInset = bubbleAppearance.contentInset {
                bubble.contentInset = contentInset
            }

            bubble.tapAction = { [weak self] (bubble, userInfo) in 
                if let userInfo = userInfo as? [String:Any],
                    var bubbleDescription = userInfo["description"] as? SVKUserBubbleDescription,
                    let sectionDescription = userInfo["sectionDescription"] as? SVKSectionDescription,
                    let indexPath =  userInfo["indexPath"] as? IndexPath  {
                    
                    // toggle display user message timestamp
                    bubbleDescription.isTimestampDetailsHidden = !bubbleDescription.isTimestampDetailsHidden
                    sectionDescription.elements[indexPath.row]  = bubbleDescription
                    if let tableView = self?.superview as? UITableView {
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }

            self.contentView.layoutIfNeeded()
        }
    }
}
