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

public typealias SVKSkillIdentifier = String
public typealias SVKSkillSkins = [SVKSkillIdentifier: SVKSkillCatalog]

public struct SVKSkillsCatalog: Decodable {
    public enum CodingKeys: String, CodingKey {
        case skillCatalog
    }

    public let skillCatalog: [SVKSkillCatalog]
}

public struct SVKSkillCatalog: Decodable {
    public enum CodingKeys: String, CodingKey {
        case skillId, content, tenantContent
    }

    public let skillId: SVKSkillIdentifier
    public var content: SVKSkillContent?
    internal let contentDt: SVKSkillContentDt?
    internal let tenantContent: SVKSkillContent?

    // In the json, we may have content, tenantContent or both.
    // That's why they are optionals and there is a function to get the right one.
    // But (for now?) when there is no tenantContent, we get {} in the json instead of null or just nothing.
    // So the Content struct has to have all its keys as optionals (some of them implicitely unwrapped)
    // and we check a specific one (displayName) to see if we got a real tenantContent or just an empty one
    public var finalContent: SVKSkillContent? {
        if let tenantContent = tenantContent, tenantContent.displayName != "" {
            return tenantContent
        } else {
            return content
        }
    }

    public init(from decoder: Decoder) throws {

        // decode the current stucture
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.skillId = try container.decode(SVKSkillIdentifier.self, forKey: CodingKeys.skillId)
        self.content = try? container.decode(SVKSkillContent.self, forKey: CodingKeys.content)
        self.contentDt = try? container.decode(SVKSkillContentDt.self, forKey: CodingKeys.content)
        self.tenantContent = try? container.decode(SVKSkillContent.self, forKey: CodingKeys.tenantContent)
        
        if self.content == nil {
            self.content = self.contentDt?.getSkillContentData()
        }
    }
}

public struct SVKSkillContent: Decodable {
    public enum CodingKeys: String, CodingKey {
        case displayName, headline, iconUrl, design
        case showsInCatalog, showsInExamplePhrasesList
        case examplePhrases, description
        case conversationHistory
    }

    public let displayName: String
    public let headline: String
    public let iconUrl: String?
    public let design: SVKSkillDesign?
    public let showsInCatalog: Bool
    public let showsInExamplePhrasesList: Bool
    public let examplePhrases: [String]
    public let description: String?
    public let conversationHistory: SVKConversationHistory?
}

public struct SVKSkillDesign: Decodable {
    public enum CodingKeys: String, CodingKey {
        case backgroundColor, gradientBackgroundColor, backgroundImageUrl
    }

    public let backgroundColor: String?
    public let gradientBackgroundColor: String?
    public let backgroundImageUrl: String?
}

public struct SVKConversationHistory: Decodable {
    public enum CodingKeys: String, CodingKey {
        case backgroundColor, textColor, iconUrl, partnerName
    }

    public let backgroundColor: String
    public let textColor: String
    public let iconUrl: String
    public let partnerName: String
}

public struct SVKSkillContentDt: Decodable {
    public enum CodingKeys: String, CodingKey {
        case fileVersion
        case v2
    }

    public let fileVersion: Int
    public let v2: SVKSkillV2Content
    
    func getSkillContentData() -> SVKSkillContent {
        return SVKSkillContent(displayName: v2.displayName ?? "", headline: v2.headline ?? "", iconUrl: v2.iconUrl ?? "", design: v2.design, showsInCatalog: v2.showsInCatalog ?? false, showsInExamplePhrasesList: v2.showsInExamplePhrasesList ?? false, examplePhrases: v2.examplePhrases ?? [], description: v2.description, conversationHistory: v2.conversationHistory)
    }
}

public struct SVKSkillV2Content: Decodable {
    public enum CodingKeys: String, CodingKey {
        case cappBehavior, displayName, headline, iconUrl
        case iconOnWhiteUrl, description, setupButton, wakeWord, pairingPhrase
        case showsInCatalog, showsInExamplePhrasesList, examplePhrases
        case design
        case examplePhrasesV2
        case conversationHistory
        case appExternal
        case menuActions
        case adCard
        case adCardLaterUse
        case walkthrough
        case pairing
        case migrationConfig
    }

