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

public enum SVKTextSpeechConverter: CustomStringConvertible {
    case stt
    case tts(String) // The string to convert
    
    public var description: String {
        switch self {
        case .tts(_): return "tts"
        case .stt: return "stt"
        }
    }
}

public struct SVKAPIVoiceRequest: SVKAPIRequestProtocol {

    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKRawData
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET
    
    // The logger use this identity
    typealias Identity = SVKAPIVoiceRequest
    
    /// The convert to use
    var converter: SVKTextSpeechConverter = .stt
    
    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/cvi/voice/api/v1/\(converter)"
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        switch converter {
        case .tts(let text):
            let escapedtext = text.escapedJSONString.replacingOccurrences(of: "=′", with: "=\\\"")
                                                   .replacingOccurrences(of: "′\\", with: "\\\"\\")
                                                   .replacingOccurrences(of: "′>", with: "\\\">")
            
            request.httpBody = """
                { "text": "\(escapedtext)" }
                """.data(using: .utf8)
            // Note. The audio format can be added like this
            // request.addValue("audio/l16;rate=16000", forHTTPHeaderField: "Accept")
            
        default:
            break
        }

        return request
    }

    public init(converter: SVKTextSpeechConverter) {
        self.converter = converter
    }

}
