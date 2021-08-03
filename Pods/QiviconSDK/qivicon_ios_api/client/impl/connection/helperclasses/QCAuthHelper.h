//
//  QCAuthHelper.h
//  
//
//  Created by Michael on 15.12.15.
//
//

#import <Foundation/Foundation.h>
#import "QCAsyncAuthDelegateProtocol.h"

@class QCOAuth2Token;

@interface QCAuthHelper : NSObject<NSURLSessionDelegate>

- (id _Nonnull ) init __attribute((unavailable("Call initWithSession!")));
    
- (id _Nonnull )initWithSession:(NSURLSession * __nonnull)session;
    
/**
 * Create the POST request to get the OAuth token. If a client secret is
 * defined, a BASIC AUTH header will be added with clientSecret:clientId.
 *
 * @param url
 *            URL to call
 * @param postParams
 *            a map containing the parameters for the POST request; must not
 *            be null
 * @return create POST request
 * @throws AuthException
 *             for any error
 */
- (NSURLRequest *_Nonnull) createPostRequestWithUrl:(NSURL*_Nonnull)url
                                         postParams:(NSDictionary*_Nullable)postParams
                                clientAuthorization:(NSString*_Nullable)clientAuthorization
                                              error:(NSError *_Nonnull* _Nullable)error;


- (QCOAuth2Token*_Nonnull)executeAuthorizeCallWithRequest:(NSURLRequest*_Nonnull)request error:(NSError *_Nonnull* _Nullable)error;

- (void)executeAuthorizeCallAsyncWithRequest:(NSURLRequest*_Nonnull)request delegate:(id<QCAsyncAuthDelegate>_Nullable)delegate;
@end
