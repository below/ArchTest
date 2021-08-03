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

public struct SVKInvokeResult: Decodable {
    public enum CodingKeys: String, CodingKey {
        case cardId, intent, session, skill, stt, sttCandidates, text, status, conversationId
        case smarthubTraceId = "@smarthub.traceId"
        case quickReplies
    }

    public let cardId: String?
    public let intent: SVKInvokeIntent?
    public let session: SVKSession
    public let skill: SVKSkillResult?
    public let stt: SVKSpeechToTextResult?
    public let sttCandidates: SVKSpeechToTextResults?
    public let text: String
    public let status: String
    public let smarthubTraceId: String
    public let conversationId: String?

    public var jsonData: Data?
    public var quickReplies: SVKQuickReplies?
    
    public init(cardId: String?, intent: SVKInvokeIntent?, session: SVKSession, skill: SVKSkillResult?, stt: SVKSpeechToTextResult?,
                sttCandidates: SVKSpeechToTextResults?, text: String, status: String, smarthubTraceId: String, conversationId: String?, jsonData: Data?
    , quickReplies: SVKQuickReplies? = nil) {
        self.cardId = cardId
        self.intent = intent
        self.session = session
        self.skill = skill
        self.stt = stt
        self.sttCandidates = sttCandidates
        self.text = text
        self.status = status
        self.smarthubTraceId = smarthubTraceId
        self.conversationId = conversationId
        self.quickReplies = quickReplies
    }
}

public struct SVKInvokeIntent: Decodable {
    public enum CodingKeys: String, CodingKey {
        case intent, entities
    }

    public let entities: Dictionary<String, [String?]>?
    public let intent: String
}

public struct SVKSession: Decodable {
    public enum CodingKeys: String, CodingKey {
        case finished, id, ttl
    }

    public let finished: Bool
    public let id: String
    public let ttl: Int
}

public enum SVKSKillResultType: String, Decodable {
    case TELL, ASK, ASK_FREETEXT
}

public struct SVKSkillResult: Decodable {
    public enum CodingKeys: String, CodingKey {
        case data, id, local, resultType
    }

    public let data: SVKSkillUseKit?
    public let id: SVKSkillIdentifier
    public let local: Bool
    public let resultType: SVKSKillResultType
}

public struct SVKSpeechToTextResult: Decodable {
    public enum CodingKeys: String, CodingKey {
        case text, confidence
    }

    public let text: String
    public let confidence: Double
}

public struct SVKSpeechToTextResults: Decodable {
    public enum CodingKeys: String, CodingKey {
        case data
    }

    public let data: [SVKSpeechToTextResult]
}

public struct SVKSkillUseKit: Decodable {
    public enum CodingKeys: String, CodingKey {
        case kit = "use_kit"
    }

    public let kit: SVKSkillKit?
}

public enum SVKKitType: String {
    case unkown
    case deezer
    case audioPlayer = "audio_player"
    case system
    case timer
}

public struct SVKSkillKit: Decodable {
    public enum CodingKeys: String, CodingKey {
        case name = "kit_name"
        case action
        case parameters
    }

    public let name: String
    public let action: String
    public let parameters: SVKParameters?
}

extension SVKSkillKit {
    public var type: SVKKitType {
        return SVKKitType(rawValue: name) ?? .unkown
    }
}

public struct SVKParameters: Decodable {
    public enum CodingKeys: String, CodingKey {
        case urls, url
    }

    public let urls: [String]?
    public let url: String?
}

public enum SVKQuickRepliesAligment: String, Codable {
    case vertical = "vertical"

    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKQuickRepliesAligment.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKQuickRepliesAligment {
        guard let string = string else { return .vertical }
        switch string.uppercased() {
        case "VERTICAL": return .vertical
        default:
            SVKLogger.debug("This SVKQuickRepliesAligment value \(string) is unknown")
            return .vertical
        }
    }
    
}

public enum SVKQuickRepliesType: String, Codable {
    case quickReplies = "quickReplies"

    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKQuickRepliesType.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKQuickRepliesType {
        guard let string = string else { return .quickReplies }
        switch string.uppercased() {
        case "QUICKREPLIES": return .quickReplies
        default:
            SVKLogger.debug("This SVKQuickRepliesType value \(string) is unknown")
            return .quickReplies
        }
    }
    
}

public struct SVKQuickReplies: Codable {
    public enum CodingKeys: String, CodingKey {
        case type, itemAligment, replies
    }
    
    public let type: SVKQuickRepliesType
    public let itemAligment: SVKQuickRepliesAligment
    public let replies: [SVKQuickReply]
    
    public init(type: SVKQuickRepliesType, itemAligment: SVKQuickRepliesAligment, replies: [SVKQuickReply]) {
        self.type = type
        self.itemAligment = itemAligment
        self.replies = replies
    }
}

public enum SVKQuickReplyType: String, Codable {
    case button = "button"
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKQuickReplyType.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKQuickReplyType {
        guard let string = string else { return .button }
        switch string.uppercased() {
        case "BUTTON": return .button
        default:
            SVKLogger.debug("This SVKQuickRepliesType value \(string) is unknown")
            return .button
        }
    }
    
}

public struct SVKQuickReply: Codable {
    public let type: SVKQuickReplyType
    public let tooltip: String?
    public let title: String
    public let iconUrl: String?
    public let action: SVKQuickReplyAction
    
    public init(type: SVKQuickReplyType, tooltip: String?, title: String, iconUrl: String?, action: SVKQuickReplyAction) {
        self.type = type
        self.tooltip = tooltip
        self.title = title
        self.iconUrl = iconUrl
        self.action = action
    }
}

public enum SVKQuickActionType: String, Codable {
    case publishText = "publishText"
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKQuickActionType.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKQuickActionType {
        guard let string = string else { return .publishText }
        switch string.uppercased() {
        case "PUBLISHTEXT": return .publishText
        default:
            SVKLogger.debug("This SVKQuickActionType value \(string) is unknown")
            return .publishText
        }
    }
    
}

public struct SVKQuickReplyAction: Codable {
    public let type: SVKQuickActionType
    public let value: String
    
    public init(type: SVKQuickActionType, value: String) {
        self.type = type
        self.value = value
    }
}
