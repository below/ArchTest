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
 A structure to request login
 */
public struct SVKAPILoginRequest: SVKAPIRequestProtocol {
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKLoginResult
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPILoginRequest
    
    /// The userId use to log in (mutually exclusive with `externalToken`)
    var userId: String?
    /// The externalToken to log in (mutually exclusive with `userId`)
    var externalToken: String?
    
    var absoluteQueryString: String {
        return SVKAPIClient.loginURL + "/user/api/v1/login"
    }
    
    var isAuthorizationTokenRequired: Bool {
        return false
    }

    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var bodyDict = [String:String]()
        if self.externalToken != nil {
            bodyDict["externalToken"] = self.externalToken
        } else if self.userId != nil {
            bodyDict["userId"] = self.userId
        }
        do {
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict, options: [])
        } catch {
            assert(false, "Unable to create json payload for SVkAPILoginRequest")
        }
        return request
    }

    
    public init(userId: String) {
        self.userId = userId
    }
    
    public init(externalToken: String) {
        self.externalToken = externalToken
    }

    /**
     Called after the request data response has been decoded.
     
     The function then extract the token and store it for further use
     - parameter data: The data received has in the request's response
     - parameter object: The decoded object.
    */
    public func didDecodeData<T>(_ data: Data?, to object: inout T) {
        let session = object as! DecodingTypeGET
        SVKAPIClient.shared.storeToken(session.token)
    }
    
    public func perform(completionHandler: @escaping (SVKAPIRequestResult) -> Void) {
        performDefault(completionHandler: completionHandler, verbose: false)
    }
}
