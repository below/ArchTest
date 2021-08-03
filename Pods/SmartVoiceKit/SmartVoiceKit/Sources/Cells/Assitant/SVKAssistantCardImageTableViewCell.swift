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

final class SVKAssistantCardImageTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol, CardDarkable {
    static let cardKey: WritableKeyPath<SVKAssistantCardImageTableViewCell, SVKGenericBubble>  = \SVKAssistantCardImageTableViewCell.bubble
    @IBOutlet public var bubble: SVKGenericBubble!
    @IBOutlet var actionViewImageViewConstraint: NSLayoutConstraint!
    @IBOutlet var actionViewTextViewConstraint: NSLayoutConstraint!
    
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var subTitleViewSourceViewConstraint: NSLayoutConstraint!
    
    @IBOutlet var subTitleViewBottomConstaint: NSLayoutConstraint!
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var actionView: UIView!
    @IBOutlet var textView: UIView!
    @IBOutlet var actionSeparator: UIView!
    @IBOutlet var rafterImageView: UIImageView!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        rafterImageView?.image = UIImage(named: "chevron_w", in: SVKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        rafterImageView?.tintColor = SVKConversationAppearance.shared.tintColor
        setupInitialContext()
    }

    private func setupInitialContext() {
        bubble.extendTextLabel(true)
        
        NSLayoutConstraint.deactivate([actionViewImageViewConstraint,actionViewTextViewConstraint,
                                       textViewBottomConstraint,imageViewBottomConstraint,
                                       subTitleViewBottomConstaint,subTitleViewSourceViewConstraint])

        textView.alpha = 0
        actionView.alpha = 0
        actionSeparator.alpha = 0
        bubble.sourceLabel?.alpha = 0.0
        bubble.sourceLabel?.text = nil
        bubble.detailsLabel?.text = ""
        bubble.imageView?.image = nil
        bubble.iconImageView?.image = nil
        
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
            let card = bubbleDescription.card else {
                return
        }
        setBubbleStyle(bubbleDescription.bubbleStyle)

        super.layoutAvatar(for: bubbleDescription)
        self.bubble.cornerRadius = bubbleDescription.appearance.assistantBubbleAppearance.cornerRadius

        switch bubbleDescription.contentType {
        case .imageCard:
            fillGenericCard(with: bubbleDescription)
            return
        default:
            break
        }

        bubble.titleLabel.text = card.data?.text
        if let items = bubbleDescription.card?.data?.items  {
            
            var index = 0
            var text = "\u{2022} \(items[index])"
            
            while index < items.count - 1 && index < 9 {
                index += 1
                text += "\n\u{2022} \(items[index])"
            }
            bubble.subTitleLabel.text  = text
            if items.count > 10 {
                let itemsLeft = items.count - 10
                bubble.sourceLabel?.text = "DC.genericCard.imageList.item".localized(value:itemsLeft)
//                let itemLabel = items.count == 11 ? "DC.genericCard.imageList.item".localized : "DC.genericCard.imageList.items".localized
//                bubble.sourceLabel?.text = String(format: "DC.genericCard.imageList.otherItems".localized, itemsLeft, itemLabel)
            }
        } else {
            bubble.subTitleLabel.text = nil
        }
        bubble.subTextLabel.text = ""
        
        bubble.setImage(with: card.data?.iconUrl)
        switch bubbleDescription.contentType {
        case .recipeCard:
            if isCardHackEnabled {
                if card.data?.durationString == nil {
                    bubble.titleLabel.text = card.data?.titleText
                    bubble.textLabel.text = card.data?.text
                } else {
                    bubble.textLabel.text = card.data?.durationString?.formatPTHMtoMinutes() ?? card.data?.durationString
                    bubble.titleLabel.text = card.data?.titleText
                }
            } else {
                bubble.titleLabel.text = card.data?.titleText
                bubble.textLabel.text = card.data?.text
            }
            break
        case .weatherCard:
            bubble.imageView?.image = nil
            
            if isCardHackEnabled {
                bubble.titleLabel.text = card.data?.weatherType
                bubble.subTitleLabel.text = card.data?.location
                bubble.textLabel.text = card.temperature
                bubble.subTextLabel.text = card.boundedTemperatures
                bubble.setImage(with: card.data?.weatherImage)
                bubble.setIconImage(with: card.data?.weatherIcon)                
            } else {
                bubble.textLabel.text = card.data?.titleText
                bubble.subTextLabel.text = card.data?.subTitle
                bubble.titleLabel.text = card.data?.text
                bubble.subTitleLabel.text = card.data?.subText
                bubble.setImage(with: card.data?.iconUrl)
            }
        default:
            bubble.textLabel.text = card.data?.text
            bubble.titleLabel.text = card.data?.titleText
        }
        
        updateTextViewActionViewConstraints()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
    }
    
