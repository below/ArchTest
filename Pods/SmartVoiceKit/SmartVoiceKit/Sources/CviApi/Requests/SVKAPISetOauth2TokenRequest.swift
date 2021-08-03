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
 A structure to request an oauth2 token update
 */
public struct SVKAPISetOauth2TokenRequest: SVKAPIRequestProtocol {

    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKRawData
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET
    
    // The logger use this identity
    typealias Identity = SVKAPISetOauth2TokenRequest
    
    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/user/api/v1/token/oauth2"
    }
    
    var isAuthorizationTokenRequired: Bool {
        return true
    }
    var skillId: String
    var tokenId: String
    var refreshToken: String
    var accessToken: String
    var expiration: String // 2120-10-10T10:00:00.123Z
    
    public init(skillId: String, tokenId: String, accessToken: String, expiration: String, refreshToken: String) {
        self.skillId = skillId
        self.tokenId = tokenId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = ["skillId": "skill-smarthome", "refreshToken":  refreshToken, "accessToken": accessToken, "tokenId": tokenId, "validUntil": expiration]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        catch {
            SVKLogger.error("Unable to create body")
        }
        return request
    }

    /**
     Called after the request data response has been decoded.
     
     The function then extract the token and store it for further use
     - parameter data: The data received has in the request's response
     - parameter object: The decoded object.
     */
    public func didDecodeData<T>(_ data: Data?, to object: inout T) {
//        let session = object as! DecodingTypeGET
//        SVKAPIClient.shared.storeToken(session.token)
    }

}
