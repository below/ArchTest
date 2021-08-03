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

/**
 The HTTP standard error codes
 */
public enum SVKHTTPStatusCode: Int {
    case success = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case notModified = 304
    case clientSideError = 400
    case invalidToken = 401
    case authorizationError = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case noMatchingSkill = 497
    case intentUnresolved = 499
    case unsupportedMediaType = 415
    case serverSideError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case failure = 1000
    case decodingFailed = 1001
    case networkConnection = -1009
    
    init(from response: URLResponse?, error: Error?) {
        if let response = response as? HTTPURLResponse {
            if let code = SVKHTTPStatusCode(rawValue: response.statusCode) {
                self = code
                return
            }
        } else if let _error = error as NSError? {
            if let code = SVKHTTPStatusCode(rawValue: _error.code) {
                self = code
                return
            }
        }
        self = .failure
    }
}

/**
 The public protocol of a SVKRequestable
 */
public protocol SVKRequestable {
    func perform(completionHandler: @escaping SVKCompletionHandler) -> Void
}

/**
 The internal protocol of a SVKRequestable
 */
protocol SVKAPIRequestProtocol: SVKRequestable {

    /// The type associated to the requester for json decoding
    associatedtype DecodingTypeGET: Decodable
    associatedtype DecodingTypePOST: Decodable
    associatedtype DecodingTypePUT: Decodable
    associatedtype DecodingTypeDELETE: Decodable

    /// The type associated to the requester for PrettyLogger
    associatedtype Identity

    /**
     Called after the data has been decoded to the DecodingType
     - parameter data: The data that has been decoded
     - parameter object: The decoded object
     */
    func didDecodeData<T>(_ data: Data?, to object: inout T)

    /**
     Implement this method to configure the URLRequest use by the SVKRequestable
     * parameter url: The URL from which the URLRequest should be construct
     */
    func requestWithURL(_ url: URL) -> URLRequest
    
    /**
     Implement this method to configure the `URLRequest` with custom defined headers.
     * Otherwise the method configure `URLRequest` with default headers
     */
    func addHeaders(to request: URLRequest) throws -> URLRequest
    
    /**
     Implement this method to configure the `URLRequest` with custom defined body.
     * Otherwise the method configure `URLRequest` with default body
     */
    func setBody(for request: URLRequest) -> URLRequest
    
    /// The absolute path of the query string
    var absoluteQueryString: String { get }

    /// **true** if an authorization token is required. Default to **true**.
    var isAuthorizationTokenRequired: Bool { get }
}
enum SVKAPIRequestCreationErrors: Error {
    case `internal`(String)
    case missingToken(String)
}
extension SVKAPIRequestProtocol {

    var absoluteQueryString: String {
        return ""
    }

    var isAuthorizationTokenRequired: Bool {
        return true
    }

    func requestWithURL(_ url: URL) -> URLRequest {
        return URLRequest(url: url)
    }

