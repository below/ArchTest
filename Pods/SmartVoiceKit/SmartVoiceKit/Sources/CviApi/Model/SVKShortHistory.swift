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

public struct SVKHistoryEntries: Decodable {
    public enum CodingKeys: String, CodingKey {
        case entries, newest, oldest
    }

    public var entries: [SVKHistoryEntry]
    public let newest: SVKShortHistory?
    public let oldest: SVKShortHistory?
    
    public init(entries: [SVKHistoryEntry], newest: SVKShortHistory?, oldest: SVKShortHistory?) {
        self.entries = entries
        self.newest = newest
        self.oldest = oldest
    }
    
    mutating func checkTimestampOfAllEntry() {
        var histroyEntries: [SVKHistoryEntry] = []
        for var item in entries {
            if item.timestampNotFormated == nil {
                item.timestampNotFormated = item.request?.timestamp != nil ? item.request?.timestamp : item.response?.timestamp
            }
            histroyEntries.append(item)
        }
        entries = histroyEntries
    }
}

public struct SVKShortHistory: Decodable {
    public enum CodingKeys: String, CodingKey {
        case id, requestTimestamp, responseTimestamp
    }

    public let id: String
    public let requestTimestamp: String?
    public let responseTimestamp: String?
}
/*
 [UNINTENDED_ACTIVATION, SPEECH_MISUNDERSTOOD_WRONG_SKILL_INVOKED, SPEECH_UNDERSTOOD_WRONG_SKILL_INVOKED, NONE, WRONG_SKILL_INVOKED, SPEECH_MISUNDERSTOOD_RIGHT_SKILL_INVOKED, SPEECH_MISUNDERSTOOD, SPEECH_VOCALISED_WRONGLY]
 
 WRONG_SKILL_INVOKED
 */
/**
 A representation of feedback sent to the backend
 */
public enum SVKFeedback: String, Codable {
    case none = "NONE"
//    case goodResponse = "TBC" // Use in the futur
    case speechUnderstoodWrongSkillInvoked = "SPEECH_UNDERSTOOD_WRONG_SKILL_INVOKED"
    case speechMisunderstoodRightSkillInvoked = "SPEECH_MISUNDERSTOOD_RIGHT_SKILL_INVOKED"
    case speechMisunderstood = "SPEECH_MISUNDERSTOOD"
    case unintededActivation = "UNINTENDED_ACTIVATION"
    case speechVocalisedWrongly = "SPEECH_VOCALISED_WRONGLY"
    case speechMisunderstoofWrongSkillInvoked =  "SPEECH_MISUNDERSTOOD_WRONG_SKILL_INVOKED"
    case wrongSkillInvoked = "WRONG_SKILL_INVOKED"
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKFeedback.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKFeedback {
        guard let string = string else { return .none }
        switch string.uppercased() {
//        case "TBC": return .goodResponse // use in the futur
        case "SPEECH_UNDERSTOOD_WRONG_SKILL_INVOKED": return .speechUnderstoodWrongSkillInvoked
        case "SPEECH_MISUNDERSTOOD_RIGHT_SKILL_INVOKED": return .speechMisunderstoodRightSkillInvoked
        case "SPEECH_MISUNDERSTOOD": return .speechMisunderstood
        case "UNINTENDED_ACTIVATION": return .unintededActivation
        case "SPEECH_VOCALISED_WRONGLY": return .speechVocalisedWrongly
        case "SPEECH_MISUNDERSTOOD_WRONG_SKILL_INVOKED": return .speechMisunderstoofWrongSkillInvoked
        case "WRONG_SKILL_INVOKED": return .wrongSkillInvoked
        case "NONE" : return .none
        default:
            SVKLogger.debug("This feedback value \(string) is unknown")
            return .none
        }
    }
}

public struct SVKHistoryEntryShort: Decodable {
    public let id: String
    public let vote: SVKFeedback
}

public struct SVKHistoryEntry: Codable {
    public enum CodingKeys: String, CodingKey {
        case id, request, response, sessionId, vote, traceId
        case timestampNotFormated = "timestamp"
        case device
    }

    public let id: String
    public let request: SVKHistoryRequest?
    public let response: SVKHistoryResponse?
    public let sessionId: String
    public let vote: SVKFeedback
    public let traceId: String?
    public var timestampNotFormated: String?
    public let device: SVKHistoryDevice?
    
    public init(id: String, request: SVKHistoryRequest?, response: SVKHistoryResponse?, sessionId: String, vote: SVKFeedback, traceId: String?, timestampNotFormated: String?, device: SVKHistoryDevice?) {
        self.id = id
        self.request = request
        self.response = response
        self.sessionId = sessionId
        self.vote = vote
        self.traceId = traceId
        self.timestampNotFormated = timestampNotFormated
        self.device = device
    }
}

public struct SVKHistoryDevice: Codable {
    public let name: String?
    public let serialNumber: String?
    
    public init(name: String?, serialNumber: String?) {
        self.name = name
        self.serialNumber = serialNumber
    }
}

public struct SVKHistoryRequest: Codable {
    public enum CodingKeys: String, CodingKey {
        case text, voteText, skillId, timestamp
    }

    public let text: String?
    public let voteText: String?
    public let skillId: SVKSkillIdentifier?
    public let timestamp: String?
}

public struct SVKHistoryResponse: Codable {
    public enum CodingKeys: String, CodingKey {
        case card, text, errorCode, timestamp
    }

    public let card: SVKCard?
    public let text: String?
    public let errorCode: String?
    public let timestamp: String?
    
    public init(card: SVKCard?, text: String? ,errorCode: String? = nil, timestamp: String? = nil) {
        self.card = card
        self.text = text
        self.errorCode = errorCode
        self.timestamp = timestamp
    }

}
