/*
 * (C) Copyright 2011-2013 by Deutsche Telekom AG.
 *
 * This software is property of Deutsche Telekom AG and has
 * been developed for QIVICON platform.
 *
 * See also http://www.qivicon.com
 *
 * DO NOT DISTRIBUTE OR COPY THIS SOFTWARE OR PARTS OF THE SOFTWARE
 * TO UNAUTHORIZED PERSONS OUTSIDE THE DEUTSCHE TELEKOM ORGANIZATION.
 *
 * VIOLATIONS WILL BE PURSUED!
 */

#import <Foundation/Foundation.h>

/**
 * Utility functions for connection handling. Provides methods to create the
 * endpoint URLs.
 * <p>
 * Must be initialized either implicitly or explicitly.
 */
@interface QCGlobalSettings : NSObject

/**
 * Initialize connection utilities. Don't use the property file for
 * initialization.
 *
 * @param oaEP
 *            OAuth2 Endpoint
 * @param oaTokenEP
 *            OAuth2 Token Endpoint
 * @param remoteEP
 *            Remote Endpoint
 * @param backendEP
 *            Backend Endpoint
 * @param qiviconBackendEP
 *            Endpoint of QIVICON backend
 * @param websocketEP
 *            Websocket Endpoint
 * @param appUrl
 *            Redirection URL
 * @param scope
 *            Scope
 * @param clientId
 *            Client ID
 * @param clientSecret
 *            Client Secret - may be null
 * @param useProxy
 *            YES, if proxy must be used
 * @param proxyHost
 *            proxy host
 * @param proxyPort
 *            proxy port
 * @return initialized object
 */
- (id) initWithOaEP:(NSString *)oaEP
          oaTokenEP:(NSString*)oaTokenEP
           remoteEP:(NSString*)remoteEP
          backendEP:(NSString*)backendEP
 backendGatewayIdEP:(NSString*)backendGatewayIdEP
   qiviconBackendEP:(NSString*)qiviconBackendEP
        websocketEP:(NSString*)websocketEP
             appUrl:(NSString*)appUrl
              scope:(NSString*)scope
           clientId:(NSString*)clientId
       clientSecret:(NSString*)clientSecret
           useProxy:(BOOL)useProxy
          proxyHost:(NSString*)proxyHost
          proxyPort:(NSInteger)proxyPort;

/**
 * Provide the OAuth-URL for the login dialog.
 * <p>
 * <strong>Avoid using this method directly. Starting with version 2.0 use
 * the delegation method {@link QCAuthorizedConnection#loginURL}.
 * </strong>
 *
 * @param endpoint
 *            OAuth authorize endpoint
 *
 * @return URL
 */
- (NSURL *) loginURLForEndpoint:(NSURL *)endpoint;

/**
 * Provide the OAuth-URL for the login dialog. A state parameter can be
 * attached.
 * <p>
 * <strong>Avoid using this method directly. Starting with version 2.0 use
 * the delegation method {@link QCAuthorizedConnection#loginURLForState:}.
 * </strong>
 *
 * @param endpoint
 *            OAuth authorize endpoint
 * @param state
 *            state parameter for the request
 * @return URL
 */
- (NSURL *) loginURLForEndpoint:(NSURL *)endpoint state:(NSString*) state;

/**
 * Provide the OAuth request parameters for authorization using <i>grant_type=password</i>
 * authorization.
 *
 * @deprecated should never be used by end users
 *
 * @param username
 *            user name
 * @param password
 *            password
 * @return URL
 */
- (NSDictionary *) oAuthRequestParametersWithUsername:(NSString *)username
                                             password:(NSString *)password __attribute__((deprecated));

/**
 * Provide the OAuth request parameters for authorization using <i>grant_type=code</i>
 * authorization. Parameter <code>client_id</code> will only be included if
 * parameter <code>client_secret</code> is not set!
 *
 * @param code
 *            authorization code
 * @return URL
 */
- (NSDictionary *) oAuthRequestParametersWithAuthCode:(NSString *) code;

/**
 * Provide the OAuth request parameters for authorization using
 * <i>grant_type=refresh_token</i>. Parameter <code>client_id</code> will
 * only be included if parameter <code>client_secret</code> is not set!
 *
 * @param refreshToken
 *            refresh token
 * @return URL
 */
- (NSDictionary *) oAuthRefreshRequestParametersWithRefreshToken:(NSString *)refreshToken;

/**
 * Return the Base64 encoded client authorization
 * <code>client_id:client_secret</code>. If client_secret is not set, null
 * is returned.
 *
 * @return encoded authorization string or null
 */
- (NSString *) clientAuthorization;


/**
 * Provide the client identifier used as part of Backend requests payloads
 *
 * @return String
 */
@property (readonly) NSString *clientId;


/**
 * Provide the URL to connect to QIVICON backend
 *
 * @return URL
 */
@property (readonly) NSURL *qiviconBackendURL;

/**
 * Provide the URL to connect to the Backend
 *
 * @return URL
 */
@property (readonly) NSURL *backendURL;

/**
 * Provide the URL to connect to the Backend for retrieval of gateway ID's
 *
 * @return URL
 */
@property (readonly) NSURL *backendGatewayIdURL;

/**
 * Provide the URL to connect to <i>Service Gateway</i> via Remote
 *
 * @return URL
 */
@property (readonly) NSURL *remoteAccessURL;

@property (readonly) NSString *appUrl;

/**
 * Provide the URL to connect to remote websockets
 *
 * @return webSocketURL
 */
- (NSURL *) webSocketURL;

@property (readonly) NSURL *oAuthEndpoint;

@property (readonly) NSURL *oAuthTokenEndpoint;
@end
