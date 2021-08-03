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
 A structure to delete an oauth2 token
 */
public struct SVKAPIDeleteOauth2TokenRequest: SVKAPIRequestProtocol {
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKRawData
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET
    
    // The logger use this identity
    typealias Identity = SVKAPIDeleteOauth2TokenRequest
    
    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/user/api/v1/token/" + self.tokenId
    }
    
    var isAuthorizationTokenRequired: Bool {
        return true
    }
    var tokenId: String
    
    public init(tokenId: String) {
        self.tokenId = tokenId
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
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
