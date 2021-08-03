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

public struct SVKToken: Decodable {
    public enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, skillId, tokenId, validUntil
    }

    /** OAuth2 access token */
    public let accessToken: String
    /** OAuth2 refresh token */
    public let refreshToken: String?
    /** Id of skill which is eligible to use the token */
    public let skillId: String
    /** Business id of token */
    public let tokenId: String
    /** Valid until timestamp in ISO-8601 format: Extended format with date, time, and offset */
    public let validUntil: String?
}

public struct SVKTokens: Decodable {
    public enum CodingKeys: String, CodingKey {
        case tokens
    }

    /** List of tokens */
    public let tokens: [SVKToken]
}
