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

public enum SVKCardType: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var value = ""
        switch self {
        case .memolistAdd: value = "shopping_list_add"
        case .memolistGet: value = "shopping_list_get"
        case .memolistDelete: value = "shopping_list_delete"
        case .link: value = "link"
        case .deezerUser: value = "deezer-user"
        case .deezerAlbum: value = "deezer-album"
        case .deezerArtist: value = "deezer-artist"
        case .deezerTrack: value = "deezer-track"
        case .deezerPlaylist: value = "deezer-playlist"
        case .deezerUserFavorites: value = "deezer-userfavorites"
        case .deezerRadio: value = "deezer-radio"
        case .timer: value = "timer_set"
        case .iot: value = "lights"
        case .weather: value = "weather"
        case .recipeIngredients: value = "recipe_ingredients"
        case .imageCard: value = "image_card"
        case .genericDefault: value = "generic_default"
        default:
            value = "GENERIC"
        }
      
        try container.encode(value)
    }
    
    case memolistAdd
    case memolistGet
    case memolistDelete
    case link
    case deezerUser
    case deezerAlbum
    case deezerArtist
    case deezerTrack
    case deezerPlaylist
    case deezerUserFavorites
    case deezerRadio
    case timer
    case iot
    case generic
    case genericDefault
    case weather
    case recipeIngredients
    case imageCard
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKCardType.case(with: string)
    }
    
    public static func `case`(with string: String) -> SVKCardType {
        switch string.lowercased() {
        case "shopping_list_add": return .memolistAdd
        case "shopping_list_get": return .memolistGet
        case "shopping_list_delete": return .memolistDelete
        case "link": return .link
            
        case "deezer-user": return .deezerUser
        case "deezer-album": return .deezerAlbum
        case "deezer-artist": return .deezerArtist
        case "deezer-track": return .deezerTrack
        case "deezer-playlist": return .deezerPlaylist
        case "deezer-userfavorites": return .deezerUserFavorites
        case "deezer-radio": return .deezerRadio
            
        case "timer_set": return .timer
        case "timer_get": return .timer
        case "timer_delete": return .timer
            
        case "lights": return .iot
        case "weather": return .weather
            
        case "recipe_ingredients": return .recipeIngredients
        case "image_card": return .imageCard
        case "generic_default": return .genericDefault
        default: return .generic
        }
    }
}

public struct SVKCard: Codable {
    public enum CodingKeys: String, CodingKey {
        case id, type, version, created, device
        case data
    }
    
    public let id: String
    public let type: SVKCardType
    public let version: Int
    public let created: String
    public let device: SVKDevice?
    public var data: SVKCardData?
    
    public var jsonData: Data?
    
    public init(id: String, type: SVKCardType, version: Int, created: String, device: SVKDevice?, data: SVKCardData?, jsonData: Data?) {
        self.id = id
        self.type = type
        self.version = version
        self.created = created
        self.device = device
        self.data = data
        self.jsonData = jsonData
    }
}

public struct SVKDevice: Codable {
    public enum CodingKeys: String, CodingKey {
        case clientId, deviceName
    }
    
    public let clientId: String?
    public let deviceName: String?
}

public struct SVKCardData: Codable {
    public enum CodingKeys: String, CodingKey {
        case typeDescription, items, text, subText, moreText, fullText
        case iconUrl, duration, timeLeft
        case serviceLink, contentId, iconPartner, titleText
        case type
        case temperature, weatherType, location, weatherImage, weatherIcon, day, minTemp, maxTemp
        case layout, subTitle, requesterSource, action, actionText
        case mediaUrl, logoUrl
        // Card V3
        case imageUrl
        case prominentText, actionProminentText
        case listSections
    }
    
    public enum SVKCardLayout: String, Codable {
        case generic
        case genericFullText
        case genericList
        case partner
        case image
        case imageList
        case imageFullText
        case mediaPlayer
        case playStream
        case playAudioFile
    }
    
