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
 A structure to request user history
 */
public struct SVKAPIClientOIDCRequest: SVKAPIRequestProtocol {
    
    public enum Method {
        case getAuthenticationToken(String)
        case postAuthorisationToken(String)
        
        var httpMethod: String {
            switch self {
            case .getAuthenticationToken(_): return "GET"
            case .postAuthorisationToken(_): return "POST"
            }
        }
    }
    
    private let getURLParams = [
        "response_type": "code",
        "redirect_uri": "djingoapp://",
        "state": "empty",
        "prompt": "none",
        "client_id": SVKAPIClient.clientOIDC?.clientId ?? "",
        "scope": SVKAPIClient.clientOIDC?.scope ?? "",
    ]
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = String
    typealias DecodingTypePUT = String
    typealias DecodingTypePOST = SVKAccessToken
    typealias DecodingTypeDELETE = String
    
    // The logger use this identity
    typealias Identity = SVKAPIClientOIDCRequest
    
    /// The method
    var method: SVKAPIClientOIDCRequest.Method
    
    var absoluteQueryString: String {
        var query = ""
        switch method {
        case .getAuthenticationToken(_):
            query = "\(SVKAPIClient.clientOIDC?.baseUrl ?? "")/oidc/authorize".appendingQueryParameters(getURLParams)
        case .postAuthorisationToken(_):
            query = "\(SVKAPIClient.clientOIDC?.baseUrl ?? "")/oidc/token"
        }
        return query
    }
    
    func addHeaders(to request: URLRequest) throws -> URLRequest {
        var requestCopy = request
        requestCopy.httpMethod = method.httpMethod
        switch method {
        case .getAuthenticationToken(let coose):
            let value = "wassup="+coose
            requestCopy.addValue(value, forHTTPHeaderField: "Cookie")
            requestCopy.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        case .postAuthorisationToken(_):
            if let clientId = SVKAPIClient.clientOIDC?.clientId,
                let password = SVKAPIClient.clientOIDC?.password {
                let userPasswordData = "\(clientId):\(password)".data(using: .utf8)
                let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
                let authString = "Basic \(base64EncodedCredential)"
                requestCopy.addValue(authString, forHTTPHeaderField: "Authorization")
                requestCopy.addValue("application/json", forHTTPHeaderField: "Accept")
            }
        }
        
        return requestCopy
    }
    
    func setBody(for request: URLRequest) -> URLRequest {
        var requestCopy = request
        if case .postAuthorisationToken(let token) = method {
            let postBodyParams = [
                "grant_type": "authorization_code",
                "redirect_uri": "djingoapp://",
                "code": token,
            ]
            let body = postBodyParams.queryParameters
            requestCopy.httpBody = body.data(using: .utf8)
        }
        return requestCopy
    }
    
    public init(method: SVKAPIClientOIDCRequest.Method) {
        self.method = method
        
    }
    
    public func perform(completionHandler: @escaping (SVKAPIRequestResult) -> Void) {
        performDefault(completionHandler:  { (result) in
            if case .error( _, _, _, let userInfo ) = result {
                if let value = (userInfo?["NSErrorFailingURLStringKey"]) as? String {
                    let firstIndex = value.range(of: "code=")?.upperBound
                    let endIndex = value.range(of: "&state=")?.lowerBound
                    if let firstIndex = firstIndex, let endIndex = endIndex {
                        let token = String(value[firstIndex..<endIndex])
                        let tokenResult = SVKAPIRequestResult.success(.success, token)
                        completionHandler(tokenResult)
                        return
                    }
                    
                }
            }
            completionHandler(result)
        }, verbose: false)
    }
}