    func addHeaders(to request: URLRequest) throws -> URLRequest{
        var requestCopy = request
        requestCopy.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestCopy.addValue(SVKAPIClient.apiKey, forHTTPHeaderField: "apiKey")
        requestCopy.addValue(SVKAPIClient.language, forHTTPHeaderField: "Accept-Language")
        requestCopy.addValue(SVKUserIdentificationManager.shared.uniqueID, forHTTPHeaderField: "X-Touchpoint-Id")

        var meta = "{\"serialNumber\": \"" + SVKUserIdentificationManager.shared.serialNumber + "\""
        
        if let deviceName = SVKUserIdentificationManager.shared.deviceName {
            meta += ", \"deviceName\": \"" + deviceName.escapedJSONString + "\""
            
        }
        let data = SVKAPIClient.clientMetadata
        if let data = data {
            meta += " , \"data\": { "
            var first = true
            data.forEach { (arg0) in
                let (key, value) = arg0
                if first {
                    first = false
                } else {
                    meta += ","
                }
                meta += " \"\(key)\" : \"\(value)\" "
            }
            meta += "}}"
            
        } else {
            meta += "}"
        }
        requestCopy.addValue(meta, forHTTPHeaderField: "X-Client-Metadata")
        // append the token for non login requests
        if isAuthorizationTokenRequired {
            guard let token = SVKAPIClient.shared.getToken() else {
                throw SVKAPIRequestCreationErrors.missingToken("Bad token")
            }
            requestCopy.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return requestCopy
    }
    
    func setBody(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public func didDecodeData<T>(_: Data?, to _: inout T) {}

    
    public func perform(completionHandler: @escaping (SVKAPIRequestResult) -> Void) {
        performDefault(completionHandler: completionHandler)
    }
    
    public func performDefault(completionHandler: @escaping (SVKAPIRequestResult) -> Void, verbose: Bool = true) {
        guard let URL = Foundation.URL(string: absoluteQueryString) else {
            completionHandler(SVKAPIRequestResult.error(.failure, SVKApiErrorCode.internal.rawValue, "malformed url",nil))
            return
        }
        var request = requestWithURL(URL)
        
        do {
            request = try addHeaders(to: request)
        } catch SVKAPIRequestCreationErrors.internal(let message) {
            completionHandler(SVKAPIRequestResult.error(.failure, SVKApiErrorCode.internal.rawValue, message,nil))
            return
        }catch SVKAPIRequestCreationErrors.missingToken(let message){
            completionHandler(SVKAPIRequestResult.error(.failure, SVKApiErrorCode.missingToken.rawValue, message,nil))
            return
        }catch{
            completionHandler(SVKAPIRequestResult.error(.failure, SVKApiErrorCode.internal.rawValue, "unknown error due to request creation",nil))
            return
        }
        
        request = setBody(for: request)

        #if DEBUG
        if verbose {
            let str = request.debugDescription
            SVKLogger.debug(str)
        }
        #endif

        URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            #if DEBUG
                if verbose,var debugData = data, debugData.count > 0 {
                    do {
                        let dictionary = try JSONSerialization.jsonObject(with: debugData, options: .init(rawValue: 0))
                        debugData =  try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
                    } catch { }
                    SVKLogger.debug(String(data: debugData, encoding: .utf8) ?? "")
                }
            #endif

            let statusCode = SVKHTTPStatusCode(from: urlResponse, error: error)
            switch statusCode {
            case .noContent:
                completionHandler(SVKAPIRequestResult.success(.success, nil))

            case .success where ((DecodingTypePOST.self as? SVKRawData.Type) != nil):
                completionHandler(SVKAPIRequestResult(data: SVKRawData(data: data!), error: nil))

            case .success where String.self == DecodingTypeGET.self && request.httpMethod == "GET":
                completionHandler(SVKAPIRequestResult(data: urlResponse?.url ?? "", error: error))
                
            case .success where request.httpMethod == "GET":
                var (response, error) = self.decode(DecodingTypeGET.self, from: data!)
                if error == nil {
                    self.didDecodeData(data, to: &response)
                    completionHandler(SVKAPIRequestResult(data: response, error: error))
                } else {
                    completionHandler(SVKAPIRequestResult.error(.decodingFailed, SVKApiErrorCode.unknown.rawValue, "Fail to decode response",nil))
                }

            case .success where request.httpMethod == "POST" && data!.count == 0:
                completionHandler(SVKAPIRequestResult(data: data))

            case .success where request.httpMethod == "POST":
                var (response, error) = self.decode(DecodingTypePOST.self, from: data!)
                if error == nil {
                    self.didDecodeData(data, to: &response)
                    completionHandler(SVKAPIRequestResult(data: response, error: error))
                } else {
                    completionHandler(SVKAPIRequestResult.error(.decodingFailed, SVKApiErrorCode.unknown.rawValue, "Fail to decode response",nil))
                }

            case .success where request.httpMethod == "PUT":
                var (response, error) = self.decode(DecodingTypePUT.self, from: data!)
                if error == nil {
                    self.didDecodeData(data, to: &response)
                    completionHandler(SVKAPIRequestResult(data: response, error: error))
                } else {
                    completionHandler(SVKAPIRequestResult.error(.decodingFailed, SVKApiErrorCode.unknown.rawValue, "Fail to decode response",nil))
                }

            case .success where request.httpMethod == "DELETE":
                if let data = data, data.isEmpty {
                    completionHandler(SVKAPIRequestResult.success(.success, nil))
                } else {
                    var (response, error) = self.decode(DecodingTypeDELETE.self, from: data!)
                    if error == nil {
                        self.didDecodeData(data, to: &response)
                        completionHandler(SVKAPIRequestResult(data: response, error: error))
                    } else {
                        completionHandler(SVKAPIRequestResult.error(.decodingFailed, SVKApiErrorCode.unknown.rawValue, "Fail to decode response",nil))
                    }
                }
            case .intentUnresolved, .serviceUnavailable:
                var (response, error) = self.decode(DecodingTypeGET.self, from: data!)
                if error == nil {
                    self.didDecodeData(data, to: &response)
                    completionHandler(SVKAPIRequestResult(data: response, error: error))
                } else {
                    completionHandler(SVKAPIRequestResult.error(.decodingFailed, SVKApiErrorCode.unknown.rawValue, "Fail to decode response",nil))
                }

            case .failure where error != nil:
                if let error = error as NSError? {
                    completionHandler(SVKAPIRequestResult.error(.failure, "\(error.code)", error.localizedDescription,error.userInfo))
                }
                
            case .networkConnection where error != nil:
                if let error = error as NSError? {
                    completionHandler(SVKAPIRequestResult.error(.networkConnection, "\(error.code)", "feedback.networkFailure".localized,error.userInfo))
                }
                
            case .invalidToken:
                completionHandler(SVKAPIRequestResult.error(.invalidToken, SVKApiErrorCode.missingToken.rawValue, "Invalid Token",nil))
                
            default :
                let result = self.decodeErrorFrom(data: data, statusCode: statusCode)
                completionHandler(result)
            }
        }.resume()
    }
    /**
     Decodes a top-level value of the given type from the given JSON representation.

     - parameter type: The type of the value to decode.
     - parameter data: The data to decode from.
     - returns: A tuple (T?, Error?)
     */
    func decode<T>(_ type: T.Type, from data: Data) -> (T?, Error?) where T: Decodable {
        do {
            let decodedObject = try JSONDecoder().decode(type, from: data)
            return (decodedObject, nil)
        } catch let error {
            SVKLogger.error("\(error)")
            SVKLogger.debug(String(data: data, encoding: .utf8) ?? "")
            return (nil, error)
        }
    }

    /**
     Decodes an error from a given data
     - parameter data: The data to be decoded
     - parameter statusCode: The HTTP status code returned by the HTTP request
     - returns: A SVKAPIRequestResult of type .error
     */
    func decodeErrorFrom(data: Data?, statusCode: SVKHTTPStatusCode) -> SVKAPIRequestResult {
        var message: String = "Fail to invoke the service: code(\(statusCode.rawValue)) - \(statusCode)"
        var errorCode: SVKApiErrorCode = .unknown
        if let data = data {
            let ( svkError, _) = self.decode(SVKAPIRequestError.self, from: data)
            if let svkError = svkError {
                message = svkError.message
                errorCode = SVKApiErrorCode(code: svkError.code)
            } else if let string = String(data: data, encoding: .utf8) {
                SVKLogger.error("\(message): \(string)")
            }
        }
        return SVKAPIRequestResult.error(statusCode, errorCode.rawValue, message,nil)
    }
}
protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    /**
     This computed property returns a query parameters string from the given NSDictionary. For
     example, if the input is ["response_type": "code", "redirect_uri": "djingoapp://", "state":"empty", "prompt":"none", "client_id": client_id, "scope":scope ], the output
     string will be "redirect_uri=djingoapp://&prompt=none&state=empty&client_id=client_id&scope=scope&response_type=code".
     @return The computed parameters string.
    */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? String(describing: key),
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? String(describing: value)) // .urlHostAllowed
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension String {
    /**
     Creates a new String by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new String.
    */
    func appendingQueryParameters(_ parametersDictionary : [String: String]) -> String {
        return String(format: "%@?%@", self, parametersDictionary.queryParameters)
    }
}
extension String {

