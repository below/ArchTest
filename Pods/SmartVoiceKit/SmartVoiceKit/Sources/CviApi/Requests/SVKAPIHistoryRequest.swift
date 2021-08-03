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
public struct SVKAPIHistoryRequest: SVKAPIRequestProtocol {
    
    public enum Method {
        case get(_ date: Date, _ limit: Int, _ direction: SVKFetchHistoryDirection, _ suppressError: Bool, _ deviceSerialNumber: String?)
        case post(_ ids: [String])
        case delete(_ deviceSerialNumber: String?)
        case put(_ id: String, _ feedback: SVKFeedback)
        
        var httpMethod: String {
            switch self {
            case .get: return "GET"
            case .post: return "POST"
            case .delete: return "DELETE"
            case .put: return "PUT"
            }
        }
    }
    
    // The request data response is decoded to this type
    typealias DecodingTypeGET = SVKHistoryEntries
    typealias DecodingTypePUT = SVKHistoryEntryShort
    typealias DecodingTypePOST = SVKHistoryEntry
    typealias DecodingTypeDELETE = SVKHistoryEntry

    // The logger use this identity
    typealias Identity = SVKHistoryRequest
    
    /// The method
    var method: SVKAPIHistoryRequest.Method
    
    var absoluteQueryString: String {
        var query = ""
        
        switch method {
        case .get(let date, let limit, let direction,let suppressError, let deviceSerialNumber):
            query = "?fromDate=\(date.formatted())" + "&direction=\(direction.rawValue)" + "&limit=\(limit)&suppressErrorConversations=\(suppressError)"
            
            if let deviceSerialNumber = deviceSerialNumber {
                let param = "&deviceSerialNumber=\(deviceSerialNumber)"
                let escaped = param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                if let escaped = escaped {
                    query += escaped
                }
            }
            return SVKAPIClient.baseURL + "/history/app/api/v2/conversations\(query)"
        case .post:
            query = "/bulkDelete"
        case .delete(let deviceSerialNumber):
            var parameters = ""
            if let deviceSerialNumber = deviceSerialNumber {
                let param = "deviceSerialNumber=\(deviceSerialNumber)"
                let escaped = param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                if let escaped = escaped {
                    parameters = "?" + escaped
                }
            }
            return SVKAPIClient.baseURL + "/history/app/api/v2/conversations\(parameters)"
        case .put(let id, _):
            query = "/\(id)/vote"
        }
        return SVKAPIClient.baseURL + "/cvi/user/api/v1/history\(query)"
    }
    
    func requestWithURL(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.httpMethod
        
        if case .post(let ids) = method {
            request.httpBody = jsonDataHistoryEntriesFrom(ids: ids)
        } else if case .put(_, let feedback) = method {
            request.addValue(SVKAPIClient.language, forHTTPHeaderField: "Accept-Language")
            request.httpBody = """
                { "vote":"\(feedback.rawValue)" }
                """.data(using: .utf8)
        }
        
        return request
    }
    
    public init(method: SVKAPIHistoryRequest.Method) {
        self.method = method
    }

    private func jsonDataHistoryEntriesFrom(ids: [String]) -> Data {
        let begin = """
        {"entries": [
        """
        let content = ids.reduce("") { (content, id) -> String in
            let entry = """
            {"id":"\(id)"}
            """
            return content.count > 0 ? "\(content), \(entry)" : entry
        }
        
        let end = "]}"
        
        let json = begin + content + end
        return json.data(using: .utf8)!
    }

}

fileprivate extension Date {
    func formatted(with format: String = "yyyy-MM-dd'T'HH:mm:ss'Z'") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: self)
    }
}
