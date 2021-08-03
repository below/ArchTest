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

@class QCOAuth2Token;

/**
 * This interface must be implemented to provide a secure storage for the OAuth2
 * refresh token.
 */
@protocol QCPersistentTokenStorage <NSObject>

/**
 * Stores the provided OAuth2 refresh token.
 *
 * @param gatewayId
 *            id of the service gateway that shall be used with the provided
 *            token
 * @param refreshToken
 *            token to be stored
 */
- (void)storeTokenForGatewayId:(NSString *)gatewayId token:(NSString*)refreshToken;

/**
 * Retrieves a OAuth2 refresh token from storage.
 *
 * @param gatewayId
 *            id of the service gateway that shall be used with the provided
 *            token
 * @return refresh token loaded from storage or null, if token cannot be
 *         retrieved
 */
- (NSString*)loadTokenForGatewayId:(NSString *)gatewayId;

- (void)storeOAuthToken:(QCOAuth2Token *)token forID:(NSString *)tokenId;

- (QCOAuth2Token *)oAuthTokenForID:(NSString *)tokenId;

- (void)storeRemoteAccessToken:(NSString*)token expireTime:(double)expireTime;

/**
 *
 * @param gatewayId
 *            id of the service gateway that used the provided token
 */
- (void)deleteTokenForGatewayId:(NSString *)gatewayId;

- (void)deleteOAuthTokenForID:(NSString *)tokenId;

- (void)deleteRemoteAccessToken;

/**
 * Deletes all OAuth2 refresh token from storage.
 */
- (void) deleteAllTokens;

/**
 * Store the local network IP Address of the Gateway
 */
- (void)storeLocalIP:(NSString *)localIP;
@end