    // generic
    public let text: String?
    public let subText: String?
    public let fullText: String?
    public var iconUrl: String?
    public let layout: SVKCardLayout?
    public var titleText: String?
    public let subTitle: String?
    public var typeDescription: String?
    public let requesterSource: String?
    public let action: String?
    public let actionText: String?
    
    // MediaPlayer
    public let mediaUrl: String?
    
    // memolist
    public let items: [String]?
    
    // partner
    public let logoUrl: String?
    
    // Deezer
    public let contentId: String?
    public let iconPartner: String?
    
    /**************************/
    // remove  all properties after this comment
    // once the backend will be up to date
    /**************************/
    public let moreText: String?
    // timer, current time
    public let duration: Int?
    public let durationString: String?
    
    public let timeLeft: [Float]?
    
    // Deezer
    public let serviceLink: String?
    public let type: String?
    
    // weather
    public let weatherType: String?
    public let location: String?
    public let weatherImage: String?
    public let weatherIcon: String?
    public let day: String?
    public let temperature: Int?
    public let minTemp: Int?
    public let maxTemp: Int?
    
    // Card V3
    // Image block
    public let imageUrl: String?
    // Highlight
    public var prominentText: String?
    public var actionProminentText: String?
    // List / Action
    public var listSections: [SVKListSection]?
    
    public func isEmpty() -> Bool {
        return self.action == nil && self.actionText == nil && self.contentId == nil &&
            self.day == nil && self.duration == nil && self.durationString == nil &&
            self.fullText == nil && self.iconPartner == nil && self.iconUrl == nil &&
            self.items == nil && self.layout == nil && self.location == nil &&
            self.logoUrl == nil && self.maxTemp == nil && self.mediaUrl == nil &&
            self.minTemp == nil && self.moreText == nil && self.requesterSource == nil &&
            self.serviceLink == nil && self.subText == nil && self.subTitle == nil && self.temperature == nil &&
            self.text == nil && self.timeLeft == nil && self.titleText == nil && self.type == nil &&
            self.typeDescription == nil && self.weatherIcon == nil && self.weatherImage == nil && self.weatherType == nil && self.imageUrl == nil
    }
    public init(from decoder: Decoder) throws {
        // decode the current stucture
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // generic
        self.typeDescription = try? container.decode(String.self, forKey: CodingKeys.typeDescription)
        self.text = try? container.decode(String.self, forKey: CodingKeys.text)
        self.subText = try? container.decode(String.self, forKey: CodingKeys.subText)
        self.iconUrl = try? container.decode(String.self, forKey: CodingKeys.iconUrl)
        self.fullText = try? container.decode(String.self, forKey: CodingKeys.fullText)
        self.layout = try? container.decode(SVKCardLayout.self, forKey: CodingKeys.layout)
        self.titleText = try? container.decode(String.self, forKey: CodingKeys.titleText)
        self.subTitle = try? container.decode(String.self, forKey: CodingKeys.subTitle)
        self.requesterSource = try? container.decode(String.self, forKey: CodingKeys.requesterSource)
        self.action = try? container.decode(String.self, forKey: CodingKeys.action)
        self.actionText = try? container.decode(String.self, forKey: CodingKeys.actionText)
        
        self.moreText = try? container.decode(String.self, forKey: CodingKeys.moreText)
        
        // memolist
        self.items = try? container.decode([String].self, forKey: CodingKeys.items)
        
        // timer, current time
        self.timeLeft = try? container.decode([Float].self, forKey: CodingKeys.timeLeft)
        do {
            self.duration = try container.decode(Int.self, forKey: CodingKeys.duration)
            self.durationString = nil
        } catch {
            let duration: String? = try? container.decode(String.self, forKey: CodingKeys.duration)
            if let duration = duration {
                self.duration = Int(duration)
                self.durationString = duration
            } else {
                self.duration = nil
                self.durationString = nil
            }
        }
        
        if typeDescription == " " {
            self.typeDescription = nil
        }
        
        // Deezer
        self.serviceLink = try? container.decode(String.self, forKey: CodingKeys.serviceLink)
        self.contentId = try? container.decode(String.self, forKey: CodingKeys.contentId)
        self.iconPartner = try? container.decode(String.self, forKey: CodingKeys.iconPartner)
        self.type = try? container.decode(String.self, forKey: CodingKeys.type)
        self.logoUrl = try? container.decode(String.self, forKey: CodingKeys.logoUrl)
        
        // weather
        do {
            self.temperature = try container.decode(Int.self, forKey: CodingKeys.temperature)
        } catch {
            let temperature: String? = try? container.decode(String.self, forKey: CodingKeys.temperature)
            if let temperature = temperature {
                self.temperature = Int(temperature)
            } else {
                self.temperature = nil
            }
        }
        self.maxTemp = try container.decodeIfPresent(Int.self, forKey: CodingKeys.maxTemp)
        self.minTemp = try container.decodeIfPresent(Int.self, forKey: CodingKeys.minTemp)
        
        self.weatherType = try? container.decode(String.self, forKey: CodingKeys.weatherType)
        self.location = try? container.decode(String.self, forKey: CodingKeys.location)
        self.weatherImage = try? container.decode(String.self, forKey: CodingKeys.weatherImage)
        self.weatherIcon = try? container.decode(String.self, forKey: CodingKeys.weatherIcon)
        self.day = try? container.decode(String.self, forKey: CodingKeys.day)
        
        self.mediaUrl = try? container.decode(String.self, forKey: CodingKeys.mediaUrl)
        // Image block
        self.imageUrl = try? container.decode(String.self, forKey: CodingKeys.imageUrl)
        // Highlight
        self.prominentText = try? container.decode(String.self, forKey: CodingKeys.prominentText)
        self.actionProminentText = try? container.decode(String.self, forKey: CodingKeys.actionProminentText)
        // List / Action
        self.listSections = try? container.decode([SVKListSection].self, forKey: CodingKeys.listSections)
    }
    
