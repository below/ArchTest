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

#import "QCOAuth2Token.h"

@implementation QCOAuth2Token
- (id) initWithAccessToken:(NSString*)accessToken
                 tokenType:(NSString *)tokenType
        expireTime:(double)expireTime
              refreshToken:(NSString *)refreshToken
                     scope:(NSString *)scope {
    self = [super init];
    if (self) {
        self.access_token = accessToken;
        self.token_type = tokenType;
        self.expire_time = expireTime;
        self.refresh_token = refreshToken;
        self.scope = scope;
    }
    return self;
}

- (void)setExpires_in:(double)expires_in {

    @synchronized (self) {
        _expire_time = expires_in + [[NSDate date] timeIntervalSince1970];
    }
}

- (double)expires_in {
    double interval = _expire_time - [[NSDate date] timeIntervalSince1970];
    return MAX(interval, 0);
}

- (NSString *) description {
    return [NSString stringWithFormat:@"Token: \naccess_token: %@\ntoken_type: %@\nexpires_in: %ld\nexpire_time: %f\nrefresh_token: %@\nscope: %@\n",
            self.access_token, self.token_type, self.expires_in, self.expire_time, self.refresh_token, self.scope];
}

-(BOOL)isAuthorized {
    if (self.refresh_token &&
        self.refresh_token.length > 0 &&
        self.access_token) {
        return YES;
    }
    return NO;
}

- (BOOL)isAccessTokenRefreshNeeded {
    BOOL needNewAuth = NO;
    long expiresIn = self.expires_in;
    
    if (expiresIn > 0) {
        double maxValidTime = 1800; // 30 mins
        NSTimeInterval expireTime = self.expire_time;
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval validTime= expireTime - interval;
        if (validTime < maxValidTime){
            needNewAuth = YES;
        }
    } else {
        needNewAuth = YES;
    }
    
    return needNewAuth;
}

@end
