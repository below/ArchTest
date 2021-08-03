//
//  QCAsyncAuthDelegateProtocol.h
//  qivicon_ios_api
//
//  Created by Michael on 15.07.16.
//  Copyright © 2016 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QCOAuth2Token;
@class QCAuthorizedConnection;

@protocol QCAsyncAuthDelegate <NSObject>
- (void)authOnConnection:(QCAuthorizedConnection*)connection wasSuccessfulWithAuthToken:(QCOAuth2Token*)authToken;
- (void)authOnConnection:(QCAuthorizedConnection*)connection didFailWithError:(NSError *)error;
@end
