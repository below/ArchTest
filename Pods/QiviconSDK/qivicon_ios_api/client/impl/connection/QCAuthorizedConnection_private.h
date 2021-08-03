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
//  QCAuthorizedConnection_private.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 21.11.13.
//
#import "QCHTTPClientConnectionContext.h"

@interface QCAuthorizedConnection (private)<QCAsyncAuthDelegate>

- (BOOL)isAccessTokenRefreshNeeded;
- (BOOL)refreshAccessTokenIfNeededWithError:(NSError **) error;
- (void)refreshWithDelegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError **)error;
    
/**
 *  An attempt to get rid of the client connection context
 */

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
 *            methods as array
 * @return class of classOfT
 */
- (id) callWithClass:(Class)classOfT
    url:(NSURL *)url
    authToken:(NSString *)authToken
    gwId:(NSString *)gwId
    methods:(NSArray *)methods
    error:(NSError * __autoreleasing *)error;

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

- (QCOAuth2Token *) tokenFromOAuthProvider:(NSURL *) url withPostParams:(NSDictionary *)postParams error:(NSError * *)error;
- (void) tokenFromOAuthProvider:(NSURL *) url withPostParams:(NSDictionary *)postParams delegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError * *)error;

@end
