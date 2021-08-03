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

/**
 The content type of an SVKBubble
 */
public enum SVKBubbleContentType {
    case text
    case waitingIndicator
    case audioController
    case image
    case imageCard
    case genericCard
    case musicCard
    case weatherCard
    case memolistCard
    case timerCard
    case iotCard
    case recipeCard
    case disabledText
    case partialText
    case errorHeader
    case errorText
    case recoText
}
/**
 An interface for associating bubble description with a
 specific bubble description type
 */
protocol SVKBubbleDescription {
    /// The content and its mime-type
    var content: (Any?, String)? { get }
    
    /// The origin of the description
    var origin: SVKBubbleDescriptionType { get set }
    
    /// The id of the message in the user's history
    var historyID: String? { get }
    
    /// A backend generated ID used for workaround (we should be careful aout this ID)
    var smarthubTraceId: String? { get set }
    
    /// The index of the description in the tableView
    var bubbleIndex: Int? { get set}

    /// The style of the bubble
    var bubbleStyle: SVKBubbleStyle { get set }

    /// The current message's **SHFeedback**"
    var vote: SVKFeedback { get set }
    
    /// **true** if the content of this description is empty
    var isEmpty: Bool { get }

    /// The content type
    var contentType: SVKBubbleContentType { get set }

    /// The timestamp of the message
    var timestamp: String { get }

    /// **true** if the timestamp of the bubble is hidden
    var isTimestampHidden: Bool { get set }
    
    /// **true** if the bubble is selected for deletion
    var isSelected: Bool { get set }
    
    /// **true** if the bubble is highlighted for deletion (selected bubbles and related bubbles to the selected one)
    var isHighlighted: Bool { get set }
    
    /// A key associated to the bubble used to find it out
    var bubbleKey: Int { get set }
    
    /// The appareance of the bubble
    var appearance: SDKSkillAppearance { get }
    
    /// The id of the skill
    var skillId: String { get }

    /// **true** if the avatar is visible
    var isAvatarVisible: Bool { get set }

    /**
     Compares itself to another SVKBubbleDescription
     - parameter other: The other description to compare to
     - returns: **true** if **self** is equal to other
     */
    func isEqual(_ other: SVKBubbleDescription) -> Bool

    /**
     Returns true if the avatar should be displayed
     */
    func shoudDisplayAvatar() -> Bool
    
    var errorCode: String? { get }
    
    mutating func markAsError() 
}

extension SVKBubbleDescription {
    
    var appearance: SDKSkillAppearance {
        return SVKConversationAppearance.shared.appearance(for: skillId)
    }
    
    func shoudDisplayAvatar() -> Bool {
        var display = false
        switch bubbleStyle {
        case .bottom(.left), .default(.left):
            display = true
        default:
            display = false
        }
        return display || isAvatarVisible
    }
}

extension SVKBubbleDescription {
    mutating func markAsError() {
        if contentType == .text {
            self.contentType = .errorText
        }
    }
}

public enum SVKBubbleDescriptionType {
    /// description of a conversation
    case conversation
    /// description of a conversation history
    case history
}

public struct SVKAssistantBubbleDescription: SVKBubbleDescription, Equatable {
    
    public var invokeResult: SVKInvokeResult?
    public var contentType: SVKBubbleContentType = .text
    public var card: SVKCard?
    var skill: SVKAssistantSkill?
    var mediaLayout = SVKMediaLayout.horizontal
    
    var origin: SVKBubbleDescriptionType = .conversation
    var bubbleStyle: SVKBubbleStyle
    var isAvatarVisible = false

    // TODO: Temporary stored here
    var cardV3SubTextIsExpanded = false
    var audioStatus: SVKAudioControllerStatus = .unknown
    var seekTime: Float = 0
    var audioDuration: Float = 0

    /**
     The text displayed in the bubble
     
     It's set is private to ensure it will be processed in the init code
     */
    private(set) var text: String?

    private(set) var timestamp: String = SVKTools.iso8061DateFormatter.string(from: Date())
    var isTimestampHidden = true
    
    public var historyEntry: SVKHistoryEntry?
    
