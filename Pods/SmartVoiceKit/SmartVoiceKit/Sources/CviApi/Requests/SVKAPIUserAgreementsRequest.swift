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

public struct SVKAPIUserAgreementsRequest: SVKAPIRequestProtocol {

    public enum Method {
        case get
        case post(_ agreements: [SVKTNCAgreement])
        
        var httpMethod: String {
            switch self {
            case .get: return "GET"
            case .post: return "POST"
            }
        }
    }
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKUserAgreements
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET
    
    // The logger use this identity
    typealias Identity = SVKAPIUserAgreementsRequest
    
    /// The method
    var method: SVKAPIUserAgreementsRequest.Method

    
    var absoluteQueryString: String {
        return SVKAPIClient.baseURL + "/user/api/v1/tnc/agreement"
    }
    
    public init(method: SVKAPIUserAgreementsRequest.Method = .get) {
        self.method = method
    }
    

    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        request.httpMethod = method.httpMethod
        
        if case .post(let agreements) = method {
            request.httpBody = jsonDataAgreement(agreements: agreements)
        }
        
        return request
    }
    
    private func jsonDataAgreement(agreements: [SVKTNCAgreement]) -> Data {
    
        let content = agreements.reduce("") { (content, agreement) -> String in
            let entry = """
            {"agreed": \(agreement.0),
            "tncId": "\(agreement.1)"}
            """
            return content.count > 0 ? "\(content), \(entry)" : entry
        }
        
        let json = """
            {"saveAgreements": [\(content) ]}
            """
        return json.data(using: .utf8)!
    }

}
