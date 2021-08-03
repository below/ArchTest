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

public struct SVKUserSkill: Decodable {
    public enum CodingKeys: String, CodingKey {
        case loginStatus, supportedLocales, name
    }

    public enum LoginStatus: String, Codable {
        case notRequired = "NOT_REQUIRED"
        case loggedIn = "LOGGED_IN"
        case notLoggedIn = "NOT_LOGGED_IN"
    }

    /** Configuration status of the skill for the user */
    //    public var loginStatus: LoginStatus?
    public let loginStatus: String?

    /** Locales supported by the skill */
    public let supportedLocales: [String]

    /** Id of the skill defined in the skill metadata */
    public let name: String
}

public struct SVKUserSkills: Decodable {
    public enum CodingKeys: String, CodingKey {
        case skills
    }

    public let skills: [SVKUserSkill]
}
