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
public struct SVKAPICviLoginV2Request: SVKAPIRequestProtocol {
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = String
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET

    // The logger use this identity
    typealias Identity = SVKAPICviLoginV2Request
    
    var absoluteQueryString: String {
        var url = SVKAPIClient.baseURL + "/user/api/v2/login?clientId=" + (SVKAPIClient.clientOIDC?.clientId ?? "")        
        url += "&scope=" +  (SVKAPIClient.clientOIDC?.scope.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")
        return url
    }
    
    var isAuthorizationTokenRequired: Bool {
        return false
    }
    
    public init() {
    }
     
    public func perform(completionHandler: @escaping (SVKAPIRequestResult) -> Void) {
        performDefault(completionHandler: completionHandler, verbose: false)
    }
}
