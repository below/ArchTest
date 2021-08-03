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
import Kingfisher

/**
 A class representing the appearance of the conversation view controller
 including the appearance for each skill
 */
public class SVKConversationAppearance {
    
    /// The shared singleton conversation appearance object.
    public static let shared = SVKConversationAppearance()
    
    private init() {}
    
    /// The default background color
    public var backgroundColor: UIColor { return SVKAppearanceBox.shared.appearance.backgroundColor.color }

    /// The default background view
    public var backgroundView: UIView = UIView(frame: .zero)

    /// The default skill appearane. The Djingo's skill
    public var defaultSkillAppearance: SDKSkillAppearance{
        SVKAppearanceBox.shared.appearance.SVKSkillAppearanceWrapper
    }
    

    /// The tintColor
    public var tintColor: UIColor { return SVKAppearanceBox.shared.appearance.tintColor.color }
    
    /// The audio input color
    public var audioInputColor: UIColor { return SVKAppearanceBox.shared.appearance.audioInputColor.color }
    /// The button's highlighted state color: same for fill, shape color
    public var hightlightedBtnColor: UIColor {
        return SVKAppearanceBox
        .shared
        .appearance
        .buttonStyle
        .highlightedState
        .shapeColor
        .color
    }
    
    /// The loadMoreControl appearance for the user
    public var loadMoreControlAppearance: SVKLoadMoreControlAppearance = SVKLoadMoreControlAppearance()
    
    /**
     A dictionary thats contains skills appearances.
     An app which that would customize skills appearance should provide an appearance for each skills.
     The key/value is skillIdentifier/SDKSkillAppearance
     */
    public var skillsAppearance: [String: SDKSkillAppearance] = [:]
    
    /**
     Returns a SDKSkillAppearance for a skill
     - parameter skillId: The identifier of the skill requested
     - returns: The SVKSkillAppeance matching skillId the default one otherwise
     */
    func appearance(for skillId: String) -> SDKSkillAppearance {
        return skillsAppearance[skillId] ?? defaultSkillAppearance
    }
    
    public var skillCatalog: [String: SVKSkillCatalog] = [:]
    
    public var isFirstTimeWelcomeMessageShown: Bool = false
    public var isSecondTimeWelcomeMessageApplicable: Bool = true
}

/**
 This struct represents a skill appearance
 */
public struct SDKSkillAppearance: Equatable {
            
    /// The bubble appearance for the assistant
    public var assistantBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: .defaultAssistantColor, flagColor: .defaultAssistantColor, textColor: .defaultAssistantText,borderColor: .defaultAssistantColor)

    /// The bubble appearance for the user
    public var userBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: .defaultUserColor, flagColor: .defaultUserColor, textColor: .defaultUserText, borderColor: .defaultUserColor)
    
    /// The Error bubble appearance for the header
    public var headerErrorCollapsedBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: SVKConversationAppearance.shared.backgroundColor , flagColor: UIColor(hex: "#DDDDDD") , textColor: UIColor(hex: "#DDDDDD"), borderWidth: 0.0, borderColor: SVKConversationAppearance.shared.backgroundColor )
    
    public var headerErrorExpandedBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: SVKConversationAppearance.shared.backgroundColor , flagColor: UIColor(hex: "#9B9B9B") , textColor: UIColor(hex: "#9B9B9B"), borderWidth: 0.0, borderColor: SVKConversationAppearance.shared.backgroundColor )
    
    /// The Error bubble appearance for the user
    public var userErrorBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: SVKConversationAppearance.shared.backgroundColor , flagColor: UIColor(hex: "#9B9B9B") , textColor: UIColor(hex: "#9B9B9B"), borderWidth: 2.5, borderColor: UIColor(hex: "#9B9B9B"))
    
    /// The Error bubble appearance for the asssitant
    public var assistantErrorBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: UIColor(hex: "#9B9B9B") , flagColor: UIColor(hex: "#9B9B9B") , textColor: SVKConversationAppearance.shared.backgroundColor, borderWidth: 2.0, borderColor: UIColor(hex: "#9B9B9B"))
    
    /// The reco bubble appearance
    public var recoBubbleAppearance: SVKBubbleAppearance = SVKBubbleAppearance(foregroundColor: SVKConversationAppearance.shared.backgroundColor , flagColor: UIColor(hex: "#9B9B9B") , textColor: UIColor(hex: "#9B9B9B"), borderWidth: 2.5, borderColor: UIColor(hex: "#9B9B9B"))
    
    /// The URL of the skill's icon
    internal var avatarURL: URL?
    
    /// The avatar image
    internal var avatarImage: UIImage?
    
    public init() {
        self.avatarImage = SVKTools.imageWithName("djingo-avatar")
    }
    
    /**
     Initialize with bubble appearance and image URL
    */
    public init(assistantBubbleAppearance: SVKBubbleAppearance, userBubbleAppearance: SVKBubbleAppearance, headerErrorCollapsedBubbleAppearance: SVKBubbleAppearance, headerErrorExpandedBubbleAppearance: SVKBubbleAppearance, userErrorBubbleAppearance: SVKBubbleAppearance, assistantErrorBubbleAppearance: SVKBubbleAppearance, recoBubbleAppearance: SVKBubbleAppearance,avatarURL: URL? = nil) {
        self.assistantBubbleAppearance = assistantBubbleAppearance
        self.userBubbleAppearance = userBubbleAppearance
        self.headerErrorCollapsedBubbleAppearance = headerErrorCollapsedBubbleAppearance
        self.headerErrorExpandedBubbleAppearance = headerErrorExpandedBubbleAppearance
        self.userErrorBubbleAppearance = userErrorBubbleAppearance
        self.assistantErrorBubbleAppearance = assistantErrorBubbleAppearance
        self.recoBubbleAppearance = recoBubbleAppearance
        self.avatarURL = avatarURL
    }

    /**
     Initialize with bubble appearance and image URL
     */
    public init(assistantBubbleAppearance: SVKBubbleAppearance, userBubbleAppearance: SVKBubbleAppearance, avatarImage: UIImage? = nil) {
        self.assistantBubbleAppearance = assistantBubbleAppearance
        self.userBubbleAppearance = userBubbleAppearance
        self.avatarImage = avatarImage
    }
}

