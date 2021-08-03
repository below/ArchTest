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

class SVKAssistantWeatherTableViewCell: SVKAssistantGenericTableViewCell {

    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription,
            let card = bubbleDescription.card else {
                return
        }

        if isCardHackEnabled {
            bubble.descriptionLabel.text = card.data?.day
            bubble.textLabel.text = card.data?.weatherType
            bubble.subTextLabel.text = card.data?.location
            bubble.titleLabel.text = card.temperature
            bubble.subTitleLabel.text = card.boundedTemperatures
            bubble.setImage(with: card.data?.weatherImage)
            bubble.setIconImage(with: card.data?.weatherIcon)
        } else {
            bubble.descriptionLabel.text = card.data?.typeDescription
            bubble.textLabel.text = card.data?.titleText
            bubble.subTextLabel.text = card.data?.subTitle
            bubble.titleLabel.text = card.data?.text
            bubble.subTitleLabel.text = card.data?.subText
            bubble.setImage(with: card.data?.iconUrl)
        }
        
    }
}