    private func updateTextViewActionViewConstraints() {
        var isTextViewVisible = true
        var isActionViewVisible = true
        var isSourceViewVisible = true
        if (bubble.titleLabel.text ?? "").isEmpty &&
            (bubble.subTitleLabel.text ?? "").isEmpty &&
            (bubble.textLabel.text ?? "").isEmpty &&
            (bubble.subTextLabel.text ?? "").isEmpty {
            isTextViewVisible = false
        }
        if (bubble.detailsLabel?.text ?? "").isEmpty {
            isActionViewVisible = false
        }
        
        if (bubble.sourceLabel?.text ?? "").isEmpty {
            isSourceViewVisible = false
        }
        
        var constraintsDesactivated:[NSLayoutConstraint] = []
        var constraintsActivated:[NSLayoutConstraint] = []

        switch (isTextViewVisible,isActionViewVisible) {
            case (true,true):
                textView.alpha = 1.0
                actionView.alpha = 1.0
                actionSeparator.alpha = 1.0
                constraintsDesactivated.append(contentsOf: [actionViewImageViewConstraint,textViewBottomConstraint,imageViewBottomConstraint])
                constraintsActivated.append(actionViewTextViewConstraint)
                if isSourceViewVisible {
                    bubble.sourceLabel?.alpha = 1.0
                    constraintsActivated.append(subTitleViewSourceViewConstraint)
                    constraintsDesactivated.append(subTitleViewBottomConstaint)
                } else {
                    constraintsActivated.append(subTitleViewBottomConstaint)
                    constraintsDesactivated.append(subTitleViewSourceViewConstraint)
                }
            case (true,false):
                textView.alpha = 1.0
                constraintsDesactivated.append(contentsOf: [actionViewImageViewConstraint,imageViewBottomConstraint,actionViewTextViewConstraint])
                constraintsActivated.append(contentsOf: [textViewBottomConstraint])
                if isSourceViewVisible {
                    bubble.sourceLabel?.alpha = 1.0
                    constraintsActivated.append(subTitleViewSourceViewConstraint)
                    constraintsDesactivated.append(subTitleViewBottomConstaint)
                } else {
                    constraintsActivated.append(subTitleViewBottomConstaint)
                    constraintsDesactivated.append(subTitleViewSourceViewConstraint)
                }
            case (false,true):
                actionView.alpha = 1.0
                constraintsDesactivated.append(contentsOf: [imageViewBottomConstraint,actionViewTextViewConstraint,
                                                            textViewBottomConstraint,subTitleViewSourceViewConstraint,
                                                            subTitleViewBottomConstaint])
                constraintsActivated.append(actionViewImageViewConstraint)
            case (false,false):
                constraintsDesactivated.append(contentsOf: [actionViewImageViewConstraint,actionViewTextViewConstraint,
                                                            textViewBottomConstraint,subTitleViewSourceViewConstraint,
                                                            subTitleViewBottomConstaint])
                constraintsActivated.append(imageViewBottomConstraint)
        }
        NSLayoutConstraint.deactivate(constraintsDesactivated)
        NSLayoutConstraint.activate(constraintsActivated)
    }
    
    override func updateConstraints() {
        updateTextViewActionViewConstraints()
        super.updateConstraints()
    }
    override func layoutSubviews() {
        updateTextViewActionViewConstraints()
        super.layoutSubviews()
    }
    
    private func fillGenericCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
        bubble.subTitleLabel.text = bubbleDescription.card?.data?.subTitle
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.setImage(with: bubbleDescription.card?.data?.iconUrl)
        bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        bubble.sourceLabel?.text = nil
        
        if let layout = bubbleDescription.card?.data?.layout {
            switch layout {
            case .imageList:
                if let items = bubbleDescription.card?.data?.items  {
                    
                    var index = 0
                    var text = "\u{2022} \(items[index])"
                    
                    while index < items.count - 1 {
                        index += 1
                        text += "\n\u{2022} \(items[index])"
                    }
                    bubble.subTitleLabel.text  = text
                    bubble.sourceLabel?.text = bubbleDescription.card?.data?.subText
                } else {
                    bubble.subTitleLabel.text = nil
                }
                bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
//                bubble.subTextLabel.textColor = UIColor.black
                bubble.extendSubTextLabel(true)
            case .imageFullText:
//                bubble.subTitleLabel.textColor = UIColor.greyishBrown
                bubble.sourceLabel?.alpha = 0.0
                bubble.extendSubTextLabel(true)
                bubble.textLabel.text = nil
                bubble.subTextLabel.text = nil
            // .generic
            default:
                bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
//                bubble.subTextLabel.textColor = UIColor.black
                bubble.sourceLabel?.alpha = 0.0
                bubble.extendSubTextLabel(false)
            }
            updateTextViewActionViewConstraints()
            concreteBubble()?.setNeedsUpdateConstraints()
            concreteBubble()?.layoutIfNeeded()
        }
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
    }
}
