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

/*
 A structure to request a djingo intent
 */
public struct SVKAPIInvokeTextRequest: SVKAPIRequestProtocol {
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKInvokeResult
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPIInvokeTextRequest
    
    /// The invocation text
    var text: String
    
    /// The sessionId for ping pong conversations
    var sessionId: String?
    
    var absoluteQueryString: String {
        var string = SVKAPIClient.baseURL + "/cvi/dm/api/v1/invoke/text/json"
        if let sessionId = sessionId {
            string.append("?sessionId=\(sessionId)")
        }
        return string
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = """
            { "text": "\(text)" }
            """.data(using: String.Encoding.utf8)
        return request
    }
    
    public init(text: String, sessionId: String? = nil) {
        self.text = text
        self.sessionId = sessionId
    }
    
    /**
     Called after the request data response has been decoded.
     
     The function then extract the token and store it for further use
     - parameter data: The data received has in the request's response
     - parameter object: The decoded object.
     */
    public func didDecodeData<T>(_ data: Data?, to object: inout T) {
        if let data = data {
            var result = object as! DecodingTypeGET
            result.jsonData = data
            object = result as! T
        }
    }
    
}
