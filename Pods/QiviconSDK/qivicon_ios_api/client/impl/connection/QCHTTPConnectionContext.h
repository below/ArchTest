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

//
//  ConnectionContext.h
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 10.01.13.
//

#import <Foundation/Foundation.h>
@class QCOAuth2Token;
#import "QCGlobalSettings.h"
#import "QCRemoteMethod.h"
#import "QCAuthorizedConnection.h"
#import "QCAsyncAuthDelegateProtocol.h"

/** HTTP header name for the OAuth2 token. */
extern NSString * const HEADER_AUTHORIZATION;

/** Start string of an Basic Auth string */
extern NSString * const BASIC;

/** HTTP header name for the id of the <i>Service Gateway</i>. */
extern NSString * const HEADER_QIVICON_SERVICE_GATEWAY_ID;

/** Standard Charset: UTF-8 */
extern NSString * const UTF_8;

/** The "http://" prefix */
extern NSString * const HTTP_PROTOCOL;

/** The "https://" prefix */
extern NSString * const HTTPS_PROTOCOL;

/** The "ws://" prefix */
extern NSString * const WS_PROTOCOL;

/** The "wss://" prefix */
extern NSString * const WSS_PROTOCOL;

/** The url used to retrieve a session id from a Service Gateway */
extern NSString * const LOGIN_URL;

/** The url used for local communication with a Service Gateway */
extern NSString * const RPC_URL;

/** The local OAuth2 authorization endpoint */
extern NSString * const OAUTH_AUTHORIZE_ENDPOINT;

/** The local OAuth2 token endpoint */
extern NSString * const OAUTH_TOKEN_ENDPOINT;

/** The url used for web sockets */
extern NSString * const WS_URL;

/** The url used for the local system information */
extern NSString * const SYSTEM_INFO_ENDPOINT;

/** default https port */
extern int const HTTPS_PORT;

/** default http port */
extern int const HTTP_PORT;

/** default web sockets port */
extern int const WS_PORT;

/** secure web sockets port */
extern int const WSS_PORT;

/** default http port for json-rpc communication (8080) */
extern int const HTTP_PORT2;

@protocol QCConnection;
@protocol QCHTTPConnectionContext;

@protocol QCHTTPConnectionContextDelegate <NSObject>

- (void) connection:(id <QCHTTPConnectionContext>)connection
       withMethodId:(NSNumber *)methodId
   didFailWithError:(NSError *)error;

- (void) connection:(id)connection withMethodId:(NSNumber *)methodId
    didFinishLoadingWithJSONResult:(id)result;

- (void)callWithMethodId:(NSNumber *)methodId
      remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
         customIdentifier:(NSString*)customIdentifier
         didFailWithError:(NSError *)error;

- (void)callWithMethodId:(NSNumber *)methodId
      remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
        customIdentifier:(NSString*)customIdentifier didFinishLoadingWithJSONResult:(id)result;
@end

/**
 * Connection Context.
 */
@protocol QCHTTPConnectionContext <NSObject>

/**
 * Initalizes the connection utilities. Stores the global settings. Creates the
 * http client.
 *
 * @param gbl
            initialized global settings object
 * @return initialized object
 */
- (id) initWithGlobalSettings:(QCGlobalSettings *) gbl;

/**
 * Return the global settings.
 *
 * @return global settings
 */
- (QCGlobalSettings*) globalSettings;

/**
 * Perform a call asynchronously
 *
 * @param classOfT
 *            generic return type. If nil, an approprate basic type (NSString, NSDictionary, NSArray etc.) is returned
 * @param url
 *            URL to call
 * @param authToken
 *            authorization token
 * @param gwId
 *            gateway ID or NULL, if not necessary
 * @param methods
 *            array of methods to call; cannot be null, must contain at
 *            least one element
 * @param customIdentifier
 *            An optional custom Identitifier. This parameter is returned in the response
 * @param contextDelegate
 *            The delegate that called this method
 * @param remoteCallDelegate
 *            The delegate that should receive the final reply
 * @param error
 *            Contains the error if the call has failed.
 * @return class of classOfT */
- (BOOL) callAsyncWithClass:(Class)classOfT
                        url:(NSURL *)url
                  authToken:(NSString *)authToken
                       gwId:(NSString *)gwId
                    methods:(NSArray *)methods
           customIdentifier:(NSString*)customIdentifier
            contextDelegate:(id<QCHTTPConnectionContextDelegate>)contextDelegate
            remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
                      error:(NSError *__autoreleasing * )error;


/**
 * Perform a call synchronous.
 *
 * @param classOfT
 *            generic return type
 * @param url
 *            URL to call
 * @param authToken
 *            authorization token
 * @param gwId
 *            gateway ID or NULL, if not necessary
 * @param error
 *            Contains the error if the call has failed.
 * @param methods
 *            methods as argument list
 * @return class of classOfT
 */
- (id) callWithClass:(Class)classOfT
                 url:(NSURL *)url
           authToken:(NSString *)authToken
                gwId:(NSString *)gwId
               error:(NSError * __autoreleasing *)error
             methods:(QCRemoteMethod *)firstMethod, ...;

/**
 * Perform a call synchronous.
 *
 * @param classOfT
 *            generic return type
 * @param url
 *            URL to call
 * @param authToken
 *            authorization token
 * @param gwId
 *            gateway ID or NULL, if not necessary
 * @param methods
 *            array of methods to call; cannot be null, must contain at
 *            least one element
 * @param error
 *            Contains the error if the call has failed.
 * @return class of classOfT
 */
- (id) callWithClass:(Class)classOfT
                 url:(NSURL *)url
           authToken:(NSString *)authToken
                gwId:(NSString *)gwId
             methods:(NSArray *)methods
               error:(NSError * __autoreleasing *)error;

/**
 * Performs the OAuth2 call to the OAuth provider to get the OAuth2
 * token.
 *
 * @param url
 *            complete request url (includes all necessary parameters and the refresh token)
 * @param postParams
 *            dictionary with parameters for authoriziation
 * @return Token class containing the authorization and the refresh token
 * @throws AuthException
 *             if any error occurs
 */
- (QCOAuth2Token *) tokenFromOAuthProvider:(NSURL*) url
                            withPostParams:(NSDictionary *)postParams
                                     error:(NSError **) error;

/**
 * Performs an Async OAuth2 call to the OAuth provider to get the OAuth2
 * token.
 *
 * @param url
 *            complete request url (includes all necessary parameters and the refresh token)
 * @param postParams
 *            dictionary with parameters for authoriziation
 * @param delegate
 *            delegate that responds to the QCAsyncAuthDelegate protocol
 * @throws AuthException
 *             if any error occurs
 */
- (void) tokenFromOAuthProvider:(NSURL *) url
                 withPostParams:(NSDictionary *)postParams
                       delegate:(id<QCAsyncAuthDelegate>)delegate
                          error:(NSError * *)error;

@end
