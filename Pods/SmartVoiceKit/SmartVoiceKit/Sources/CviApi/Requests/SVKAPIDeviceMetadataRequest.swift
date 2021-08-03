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
public struct SVKAPIDeviceMetadataRequest: SVKAPIRequestProtocol {
    
    public enum Method {
        case get(_ serialNumber: String)
        
        var httpMethod: String {
            switch self {
            case .get: return "GET"
            }
        }
    }
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKDeviceMetadata
    typealias DecodingTypePOST = DecodingTypeGET
    typealias DecodingTypePUT = DecodingTypeGET
    typealias DecodingTypeDELETE = DecodingTypeGET
    
    // The logger use this identity
    typealias Identity = SVKAPIDeviceMetadataRequest
    
    /// The method
    var method: SVKAPIDeviceMetadataRequest.Method
    
    var absoluteQueryString: String {
        
        
        var uri = ""
        
        switch method {
        case .get(let serialNumber):
            uri = "/svhb/devicegateway/api/configuration/v4/device/\(serialNumber)/info"
       
        }
        return SVKAPIClient.baseURL + uri
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.httpMethod
        
        return request
    }
    
    public init(method: SVKAPIDeviceMetadataRequest.Method) {
        self.method = method
    }
}