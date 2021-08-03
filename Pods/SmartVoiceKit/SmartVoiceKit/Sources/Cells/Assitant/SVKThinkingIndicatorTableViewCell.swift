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

// loads at startup to prevent slow animation at the first use of this cell
let svkThreeDotAnimationImages = UIImage.animationImages(named: "animation-dots", bundle: SVKBundle, withExtension: "gif")

open class SVKThinkingIndicatorTableViewCell: SVKTableViewCell {
    @IBOutlet public var bubble: SVKImageBubble!
    public func concreateBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.isTimestampHidden = true
        setupBubble()
    }
    
    func setupBubble() {
        DispatchQueue.main.async {
            if let images = svkThreeDotAnimationImages {
                self.bubble.imageViewContentMode = .scaleAspectFit
                self.bubble.image = UIImage.animatedImage(with: images, duration: 0)?.withRenderingMode(.alwaysTemplate)
                self.bubble.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                self.bubble.setNeedsLayout()
            }
        }
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        
        guard let bubbleDescription = content as? SVKBubbleDescription else {
            return
        }

        bubble.startAnimating()
        if let description = bubbleDescription as? SVKAssistantBubbleDescription {
            super.layoutAvatar(for: description)
        }
        bubble.style = bubbleDescription.bubbleStyle

        let appearance = SVKConversationAppearance.shared.defaultSkillAppearance
        bubble.foregroundColor = appearance.assistantBubbleAppearance.foregroundColor
    }
}


open class SVKUserThinkingIndicatorTableViewCell: SVKThinkingIndicatorTableViewCell {
    override func fill<T>(with content: T) {
        super.fill(with: content)
        let appearance = SVKConversationAppearance.shared.defaultSkillAppearance
        bubble.foregroundColor = appearance.userBubbleAppearance.foregroundColor
    }
}

