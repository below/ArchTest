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

class SVKAssistantMusicTableViewCell: SVKAssistantGenericTableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription else { return }
        
        if isCardHackEnabled {
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.titleLabel.text = "music.Deezer.subTitle".localized
            if let key = bubbleDescription.card?.type {
                bubble.descriptionLabel.text = "music.playing.\(key)".localized
            }
            
            bubble.iconImageView.image = SVKTools.imageWithName("iconDeezer")
            bubble.setImage(with: bubbleDescription.card?.data?.iconUrl)
        } else {
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
            bubble.descriptionLabel.text = bubbleDescription.card?.data?.typeDescription
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconPartner)
            bubble.setImage(with: bubbleDescription.card?.data?.iconUrl)
            bubble.detailsLabel?.text =  bubbleDescription.card?.data?.actionText
        }

        self.setIconButtomConstraint(defaultConstant: 17, minimumConstant: 0)
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
        
        super.layoutAvatar(for: bubbleDescription)
        self.bubble.cornerRadius = bubbleDescription.appearance.assistantBubbleAppearance.cornerRadius

    }
    
}