    var historyID: String?
    var smarthubTraceId: String?
    var bubbleIndex: Int?
    var vote: SVKFeedback = .none
    
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    
    var bubbleKey: Int = -1 {
        didSet {
            if var skill = self.skill as? SVKMusicPlayerSkill {
                skill.bubbleKey = self.bubbleKey
                self.skill = skill
            } else if var skill = self.skill as? SVKGenericAudioPlayerSkill {
                skill.bubbleKey = self.bubbleKey
                self.skill = skill
            }
        }
    }
    /**
     The session ID of a Djingo exchange mandatory to
     manage a ping-pong conversations.
     
     It is extracted from the **SVKInvokeResult***.
     */
    var sessionID: String? {
        guard let response = invokeResult, !response.session.finished else { return nil }
        return invokeResult?.session.id
    }

    var skillId: SVKSkillIdentifier = ""
    
    /// false if the separator line should be displayed
    var isAssistantLineSperatorHidden = true
    
    var errorCode :String?
    
    init(bubbleStyle: SVKBubbleStyle = .default(.left),
         text: String? = nil,
         type: SVKBubbleContentType = .text,
         timestamp: String? = nil,
         card: SVKCard? = nil,
         historyEntry: SVKHistoryEntry? = nil,
         invokeResult: SVKInvokeResult? = nil) {
        
        self.bubbleStyle = bubbleStyle
        self.invokeResult = invokeResult
        self.smarthubTraceId = invokeResult?.smarthubTraceId
        self.contentType = card?.type.contentType ?? type
        if let timestamp = timestamp {
            self.timestamp = timestamp
        }
        self.text = text?.process(with: .replaceUnicode)
        self.skill = SVKAssistantSkillHelper.makeSkill(with: invokeResult?.skill?.data?.kit,
                                                 card: card)
        self.skillId = invokeResult?.skill?.id ?? (historyEntry?.request?.skillId ?? "")
        self.historyEntry = historyEntry
        self.historyID = historyEntry?.id ?? invokeResult?.conversationId
        self.card = card
        self.origin = historyEntry != nil ? .history : .conversation
        self.vote = historyEntry?.vote ?? .none
        self.errorCode = historyEntry?.response?.errorCode
        self.audioStatus = card?.data?.mediaUrl?.isEmpty ?? true ? .notMedia : .unknown
        
        
        // Changing BubbleDescription, it will take fallback default values when data is nil
        let skillConfig = SVKConversationAppearance.shared.skillCatalog[skillId]
        if card?.data?.titleText == nil {
            self.card?.data?.titleText = skillConfig?.content?.displayName
        }
        if card?.data?.iconUrl == nil {
            if skillConfig?.contentDt != nil {
                self.card?.data?.iconUrl = skillConfig?.contentDt?.v2.iconOnWhiteUrl != nil ? skillConfig?.contentDt?.v2.iconOnWhiteUrl : skillConfig?.contentDt?.v2.iconUrl
            } else {
                self.card?.data?.iconUrl = skillConfig?.content?.iconUrl
            }
        }
        
        // Supporting V2 cards
        // Changing BubbleDescription data so that it can support V2 cards
        if card?.version == 1 {
            if card?.data?.actionProminentText != nil {
                self.card?.data?.prominentText = card?.data?.actionProminentText
            }
            if card?.data?.actionProminentText != nil, card?.data?.action != nil {
                self.card?.data?.actionProminentText = card?.data?.action
            }
            if card?.data?.action != nil, card?.data?.actionText != nil {
                if self.card?.data?.listSections != nil {
                    self.card?.data?.listSections?.insert(SVKListSection(title: nil, items: [SVKListSectionItem(itemText: card?.data?.actionText, itemIconUrl: nil, itemAction: card?.data?.action, title: nil, iconUrl: nil)]), at: 0)
                } else {
                    self.card?.data?.listSections = [SVKListSection(title: nil, items: [SVKListSectionItem(itemText: card?.data?.actionText, itemIconUrl: nil, itemAction: card?.data?.action, title: nil, iconUrl: nil)])]
                }
            }
            
            if let listSections = card?.data?.listSections, !(listSections.isEmpty) {
                var sections: [SVKListSection] = []
                for var list in listSections {
                    var items:[SVKListSectionItem] = []
                    for var item in list.items {
                        if item.title != nil {
                            item.itemText = item.title
                        }
                        if item.iconUrl != nil {
                            item.itemIconUrl = item.iconUrl
                        }
                        items.append(item)
                    }
                    list.items = items
                    sections.append(list)
                }
                self.card?.data?.listSections = sections
            }
        }
    }
    
