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

public struct SVKSttConnectWsMessage: Codable {
    public enum CodingKeys: String, CodingKey {
        case type, clientMetadata, deviceCapabilities, wakeUpWord, enableBoS, sessionId, includeIntent, includeSkill, enablePartialTranscription
    }

    public let type: String
    public let clientMetadata: SVKSttClientMetaData?
    public let deviceCapabilities: SVKSttDeviceCapabilities?
    public let wakeUpWord: String?
    public let enableBoS: Bool
    public let sessionId: String?
    public let includeIntent: Bool
    public let includeSkill: Bool
    public let enablePartialTranscription: Bool
}

public struct SVKSttDeviceCapabilities: Codable {
    public enum CodingKeys: String, CodingKey {
        case ssml, ncs
    }

    public let ssml: Bool
    public let ncs: Bool
}

public struct SVKSttClientMetaData: Codable {
    public enum CodingKeys: String, CodingKey {
        case serialNumber, deviceName, data
    }

    public let serialNumber: String
    public let deviceName: String?
    public let data: [String:String]?
}

public struct SVKSttAudioBeginWsMessage: Codable {
    public enum CodingKeys: String, CodingKey {
        case type, codec
    }

    public let type: String
    public let codec: String
}

public struct SVKSttAudioEndWsMessage: Codable {
    public let type: String
}
