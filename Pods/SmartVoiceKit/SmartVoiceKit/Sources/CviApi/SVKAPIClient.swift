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
 The service error codes
 */
public enum SVKApiErrorCode: String {
    case unknown
    case `internal`
    case invalidExternalToken = "InvalidExternalToken"
    case missingToken
    
    init(code: String?) {
        if let code = code, let errorCode = SVKApiErrorCode(rawValue: code) {
            self = errorCode
            return
        }
        self = .unknown
    }
}

/**
 History Fetch direction
 */
public enum SVKFetchHistoryDirection: String {
    case before = "BEFORE" /// Fetches messages before a given date
    case after = "AFTER" /// Fetches messages after a given date
}

private enum BaseApi: String {
    case cviCoreUser = "/cvi"
    case userManagmentUser = "/user"
}

/**
 This enumaration wraps a response of the server
 It constains to cases Success and Error
 */
public enum SVKAPIRequestResult {

    /**
     Initialisation method for a success result
     - parameter data : the result object for a Success case
     */
    init(data: Decodable?) {
        self = SVKAPIRequestResult.success(.success, data)
    }

    /**
     Initialisation method for a success or error result
     - parameter data : the result object for a Success case
     - parameter error : the error object
     */
    init(data: Decodable?, error: Error?) {
        if let data = data {
            self = SVKAPIRequestResult.success(.success, data)
        } else {
            self = SVKAPIRequestResult.error(.clientSideError, SVKApiErrorCode.unknown.rawValue, error?.localizedDescription ?? "Unknown error", nil)
        }
    }

    /** Success case */
    case success(SVKHTTPStatusCode, Decodable?)

    /** Error case */
    case error(SVKHTTPStatusCode, String, String,[String:Any]?)

    /**
     Convenience method for a short description
     - Returns : a short description of self
     */
    func description() -> String {
        switch self {
        case .success(.success, _):
            return "Success"
        case .error(let statusCode, let respStatus, let message,nil):
            return "\(statusCode) : (\(respStatus))" + message
        default:
            return "Unknown case (\(self))"
        }
    }
}
/**
    Delegate the storage of the token
 */
public protocol SVKSecureTokenDelegate {
    /**
    Store the token

    Ask to the delegate to store the token
    - parameter token: A string representing the token to be stored
    */
     func storeToken(_ token: String?)

    /**
     Returns the stored token or nil.
     */
    func getToken() -> String?
    
    func didInvalideToken(completionHandler: @escaping (_ success: Bool) -> Void)
}

public typealias SVKCompletionHandler = (SVKAPIRequestResult) -> Void

public struct SVKAPIClient {

    // The smartvoice server urls
    private(set) static var baseURL = ""
    private(set) static var loginURL = ""
    private(set) static var apiKey: String = ""
    public static var language: String = "en"
    
    @available(*, deprecated)
    public static var serialNumber: String? = UIDevice.current.identifierForVendor?.uuidString
    private(set) static var clientMetadata: [String:String]?
    
    private(set) static var clientOIDC: SVKAPIClientOIDC? = nil
    
    private static var secureTokenDelegate: SVKSecureTokenDelegate? = nil
    
    // The default GET request parameters
    lazy var defaultGETParameters: String = {
        return ""
    }()

    /**  creates a singleton of ErableClient */
    public static let shared = SVKAPIClient()
    private init() {}

    /// The default userAgent
    var userAgent: String {
        return "DJIN"
    }

    /**
     Configure the SDK
     */
    public static func configureWith(apiKey: String, baseURL: String, loginURL: String, language: String, secureTokenDelegate: SVKSecureTokenDelegate, clientMetadata: [String:String]?) {
        SVKAPIClient.apiKey = apiKey
        SVKAPIClient.baseURL = baseURL
        SVKAPIClient.loginURL = loginURL
        SVKAPIClient.language = language
        SVKAPIClient.clientMetadata = clientMetadata
        SVKLogger.debug("baseURL=\(baseURL) loginURL=\(loginURL) language=\(language) clientMetadata=\(String(describing: clientMetadata))")
        SVKAPIClient.secureTokenDelegate = secureTokenDelegate
    }

    static let pictureSericeHost = "picture.service"
    static let pictureServiceURI = "/svhb/devicegateway/api/pictures/v1/pictures"
    public static func configureOIDC(_ clientOIDC:SVKAPIClientOIDC) {
        SVKAPIClient.clientOIDC = clientOIDC
    }
}

public struct SVKAPIClientOIDC {
    let baseUrl: String
    let clientId: String
    let password: String
    let scope: String
    
    public init(baseUrl: String, clientId: String, password:String, scope: String) {
        self.baseUrl = baseUrl
        self.clientId = clientId
        self.password = password
        self.scope = scope
    }
}
// MARK: Session Token stuffs
extension SVKAPIClient {
    /**
     Store the token

     Store the token in UserDefaults database
     - parameter token: A string representing the token to be stored
     */
    public func storeToken(_ token: String?) {
        SVKAPIClient.secureTokenDelegate?.storeToken(token)
    }

    /**
     Returns the stored token or nil.
     */
    public func getToken() -> String? {
        return SVKAPIClient.secureTokenDelegate?.getToken()
    }

    /**
     Returns the token for an url.

     The token is returned only if the domain of the URL matches
     smartvoice hub base URL. Otherwise the function returns nil.
     - parameter url: The URL the token should be returned for.
     */
    public func token(matching url: URL) -> String? {
        guard url.host == URL(string: SVKAPIClient.baseURL)?.host else {
            return nil
        }
        return getToken()
    }

    /**
     Returns ture if the token is valid, false otherwise.
     */
    public var isTokenValid: Bool {
        return getToken() != nil
    }

    /**
     Reset the token to nil value
     */
    public func reset() {
        storeToken(nil)
    }
}

extension URL {

    /**
     The translated URL of an image stored on the CDN
     */
    public func translateByAppending(queryItems: [URLQueryItem]) -> URL {
        guard host == SVKAPIClient.pictureSericeHost,
            var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let cviURL = URL(string: SVKAPIClient.baseURL),
            let cviURLComponents = URLComponents(url: cviURL, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.scheme = cviURLComponents.scheme
        components.host = cviURLComponents.host
        components.path = SVKAPIClient.pictureServiceURI + components.path
        components.queryItems = queryItems
        return components.url ?? self
    }
}
