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

open class SVKAssistantTextTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol {

    @IBOutlet public var bubble: SVKTextBubble!
    @IBOutlet var signalFlag: UIImageView!

    private var votesUsed : [SVKFeedback] {
        if dedicatedPreFixLocalisationKey == "djingo" {
            return [.speechUnderstoodWrongSkillInvoked, .speechVocalisedWrongly]
        } else {
            return []
        }
    }

    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        self.signalFlag.image = self.signalFlag.image?.withRenderingMode(.alwaysTemplate)
    }

    /**
     Sets the bubble style.
     The function applies the correct bottom layout and set the avatar if needed
     - parameter style: the bubble style
     */
    func setBubbleStyle(_ style: SVKBubbleStyle) {
        bubble.style = style
        switch style {
        case .bottom(.left):
            topSpaceConstant = 5
        case .middle(.left):
            topSpaceConstant = 5
        default: break
        }
    }
    
    func updateAvatar(for bubbleDescription: SVKAssistantBubbleDescription) {
        
        var avatarKey = "djingo-avatar-gray"
        if #available(iOS 13.0, *),
            SVKAppearanceBox.shared.appearance.userInterfaceStyle.contains(.dark){
            switch traitCollection.userInterfaceStyle {
            case .dark:
                avatarKey = "djingo-avatar-gray"
            case .light, .unspecified:
                avatarKey = "djingo-avatar-gray"
            @unknown default:
                avatarKey = "djingo-avatar-gray"
            }
        }
        
        if bubbleDescription.shoudDisplayAvatar(), dedicatedPreFixLocalisationKey == "djingo" {
            avatar.image = SVKTools.imageWithName(avatarKey)
            layoutAvatar(hidden: false)
        }
        else {
            avatar.image = nil
            layoutAvatar(hidden: true)
        }
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        self.signalFlag.image = SVKAppearanceBox.Assets.flag?.withRenderingMode(.alwaysTemplate)
        if let bubbleDescription = content as? SVKAssistantBubbleDescription {
            
            let appearance = bubbleDescription.appearance
            var bubbleAppearance = appearance.assistantBubbleAppearance
            if bubbleDescription.contentType == .errorText,
                let errorCode = bubbleDescription.errorCode,
                SVKConstant.filteredErrorCode.contains(errorCode) {
                bubbleAppearance = appearance.assistantErrorBubbleAppearance
                updateAvatar(for: bubbleDescription)
            } else {
                super.layoutAvatar(for: bubbleDescription)
            }
            
            self.bubble.foregroundColor = bubbleAppearance.foregroundColor
            self.bubble.textColor = bubbleAppearance.textColor
            
            
            
            setBubbleStyle(bubbleDescription.bubbleStyle)
            bubble.text = bubbleDescription.text
            signalFlag.tintColor = bubbleAppearance.flagColor
            signalFlag.isHidden = !votesUsed.contains(bubbleDescription.vote) || !(bubbleDescription.bubbleStyle == .top(.left) || bubbleDescription.bubbleStyle == .default(.left))

            bubble.cornerRadius = bubbleAppearance.cornerRadius
            bubble.font = bubbleAppearance.font
            bubble.pinStyle = bubbleAppearance.pinStyle
            if let contentInset = appearance.assistantBubbleAppearance.contentInset {
                bubble.contentInset = contentInset
            }

            self.contentView.layoutIfNeeded()
            // TODO : must be deleted, only for test
        } else if let bubbleDescription = content as? SVKHeaderErrorBubbleDescription {
            bubble.text = bubbleDescription.text
        }
    }
}
