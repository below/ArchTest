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
 * Access token from OAuth provider.
 */
@interface QCOAuth2Token : NSObject

/**
 * Constructor is only used for test cases.
 * @param accessToken
 * @param tokenType
 * @param expiresIn
 * @param refreshToken
 * @param scope
 * @return initialized object 
 */
- (id) initWithAccessToken:(NSString*)accessToken
                 tokenType:(NSString *)tokenType
                expireTime:(double)expireTime
              refreshToken:(NSString *)refreshToken
                     scope:(NSString *)scope;

/**
 * Get the access token.
 *
 * @return access token
 */
@property(atomic, readwrite, strong) NSString *access_token;

/**
 * Get the token type.
 *
 * @return token type
 */
@property(atomic, readwrite, strong) NSString *token_type;

/**
 * Get the expires in.
 *
 * @return expires in 
 */
@property(nonatomic, readwrite, assign) double expires_in;

/**
 * Get the expires in.
 *
 * @return expires in
 */
@property(atomic, readwrite, assign) double expire_time;

/**
 * Get the refresh token.
 *
 * @return refresh token
 */
@property(atomic, readwrite, strong) NSString *refresh_token;

/**
 * Get the scope.
 *
 * @return scope
 */
@property(atomic, readwrite, strong) NSString *scope;


- (BOOL)isAccessTokenRefreshNeeded;
- (BOOL)isAuthorized;

@end