    var isEmpty: Bool {
        guard let text = text else { return false }
        return text.trimmingCharacters(in: .whitespaces).isEmpty && card == nil
    }
    
    var content: (Any?, String)? {
        switch contentType {
        case .text,.image, .disabledText, .errorText:
            return (text, "public.utf8-plain-text")
        case .musicCard, .audioController:
            return (skill?.contentURL, "public.utf8-plain-text")
        default:
            return nil
        }
    }

    //MARK: Equatable
    func isEqual(_ other: SVKBubbleDescription) -> Bool {
        guard let other = other as? SVKAssistantBubbleDescription else { return false }
        return self == other
    }

    public static func == (lhs: SVKAssistantBubbleDescription, rhs: SVKAssistantBubbleDescription) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }

}


struct SVKUserBubbleDescription: SVKBubbleDescription, Equatable {
    

    enum MessageDeliveryState {
        case beingDelivered
        case delivered
        case notDelivered
    }
    
    var deliveryState = MessageDeliveryState.beingDelivered

    var contentType: SVKBubbleContentType = .text
    var origin: SVKBubbleDescriptionType = .conversation
    var bubbleStyle: SVKBubbleStyle
    var text: String?
    var oldText: String?
    private(set) var timestamp: String = SVKTools.iso8061DateFormatter.string(from: Date())
    var isTimestampHidden = true

    var historyID: String?
    var smarthubTraceId: String?
    var bubbleIndex: Int?
    var vote: SVKFeedback = .none
    var isTimestampDetailsHidden = true
    var isEmpty: Bool = false
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var bubbleKey: Int = -1
    var isAvatarVisible = false

    var skillId: SVKSkillIdentifier = ""

    var errorCode: String?
    var deviceName: String?
    var isDefaultDeviceNameHide = false
    
    init(bubbleStyle: SVKBubbleStyle = .default(.right),
         text: String? = nil,
         type: SVKBubbleContentType = .text,
         isDelivered: Bool = false,
         timestamp: String? = nil,
         historyEntry: SVKHistoryEntry? = nil) {
        
        self.bubbleStyle = bubbleStyle
        self.text = text
        self.deliveryState = .beingDelivered
        self.contentType = type
        if let timestamp = timestamp {
            self.timestamp = timestamp
        }

        self.origin = historyEntry != nil ? .history : .conversation
        self.historyID = historyEntry?.id
        self.vote = historyEntry?.vote ?? .none
        self.smarthubTraceId = historyEntry?.traceId
        self.errorCode = historyEntry?.response?.errorCode
        self.deviceName = historyEntry?.device?.name
    }


    var content: (Any?, String)? {
        return (text, "public.utf8-plain-text")
    }

    //MARK: Equatable
    func isEqual(_ other: SVKBubbleDescription) -> Bool {
        guard let other = other as? SVKUserBubbleDescription else { return false }
        return self == other
    }

    static func == (lhs: SVKUserBubbleDescription, rhs: SVKUserBubbleDescription) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
    
    mutating func markAsReco() {
        if contentType == .text {
            self.contentType = .recoText
        }
    }
}



struct SVKHeaderErrorBubbleDescription: SVKBubbleDescription {
    
    var content: (Any?, String)?
    
    func isEqual(_ other: SVKBubbleDescription) -> Bool {
        return false
    }

    var contentType: SVKBubbleContentType = .errorHeader
    var origin: SVKBubbleDescriptionType = .history
    var bubbleStyle: SVKBubbleStyle
    var text: String?
    var oldText: String?
    var timestamp: String = SVKTools.iso8061DateFormatter.string(from: Date())
    var isTimestampHidden = true

    var historyID: String?
    var smarthubTraceId: String?
    var bubbleIndex: Int?
    var vote: SVKFeedback = .none
    var isTimestampDetailsHidden = true
    var isEmpty: Bool = false
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var bubbleKey: Int = -1
    var isAvatarVisible = true

