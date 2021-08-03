//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2021 Orange
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
 A structure to request Exchange authorization code for platform token
 */
public struct SVKAPICviExchangeOauth2TokenRequest: SVKAPIRequestProtocol {
    
    public enum Method {
        case post(authCode: String, clientSecret: String)
        
        var httpMethod: String {
            switch self {
            case .post: return "POST"
            }
        }
    }
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = String
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = SVKCviPlatformToken
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPICviExchangeOauth2TokenRequest
    
    var method: SVKAPICviExchangeOauth2TokenRequest.Method
    
    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/user/api/v2/exchange-auth-code"
    }
    
    var isAuthorizationTokenRequired: Bool {
        return false
    }

    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        switch method {
            case .post(let authCode, let clientSecret):
                do {
                    var parameters = [String:String]()
                    parameters["authCode"] = authCode
                    parameters["clientId"] = SVKAPIClient.clientOIDC?.clientId ?? ""
                    parameters["clientSecret"] = clientSecret
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                } catch {
                    assert(false, "Unable to create json payload for SVKAPIExchangeOauth2TokenRequest")
                }
        }
        return request
    }

    
    public init(method: Method) {
        self.method = method
    }
    
    public func perform(completionHandler: @escaping (SVKAPIRequestResult) -> Void) {
        performDefault(completionHandler: completionHandler, verbose: false)
    }
}