    public var escapedJSONString: String {
        return replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\'", with: "′")
            .replacingOccurrences(of: "/", with: "\\/")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\u{8}", with: "\\b")
            .replacingOccurrences(of: "\u{12}", with: "\\f")
            .replacingOccurrences(of: "\u{1B}", with: "\\" + "u001B")
            .replacingOccurrences(of: "\u{1b}", with: "\\" + "u001B")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

extension URLRequest {
    var forbiddenHeader: [String] {
        return ["Authorization", "X-Client-Metadata", "apiKey", "Cookie" ]
    }
    
    var description: String {
        if let url = self.url {
            let restrictedUrl = url.absoluteString
            if let endOfSentence = restrictedUrl.firstIndex(of: "?") {
                let firstSentence = restrictedUrl[...endOfSentence]
                return String(firstSentence)
            }
        }
        return ""
    }
    
    var debugDescription: String {
        guard let httpMethod = self.httpMethod else {
            return "Invalid httpMethod"
        }
        guard let url = self.url else {
            return "Invalid URL"
        }
        
        var outputString = "curl -X \(httpMethod) \(url)"
        outputString = outputString.replacingOccurrences(of: "http", with: "'http")
        outputString.append("'")
        var headerString = ""
        for value in self.allHTTPHeaderFields ?? [:] {
            if headerString.count > 0 {
                headerString.append(" ")
            }
            let printedValue = forbiddenHeader.contains(value.0) ? "XXXXXXXXXXXXXX" : value.1
            headerString.append("-H '\(value.0): \(printedValue)'")
        }
        if headerString.count > 0 {
            outputString.append(" ")
        }
        outputString.append(headerString)
        
        var bodyString = ""
        if let body = self.httpBody {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: body, options: [])
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                if let string = String(data: jsonData, encoding: .utf8) {
                    bodyString.append(string.replacingOccurrences(of: "\"", with: "\\\""))
                }
            }
            catch {
                if let string = String(data: body, encoding: .utf8) {
                bodyString.append(string)
                }
            }
        }
        if headerString.count > 0 {
            if outputString.count > 0 {
                outputString.append(" ")
            }
            outputString.append(bodyString)
        }

        return outputString
    }
}