/**
 That class represents a conversation bubble appeareance
 */
public struct SVKBubbleAppearance: Equatable {
    
    /// The foreground color for this skill's bubbles. Default to UIColor.djingo
    public var foregroundColor: UIColor = UIColor.defaultAssistantColor
    
    /// The foreground color for this skill's bubbles. Default to UIColor.djingo
    public var borderWidth: CGFloat = SVKBubble.defaultborderWidth
    
    /// The border color for this skill's bubbles. Default to UIColor.djingo
    public var borderColor: UIColor = UIColor.defaultAssistantColor
    
    /// The text color for this skill's bubbles. Default to UIColor.djingoText
    public var textColor: UIColor = UIColor.defaultAssistantText
    
    /// The color of the flag that can be displayed close to the bubble
    public var flagColor: UIColor = UIColor.defaultAssistantColor
    
    /// The bubble cornerRadius
    public var cornerRadius = SVKCorner.defaultRadius

    /// The bubble font
    public var font = SVKTextBubble.defaultFont

    /// The bubble pin style. Default to .none
    public var pinStyle: SVKPinStyle = .default
    
    /// The bubble's contentInset
    public var contentInset: UIEdgeInsets? = SVKTextBubble.defaultContentInset
    
    /// **true** if the checkmark must be displayed
    public var isCheckmarkEnabled = true
    
    /**
     Initialize the struct
     */
    public init(foregroundColor: UIColor,
                flagColor: UIColor,
                textColor: UIColor,
                cornerRadius: CGFloat = SVKCorner.defaultRadius,
                borderWidth: CGFloat = SVKBubble.defaultborderWidth,
                borderColor: UIColor = UIColor.defaultAssistantColor,
                font: UIFont = SVKTextBubble.defaultFont,
                pinStyle: SVKPinStyle = .default,
                contentInset: UIEdgeInsets? = nil) {
        self.foregroundColor = foregroundColor
        self.flagColor = flagColor
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.font = font
        self.pinStyle = pinStyle
        self.contentInset = contentInset
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    public init() {}
}

/**
 That class represents a conversation bubble appeareance
 */
public struct SVKLoadMoreControlAppearance: Equatable {
    
    /// The background color for loadmoreControl. Default to UIColor.clear
    public var backgroundColor: UIColor = UIColor.clear
    
    /// the type of animation for the activity indicator. Default to the native IOS activity indicator
    public var animationType:SVKLoadMoreControlAnimationType = .activityIndicator
    
    /**
     Initialize the struct
     */
    public init(backgroundColor: UIColor, animationType: SVKLoadMoreControlAnimationType) {
        self.backgroundColor = backgroundColor
        self.animationType = animationType
    }
    
    public init() {}
}

 
