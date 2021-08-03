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
import Kingfisher

final class SVKAssistantCardPartnerTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol, CardDarkable {
    static let cardKey: WritableKeyPath<SVKAssistantCardPartnerTableViewCell, SVKGenericBubble> = \SVKAssistantCardPartnerTableViewCell.bubble
    
    @IBOutlet public var bubble: SVKGenericBubble!
    @IBOutlet var imageViewActionViewConstraint: NSLayoutConstraint!
    
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var iconeViewFixWidthConstraint: NSLayoutConstraint!
    @IBOutlet var iconeViewImageViewConstraint: NSLayoutConstraint!
    
    @IBOutlet var iconeViewFixheightConstraint: NSLayoutConstraint!
    @IBOutlet var actionView: UIView!
    @IBOutlet var rafterImageView: UIImageView!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        rafterImageView?.image = UIImage(named: "chevron_w", in: SVKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        rafterImageView?.tintColor = SVKConversationAppearance.shared.tintColor
        setupInitialContext()
    }

    private func setupInitialContext() {
        
        NSLayoutConstraint.deactivate([imageViewActionViewConstraint,imageViewBottomConstraint,iconeViewFixWidthConstraint,iconeViewImageViewConstraint])

        actionView.alpha = 0
        bubble.detailsLabel?.text = ""
        bubble.imageView?.image = nil
        bubble.iconImageView?.image = nil
        iconeViewFixheightConstraint.constant = 24
        iconeViewFixWidthConstraint.constant = 140
        bubble.subTitleLabel.textColor = UIColor.black
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        bubble.prepareForReuse()
        setupInitialContext()
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
            avatar.alpha = 1
        case .default(.left):
            avatar.alpha = 1
        default:
            avatar.alpha = 0
            break
        }
        configureColors()
    }
    
    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    override func fill<T>(with content: T) {
        //        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription,
            let _ = bubbleDescription.card else {
                return
        }
        setBubbleStyle(bubbleDescription.bubbleStyle)
        super.layoutAvatar(for: bubbleDescription)
        self.bubble.cornerRadius = bubbleDescription.appearance.assistantBubbleAppearance.cornerRadius

        switch bubbleDescription.contentType {            
        case .genericCard:
            fillGenericCard(with: bubbleDescription)
            return
        case .musicCard:
            if isCardHackEnabled {
                fillMusicCard(with: bubbleDescription)
            } else {
                fillGenericCard(with: bubbleDescription)
            }
        default:
            break
        }
    }
    
    private func updateImageViewActionViewConstraints() {
        var constraintsDesactivated:[NSLayoutConstraint] = []
        var constraintsActivated:[NSLayoutConstraint] = []

        if (bubble.detailsLabel?.text ?? "").isEmpty {
            constraintsDesactivated.append(imageViewActionViewConstraint)
            constraintsActivated.append(imageViewBottomConstraint)
            
        } else {
            actionView.alpha = 1.0
            constraintsDesactivated.append(imageViewBottomConstraint)
            constraintsActivated.append(imageViewActionViewConstraint)
        }
        
        if (bubble.titleLabel?.text ?? "").isEmpty {
            if let image = bubble.iconImageView.image {
                let ratio = image.size.width / image.size.height
                iconeViewFixheightConstraint.constant = 16
                iconeViewFixWidthConstraint.constant = 16 * ratio
            }
            constraintsActivated.append(iconeViewFixWidthConstraint)
            constraintsActivated.append(iconeViewImageViewConstraint)
        } else {
            iconeViewFixWidthConstraint.constant = 24
            constraintsDesactivated.append(iconeViewImageViewConstraint)
            constraintsActivated.append(iconeViewFixWidthConstraint)
        }
      
        NSLayoutConstraint.deactivate(constraintsDesactivated)
        NSLayoutConstraint.activate(constraintsActivated)
    }
    
    override func updateConstraints() {
        updateImageViewActionViewConstraints()
        super.updateConstraints()
    }
    override func layoutSubviews() {
        updateImageViewActionViewConstraints()
        super.layoutSubviews()
    }
    
    private func fillMusicCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
        bubble.titleLabel.text = "music.Deezer.subTitle".localized
        if let key = bubbleDescription.card?.type {
            bubble.subTitleLabel.text = "music.playing.\(key)".localized
        }
        bubble.iconImageView.image = SVKTools.imageWithName("iconDeezer")
        bubble.setImage(with: bubbleDescription.card?.data?.iconUrl)
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
        updateImageViewActionViewConstraints()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
        
    }
    
    private func fillGenericCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
        bubble.subTitleLabel.text = bubbleDescription.card?.data?.subTitle
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
        bubble.setImage(with: bubbleDescription.card?.data?.iconUrl)
        bubble.iconImageView.bounds.size.width = 140
        bubble.setIconImage(with: bubbleDescription.card?.data?.logoUrl, placeHolderContentMode: .scaleToFill) { _ in
            self.updateImageViewActionViewConstraints()
            self.concreteBubble()?.setNeedsUpdateConstraints()
            self.concreteBubble()?.layoutIfNeeded()
        }
        bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        updateImageViewActionViewConstraints()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
    }
}