    var skillId: SVKSkillIdentifier = ""

    var isExpanded = false
    
    var bubbleDescriptionEntries : [SVKBubbleDescription] = []
    
    var errorCode: String?
    
    init(bubbleStyle: SVKBubbleStyle = .default(.left),
         text: String? = nil,
         timestamp: String? = nil,
         bubbleDescriptionEntries: [SVKBubbleDescription] = []) {
        self.bubbleDescriptionEntries = bubbleDescriptionEntries
        self.bubbleStyle = bubbleStyle
        self.text = text
        if let timestamp = timestamp {
            self.timestamp = timestamp
        }

        self.origin =  .history
     }

}

extension SVKInvokeResult {
    var skillURLs: [String]? {
        return skill?.data?.kit?.parameters?.urls
    }
}

fileprivate extension SVKCardType {
    var contentType: SVKBubbleContentType {
        switch self {
        case .deezerUser,
             .deezerAlbum,
             .deezerArtist,
             .deezerTrack,
             .deezerPlaylist,
             .deezerUserFavorites,
             .deezerRadio:
            return .musicCard
        case .memolistDelete, .memolistGet, .memolistAdd: return .memolistCard
        case .timer: return .timerCard
        case .iot: return .iotCard
        case .weather: return .weatherCard
        case .recipeIngredients: return .recipeCard
        case .imageCard: return .imageCard
        default: return .genericCard
        }
    }
}

extension SVKCard {
    
    var temperature: String  {
        guard let value = self.data?.temperature else { return "--°" }
        return "\(value)°C"
    }
    
    var minTemperature: String  {
        guard let value = self.data?.minTemp else { return "--°" }
        return "\(value)°"
    }

    var maxTemperature: String  {
        guard let value = self.data?.maxTemp else { return "--°" }
        return "\(value)°"
    }
    
    var boundedTemperatures: String? {
        guard let minValue = self.data?.minTemp,
            let maxValue = self.data?.maxTemp else { return nil }
        return "\(minValue)°/\(maxValue)°"
    }
}

/**
 Helper methods for Sequence of SVKBubbleDescription
 */
extension Sequence where Iterator.Element == SVKBubbleDescription {
    
    /**
     Set the property isTimestampHidden of each element of the sequence to true of false
     
     isTimestampHidden property is set to false if the timestamp of the previous element is less or equal
     to n minutes. n is the parameter delay
     - parameter delay: The delay to apply in minutes
     - parameter reversedOrder: true if elements of Sequence are in their reverseOrder (conversation speaking)
     - returns: The exact sequence of SVKBubbleDescription with each isTimestampHidden up to date
    */
    func updateIsTimestampHidden(with delay: TimeInterval, reversedOrder: Bool) -> [SVKBubbleDescription] {
     
        if reversedOrder {
            var bubbleDescriptions =  self.reduce([]) { (result, previousDescription) -> [SVKBubbleDescription] in
                
                var descriptions = result
                
                if var currentDescription = result.first,
                    let currentDate = SVKTools.date(from: currentDescription.timestamp),
                    let previousDate = SVKTools.date(from: previousDescription.timestamp)  {
                    
                    currentDescription.isTimestampHidden = currentDate.timeIntervalSince(previousDate) <= delay * 60
                    
                    if !currentDescription.isTimestampHidden {
                        descriptions[0] = currentDescription
                        descriptions.insert(previousDescription, at: 0)
                        return descriptions
                    }
                }
                descriptions.insert(previousDescription, at: 0)
                return descriptions
                
            }
            if !bubbleDescriptions.isEmpty {
                var bubbleDescrition = bubbleDescriptions.removeFirst()
                bubbleDescrition.isTimestampHidden = true
                bubbleDescriptions.insert(bubbleDescrition,at: 0)
            }

            return bubbleDescriptions
        }
        
        
        var bubbleDescriptions = self.reduce([]) { (result, previousDescription) -> [SVKBubbleDescription] in
            

            var descriptions = result
            
            if var currentDescription = result.last,
                let currentDate = SVKTools.date(from: currentDescription.timestamp),
                let previousDate = SVKTools.date(from: previousDescription.timestamp)  {
                
                currentDescription.isTimestampHidden = currentDate.timeIntervalSince(previousDate) <= delay * 60
                
                if !currentDescription.isTimestampHidden {
                    descriptions[result.count-1] = currentDescription
                    descriptions.append(previousDescription)
                    return descriptions
                }
            }
            descriptions.append(previousDescription)
            return descriptions
            
        }
        if var bubbleDescrition = bubbleDescriptions.popLast() {
            bubbleDescrition.isTimestampHidden = false
            bubbleDescriptions.append(bubbleDescrition)
        }
        
        return bubbleDescriptions
    }
    
