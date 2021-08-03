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

protocol CardDarkable{
    associatedtype SVKCARD
    static var cardKey: WritableKeyPath<Self, SVKCARD> { get }
    func configureColors()
}
extension CardDarkable where SVKCARD: SVKGenericBubble{
    func configureColors(){
        self[keyPath: Self.cardKey].foregroundColor = SVKAppearanceBox.cardBackgroundColor
        self[keyPath: Self.cardKey].borderColor = SVKAppearanceBox.cardBorderColor
        self[keyPath: Self.cardKey].cornerRadius = SVKAppearanceBox.cardCornerRadius
        self[keyPath: Self.cardKey].titleLabel.textColor = SVKAppearanceBox.cardTextColor
        self[keyPath: Self.cardKey].subTextLabel.textColor = SVKAppearanceBox.cardSupplementaryTextColor
        self[keyPath: Self.cardKey].subTitleLabel.textColor = SVKAppearanceBox.cardTextColor
        self[keyPath: Self.cardKey].textLabel.textColor = SVKAppearanceBox.cardTextColor
        self[keyPath: Self.cardKey].sourceLabel?.textColor = SVKAppearanceBox.cardTextColor
        self[keyPath: Self.cardKey].detailsLabel?.textColor = SVKAppearanceBox.cardTextColor
    }
}
final class SVKSecondGenericDefaultTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol, CardDarkable {
    
    static let cardKey: WritableKeyPath<SVKSecondGenericDefaultTableViewCell, SVKGenericBubble>  = \SVKSecondGenericDefaultTableViewCell.bubble

    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet public var bubble: SVKGenericBubble!
    
    @IBOutlet weak var actionView: UIView!
    
    internal override func layoutAvatar(hidden: Bool) {
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription else {
            return
        }
        
        bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
        bubble.subTitleLabel.text = bubbleDescription.card?.data?.subTitle
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
        bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
        bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
        bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        
        configureColors()
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }

        // mask the avatar if needed
        let isAvatarMasked = bubbleDescription.appearance.avatarURL == nil && bubbleDescription.appearance.avatarImage == nil
        layoutAvatar(hidden: isAvatarMasked)

        updateImageViewActionViewConstraints()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
        self.setNeedsUpdateConstraints()
        self.layoutIfNeeded()
    }
    
    private func setupInitialContext() {
        bubble.textLabel.text = nil
        bubble.subTextLabel.text = nil
        bubble.titleLabel.text = nil
        bubble.subTitleLabel.text = nil
        bubble.subTitleLabel.isHidden = false
        bubble.descriptionLabel?.text = nil
        bubble.sourceLabel?.text = nil
        bubble.imageView?.image = nil
        bubble.detailsLabel?.text = nil
        bubble.extendTextLabel(false)
        bubble.tapAction = nil
        bubble.extendSubTextLabel(false)
        updateImageViewActionViewConstraints()
    }
    
    private func updateImageViewActionViewConstraints() {
        let rs = bubble.sourceLabel?.text
        let at =  bubble.detailsLabel?.text
        
        if (rs ?? "").isEmpty && (at ?? "").isEmpty {
            imageViewBottomConstraint.constant = 34
        } else {
            imageViewBottomConstraint.constant = 62
        }
        bubble.setNeedsDisplay()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bubble.prepareForReuse()
        setupInitialContext()
    }
}
    
