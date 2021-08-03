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
 The service error
 */
public struct SVKAPIRequestError: Decodable {

    public struct ErrorCodingKey: CodingKey {
        public var stringValue: String = "error"

        public init?(stringValue: String) {
            self.stringValue = stringValue
        }

        public var intValue: Int?
        public init?(intValue _: Int) {
            self.stringValue = "error"
        }

        public init() {}
    }

    public enum CodingKeys: String, CodingKey {
        case code
        case message
    }

    public let code: String
    public let message: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SVKAPIRequestError.CodingKeys.self)
        do {
            let container = try decoder.container(keyedBy: SVKAPIRequestError.ErrorCodingKey.self)
            self = try container.decode(SVKAPIRequestError.self, forKey: SVKAPIRequestError.ErrorCodingKey())
        } catch {
            self.code = try container.decode(String.self, forKey: SVKAPIRequestError.CodingKeys.code)
            self.message = try container.decode(String.self, forKey: SVKAPIRequestError.CodingKeys.message)
        }
    }
}

public struct SVKRawData: Decodable {
    public let data: Data
}
