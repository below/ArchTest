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

class SVKErrorHeaderTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol {
   
    @IBOutlet public var bubble: SVKTextBubble!
    
    @IBOutlet var rafterButton: UIButton! = UIButton()
    
    @IBOutlet weak var signalFlag: UIImageView!
    var tapGesture = UITapGestureRecognizer()
    var isTapGestureEnabled = true
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleExpandable(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }

    var collapsedColor = UIColor(red: 221/255, green: 221/255, blue: 221/255, alpha: 1)
    var expandedColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
    
    var bubbleDescription: SVKHeaderErrorBubbleDescription?
    var errorDelegate: SVKActionErrorDelegate?
    
    func updateColor() {
        
        if let bubbleDescription = self.bubbleDescription {
            let appearance = bubbleDescription.appearance
            let headerCollapsedBubbleAppearance = appearance.headerErrorCollapsedBubbleAppearance
            let headerExpandedBubbleAppearance = appearance.headerErrorExpandedBubbleAppearance
            
            collapsedColor = headerCollapsedBubbleAppearance.textColor
            expandedColor = headerExpandedBubbleAppearance.textColor
        }
        if let bubbleDescription = self.bubbleDescription, bubbleDescription.isExpanded {
            rafterButton?.imageView?.tintColor = expandedColor
            bubble.textColor = expandedColor
        } else {
            rafterButton?.imageView?.tintColor = collapsedColor
            bubble.textColor = collapsedColor
        }
        updateAvatar()
    }
    
    // TODO : We should add this icon in the appearanceSettings
    func updateAvatar() {
        if let bubbleDescription = self.bubbleDescription {
            var avatarKey = "djingoIconeCopy"
            if #available(iOS 13.0, *),
                SVKAppearanceBox.shared.appearance.userInterfaceStyle.contains(.dark){
                switch (traitCollection.userInterfaceStyle,bubbleDescription.isExpanded) {
                case (.dark, false):
                    avatarKey = "djingoIconeCopy"
                case (.dark,true):
                    avatarKey = "djingo-avatar-gray"
                case (.light, false), (.unspecified, false):
                    avatarKey = "djingoIconeCopy"
                case (.light,true), (.unspecified,true):
                    avatarKey = "djingo-avatar-gray"
                @unknown default:
                    avatarKey = "djingoIconeCopy"
                }
            } else {
                avatarKey = bubbleDescription.isExpanded ? "djingo-avatar-gray" : "djingoIconeCopy"
            }
            avatar.image = SVKTools.imageWithName(avatarKey)
            if dedicatedPreFixLocalisationKey == "djingo" {
                layoutAvatar(hidden: false)
            } else {
                layoutAvatar(hidden: true)
            }
        }
    }
    
    @objc func toggleExpandable(_ button: UIButton) {
        if isTapGestureEnabled {
            rafterButton.transform = rafterButton.transform.rotated(by: CGFloat(Double.pi))
            if let bubbleDescription = self.bubbleDescription {
                self.errorDelegate?.toggleAction(from: bubbleDescription)
                self.bubbleDescription?.isExpanded = !bubbleDescription.isExpanded
                updateColor()
            }
        }
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        signalFlag.image = SVKAppearanceBox.Assets.flag?.withRenderingMode(.alwaysTemplate)
        bubble.foregroundColor = .clear
        
        rafterButton.transform = CGAffineTransform.identity
        if dedicatedPreFixLocalisationKey == "djingo" {
            rafterButton.setImage(UIImage(named: "chevron_w", in: SVKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
            rafterButton.transform = rafterButton.transform.rotated(by: CGFloat(.pi/2.0))
        } else {
            rafterButton.setImage(UIImage(named: "arrowDown", in: SVKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        if let bubbleDescription = content as? SVKHeaderErrorBubbleDescription {
            self.bubbleDescription = bubbleDescription
            bubble.text = bubbleDescription.text
            bubble.font = bubbleDescription.appearance.headerErrorExpandedBubbleAppearance.font
            if bubbleDescription.isExpanded {
                rafterButton.transform = rafterButton.transform.rotated(by: CGFloat(Double.pi))
            }
            updateColor()
        } else {
            self.bubbleDescription = nil
        }
        
    }
}