    public init(text: String?, subText: String?, titleText: String?, subTitle: String?, iconUrl: String?) {
        self.text = text
        self.subText = subText
        self.fullText = nil
        self.iconUrl = iconUrl
        self.layout = nil
        self.titleText = titleText
        self.subTitle = subTitle
        self.typeDescription = nil
        self.requesterSource = nil
        self.action = nil
        self.actionText = nil
        self.mediaUrl = nil
        self.items = nil
        self.logoUrl = nil
        self.contentId = nil
        self.iconPartner = nil
        self.moreText = nil
        self.duration = nil
        self.durationString = nil
        self.timeLeft = nil
        self.serviceLink = nil
        self.type = nil
        self.weatherType = nil
        self.location = nil
        self.weatherIcon = nil
        self.weatherImage = nil
        self.day = nil
        self.temperature = nil
        self.minTemp = nil
        self.maxTemp = nil
        self.imageUrl = nil
        self.prominentText = nil
        self.actionProminentText = nil
        self.listSections = nil
    }
    
}

public enum SVKCardDataTypeDescription: String, Decodable {
    case currentTime
    case timerSet
    case timerGet
    case timerDelete
    case unknown
    case lights
    case date
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = SVKCardDataTypeDescription.case(with: string)
    }
    
    public static func `case`(with string: String?) -> SVKCardDataTypeDescription {
        guard let string = string else { return .unknown }
        switch string.lowercased() {
        case "current_time_card_type_description": return .currentTime
        case "date_card_type_description": return .date
        case "weekday_card_type_description": return .date
        case "timer_set", "démarrer": return .timerSet
        case "timer_get": return .timerGet
        case "timer_delete", "completed", "arrêter": return .timerDelete
        case "lights": return .lights
        default: return .unknown
        }
    }
}

public struct SVKListSection: Codable {
    public enum CodingKeys: String, CodingKey {
        case title, items
    }
    
    public let title: String?
    public var items: [SVKListSectionItem]
}

public struct SVKListSectionItem: Codable {
    public enum CodingKeys: String, CodingKey {
        case itemText, itemIconUrl, itemAction, title, iconUrl
    }
    
    public var itemText: String?
    public var itemIconUrl: String?
    public let itemAction: String?
    public let title: String?
    public let iconUrl: String?
}
