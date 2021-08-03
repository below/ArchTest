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

public struct SVKTNCText: Decodable {
    public let displayName: String
    public let purpose: String
    public let text: String
}

public struct SVKAgreementTNCText: Decodable {
    public let defaultAgreement: Bool
    public let lastChanged: String? 
    public let tncId: String
    public let tncTexts: [SVKTNCText]
    public let userAgreement: Bool?
}

public struct SVKUserAgreements: Decodable {
    public enum CodingKeys: String, CodingKey {
        case elements = "agreementsWithTncTextDtos"
        case locale
    }
    
    public let elements: [SVKAgreementTNCText]
    public let locale: String
}

public typealias SVKTNCAgreement = (agreed: Bool, tncId: String)

public enum SVKTNCId: String {
    case voiceProcessing = "VOICEPROCESSING"
    case languageTechnology = "language_technology"
    case listenVoice = "listenVoice"
    case usageStatistics = "usage_statistics"
}