    public let cappBehavior: String?
    public let displayName: String?
    public let headline: String?
    public let iconUrl: String?
    public let iconOnWhiteUrl: String?
    public let design: SVKSkillDesign?
    public let showsInCatalog: Bool?
    public let showsInExamplePhrasesList: Bool?
    public let examplePhrases: [String]?
    public let examplePhrasesV2: SVKSkillExamplePhraseV2?
    public let description: String?
    public let conversationHistory: SVKConversationHistory?
    public let setupButton: String?
    public let wakeWord: String?
    public let pairingPhrase: String?
    public let appExternal: SVKSkillAppExternal?
    public let menuActions: SVKSkillMenuAction?
    public let adCard: SVKSkillAdCard?
    public let adCardLaterUse: SVKSkillAdCardLaterUse?
    public let walkthrough: SVKSkillWalkthrough?
    public let pairing: SVKSkillPairing?
    public let migrationConfig: SVKSkillMigrationConfig?
}

public struct SVKSkillExamplePhraseV2: Decodable {
    public enum CodingKeys: String, CodingKey {
        case mainPhrase
        case categories
    }

    public let mainPhrase: String?
    public let categories: [SVKSkillV2Category]?
}

public struct SVKSkillV2Category: Decodable {
    public enum CodingKeys: String, CodingKey {
        case category
        case items
    }

    public let category: String?
    public let items: [SVKSkillItem]?
}

public struct SVKSkillItem: Decodable {
    public enum CodingKeys: String, CodingKey {
        case text, iconUrl, type, direction
    }

    public let text: String?
    public let iconUrl: String?
    public let type: String?
    public let direction: String?
}

public struct SVKSkillAppExternal: Decodable {
    public enum CodingKeys: String, CodingKey {
        case buttonName, iOSUrl, iOSInstallUrl, androidPackageName
    }

    public let buttonName: String?
    public let iOSUrl: String?
    public let iOSInstallUrl: String?
    public let androidPackageName: String?
}

public struct SVKSkillMenuAction: Decodable {
    public enum CodingKeys: String, CodingKey {
        case helpAndService, legal, termsAndConditions, impressum, privacy, faq, helpDocumentTouchGestures
    }

    public let helpAndService: SVKSkillMenuActionOptions?
    public let legal: SVKSkillMenuActionOptions?
    public let termsAndConditions: SVKSkillMenuActionOptions?
    public let impressum: SVKSkillMenuActionOptions?
    public let privacy: SVKSkillMenuActionOptions?
    public let faq: SVKSkillMenuActionOptions?
    public let helpDocumentTouchGestures: SVKSkillMenuActionOptions?
}

public struct SVKSkillMenuActionOptions: Decodable {
    public enum CodingKeys: String, CodingKey {
        case name, url, type
    }

    public let name: String?
    public let url: String?
    public let type: String?
}

public struct SVKSkillAdCard: Decodable {
    public enum CodingKeys: String, CodingKey {
        case imageUrl, title, subtitle, url
        case appExternal
    }

    public let imageUrl: String?
    public let title: String?
    public let subtitle: String?
    public let url: String?
    public let appExternal: SVKSkillAppExternal?
}

public struct SVKSkillAdCardLaterUse: Decodable {
    public enum CodingKeys: String, CodingKey {
        case imageUrl, title, subtitle, buttonText
        case document
    }

    public let imageUrl: String?
    public let title: String?
    public let subtitle: String?
    public let buttonText: String?
    public let document: SVKSkillMenuActionOptions?
}

public struct SVKSkillWalkthrough: Decodable {
    public enum CodingKeys: String, CodingKey {
        case title, subtitle
        case order
      //  case examplePhrases, examplePhrasesV2
    }

    public let title: String?
    public let subtitle: String?
    public let order: Int?
 //   public let examplePhrases: [String]?
 //   public let examplePhrasesV2: [String]?
}

public struct SVKSkillPairing: Decodable {
    public enum CodingKeys: String, CodingKey {
        case authStrategy
        case config
    }

    public let authStrategy: String?
    public let config: SVKSkillPairingConfig?
}

public struct SVKSkillPairingConfig: Decodable {
    public enum CodingKeys: String, CodingKey {
        case scope, cviTokenName, clientId, clientSecret, redirectUri, discoveryUrl, oAuthUrl, authorizationUrl, targetScope
        case offlineAccess, useSingleSignOn
        case userFeatureFlags
    }

    public let scope: String?
    public let cviTokenName: String?
    public let clientId: String?
    public let clientSecret: String?
    public let redirectUri: String?
    public let discoveryUrl: String?
    public let oAuthUrl: String?
    public let authorizationUrl: String?
    public let targetScope: String?
    public let offlineAccess: Bool?
    public let userFeatureFlags: [String]?
    public let useSingleSignOn: Bool?
}

public struct SVKSkillMigrationConfig: Decodable {
    public enum CodingKeys: String, CodingKey {
        case vpp, skillId
    }

    public let vpp: String?
    public let skillId: String?
}