    /**
     Set the property isAssistantLineSperatorHidden of each element of the sequence to true of false
     
     isAssistantLineSperatorHidden property is set to false the current and previous descriptions have their
     is different **SDKSkillAppearance**
     - parameter reversedOrder: true if elements of Sequence are in their reverseOrder (conversation speaking)
     - returns: The exact sequence of SVKBubbleDescription with each isAssistantLineSperatorHidden up to date
    */
    func updateIsAssistantLineSperatorHidden(reversedOrder: Bool) -> [SVKBubbleDescription] {
        
        if reversedOrder {
            return self.reduce([]) { (result, previousDescription) -> [SVKBubbleDescription] in
                
                var descriptions = result
                
                if var currentDescription = result.first as? SVKAssistantBubbleDescription,
                    result.count > 2,
                    previousDescription is SVKUserBubbleDescription,
                    let previousDjingoDescriptionDescription = result[2] as? SVKAssistantBubbleDescription {
                    
                    currentDescription.isAssistantLineSperatorHidden = previousDjingoDescriptionDescription.appearance == currentDescription.appearance
                    
                    if !currentDescription.isAssistantLineSperatorHidden {
                        descriptions[0] = currentDescription
                        descriptions.insert(previousDescription, at: 0)
                        return descriptions
                    }
                }
                descriptions.insert(previousDescription, at: 0)
                return descriptions
                
            }
        }
        
        
        return self.reduce([]) { (result, previousDescription) -> [SVKBubbleDescription] in
            
            
            var descriptions = result
            
            /// dectect begining of other assistant conversation
            if var currentDescription = result.last as? SVKAssistantBubbleDescription,
                result.count > 2,
                let previousDjingoDescriptionDescription = result[result.count - 3] as? SVKAssistantBubbleDescription {

                currentDescription.isAssistantLineSperatorHidden = previousDjingoDescriptionDescription.appearance == currentDescription.appearance

                if !currentDescription.isAssistantLineSperatorHidden {
                    descriptions[result.count-1] = currentDescription
                    descriptions.append(previousDescription)
                    return descriptions
                }
            }

            descriptions.append(previousDescription)
            return descriptions
            
        }
    }
}

/**
 An extension of Collection
 Acts like an helper SVKBubbleDescription list
 */
extension Collection where Index == Int {
 
    /**
      Creates a bubble stype for a position
     
     The style of the bullble depends on the index position in self
     - parameter position: The position from which the style will be created
     - returns: An SVKBubbleStyle
     */
    func bubbleStyle(for position: Index) -> SVKBubbleStyle {
        guard count > 1 else {
            return SVKBubbleStyle.default(.left)
        }
        if position == 0 {
            return SVKBubbleStyle.top(.left)
        } else if position == count - 1 {
            return SVKBubbleStyle.bottom(.left)
        }
        return SVKBubbleStyle.middle(.left)
    }

}

/**
 An extension of MutableCollection of SVKBubbleDescription
 */
extension MutableCollection where Iterator.Element == SVKBubbleDescription, Index == Int {
    
    /**
     Sets the collection bubbles descriptions style to SVKBubbleStyle
     accordind to their position in the collection.
    */
    mutating func setBubblesStyle(reversed:Bool = false) {
        for (position, var element) in enumerated() {
            var p = position
            if reversed {
                p = self.count - position - 1
            }
            element.bubbleStyle = self.bubbleStyle(for: p)
            self[position] = element
        }
    }
}

