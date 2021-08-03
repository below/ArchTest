//
//  QCAuthHelper.m
//  
//
//  Created by Michael on 15.12.15.
//
//

#import "QCAuthHelper.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "QCHTTPConnectionContext.h"
#import "QCUtils.h"
#import "QCCertificateManager.h"
#import "QCOAuth2Token.h"
#import "QCErrors.h"
#import "JSONRPC.h"
#import "QCURLConnection.h"
#import <UIKit/UIKit.h>
#import "QCAsyncAuthDelegateProtocol.h"

NSString * const AUTH_CONN_ERROR_STRING = @"Auth Connection Error.";
NSString * const AUTH_REQUEST_FAILED_STRING = @"Auth Request failed.";
NSString * const REFRESH_AUTH_REQUEST_FAILED_STRING = @"Refresh Auth Request failed.";

@interface QCAuthHelper (){
    //multitasking
    NSUInteger bgTask;
}

@property(nonatomic, readwrite, strong) NSHTTPURLResponse *connResponse;
@property(nonatomic, readwrite, strong) NSData *responseData;
@property(nonatomic, readwrite, strong) NSError *connError;
@property(nonatomic, readwrite) BOOL connFinished;
@property(nonatomic, readwrite) BOOL connFailed;
@property(nonatomic, readwrite) BOOL authInProgress;
@property(atomic, readwrite, strong) NSLock *asyncRequestLock;
@property(nonatomic, readwrite)NSTimeInterval lastRequestFinishedTime;
@property(nonatomic, readwrite, strong)NSOperationQueue *queue;
@property(nonatomic, readwrite, strong)NSURLSession *session;
@property(nonatomic, readwrite, strong)NSURLSession *localSession;
@end

@implementation QCAuthHelper

static void returnOnMainThread(void (^block)(void))
{
    if (!block) return;
    
    if ( [[NSThread currentThread] isMainThread] ) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


- (id)init __attribute((unavailable("Call initWith Session!")))
{
    NSAssert(NO, @"Call initWith Session!");
    return nil;
}

- (id)initWithSession:(NSURLSession * __nonnull)session {
    self = [super init];
    if (self) {
        _asyncRequestLock = [[NSLock alloc] init];
        _authInProgress = NO;
        self.session = session;
    }
    return self;
}


- (NSURLRequest *) createPostRequestWithUrl:(NSURL*)url
                                 postParams:(NSDictionary*)postParams
                        clientAuthorization:(NSString*)clientAuthorization
                                      error:(NSError **)error {
    

    if (postParams == nil) {
        if (error)
            *error = [[NSError alloc] initWithDomain:NSArgumentDomain
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"POST parameters must not be null"}];
        return nil;
    }
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    req.HTTPMethod = @"POST";
    NSString *encoding = clientAuthorization;
    if (encoding != nil) {
        [req setValue:[BASIC stringByAppendingString:encoding] forHTTPHeaderField:HEADER_AUTHORIZATION];
    }

    NSMutableString *bodyString = [NSMutableString new];
    BOOL first = YES;
    for (NSString *key in postParams.allKeys) {
        if (!first)
            [bodyString appendString:@"&"];
        else
            first = NO;
        [bodyString appendFormat:@"%@=%@", [key urlEncoded], [[postParams valueForKey:key] urlEncoded]];
    }
    [req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    [req setValue:[NSString stringWithFormat:@"%lu", (unsigned long)req.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    return req;
}

- (void)executeAuthorizeCallAsyncWithRequest:(NSURLRequest*)request delegate:(id<QCAsyncAuthDelegate>)delegate{

    _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (bgTask == UIBackgroundTaskInvalid){
        [self startLongRunningTask];
    }
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data,
                                                                     NSURLResponse *response,
                                                                     NSError *error) {
                                                     
                                                     _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
                                                     _connResponse = (NSHTTPURLResponse *)response;
                                                     if (error) {
                                                         NSError *localError = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                                            code:AUTH_CONN_ERROR
                                                                                        userInfo: @{NSLocalizedDescriptionKey:AUTH_CONN_ERROR_STRING, NSUnderlyingErrorKey:error}];
                                                         returnOnMainThread(^{
                                                             [delegate authOnConnection:nil didFailWithError:localError];
                                                         });
                                                     } else {
                                                         _responseData = data;
                                                         if (_responseData && [_responseData length] > 0) {
                                                             NSInteger statusCode = [_connResponse statusCode];
                                                             
                                                             NSError *jsonError = nil;
                                                             
                                                             NSDictionary *jsonObject = nil;
                                                             
                                                             jsonObject = [JSONRPC resultFromJsonData:_responseData
                                                                                              asClass:[QCOAuth2Token class] error:&jsonError];;
                                                             
                                                             if (statusCode == 200 && !jsonError && jsonObject && [jsonObject isKindOfClass:[QCOAuth2Token class]]) {

                                                                 returnOnMainThread(^{
                                                                     [delegate authOnConnection:nil wasSuccessfulWithAuthToken:(QCOAuth2Token *) jsonObject];
                                                                 });

                                                             } else if (statusCode == 400 && jsonError) {
                                                                 NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:_responseData options:0 error:nil];
                                                                 if (jsonObject && [jsonObject[@"error"] isEqualToString:@"invalid_grant"]) {
                                                                     error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                         code:REFRESH_AUTH_REQUEST_FAILED
                                                                                                    userInfo:@{NSLocalizedDescriptionKey:REFRESH_AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long) statusCode]}];
                                                                     returnOnMainThread(^{
                                                                         [delegate authOnConnection:nil didFailWithError:error];
                                                                     });
                                                                 } else {
                                                                     error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                                                        code:AUTH_REQUEST_FAILED
                                                                                                    userInfo: @{NSLocalizedDescriptionKey:AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long)  statusCode]}];
                                                                     returnOnMainThread(^{
                                                                         [delegate authOnConnection:nil didFailWithError:error];
                                                                     });
                                                                 }
                                                             } else {
                                                                 error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                                                     code:AUTH_REQUEST_FAILED
                                                                                                 userInfo: @{NSLocalizedDescriptionKey:AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long)  statusCode]}];
                                                                 returnOnMainThread(^{
                                                                     [delegate authOnConnection:nil didFailWithError:error];
                                                                 });
                                                             }
                                                         } else {
                                                             
                                                             if (error) {
                                                                 error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                                                     code:AUTH_CONN_ERROR
                                                                                                 userInfo: @{NSLocalizedDescriptionKey:AUTH_CONN_ERROR_STRING}];
                                                                 returnOnMainThread(^{
                                                                     [delegate authOnConnection:nil didFailWithError:error];
                                                                 });
                                                             }
                                                             
                                                         }

                                                     }
                                                     
                                                     
                                                 }];
    
    [dataTask resume];

    return;
}

- (QCOAuth2Token*)executeAuthorizeCallWithRequest:(NSURLRequest*)request error:(NSError * *)error{
    QCOAuth2Token *oauthToken = nil;
    
    _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (bgTask == UIBackgroundTaskInvalid){
        [self startLongRunningTask];
    }

    @synchronized(self) {
        
        if (!_authInProgress) {
            _authInProgress = YES;
            _connFinished = NO;
            _connFailed = NO;
            _connError = nil;
            
            NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request
                                                        completionHandler:^(NSData *data,
                                                                            NSURLResponse *response,
                                                                            NSError *error) {
                                                            _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
                                                           _connResponse = (NSHTTPURLResponse *)response;

                                                            if (error) {
                                                                _connFailed = YES;
                                                                _connError = error;
                                                            } else {
                                                                _connFinished = YES;
                                                                _responseData = data;
                                                            }
                                                        }];
            
            [dataTask resume];
        }
        
        while (!_connFinished && !_connFailed) {
            @autoreleasepool {
                [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.5]];
            }
        }
        

        NSInteger statusCode = [_connResponse statusCode];
        if (_connFinished && _responseData && [_responseData length] > 0) {
            
            NSError *jsonError = nil;
            
            NSDictionary *jsonObject = nil;
            
            jsonObject = [JSONRPC resultFromJsonData:_responseData
                                             asClass:[QCOAuth2Token class] error:&jsonError];;
            
            if (statusCode == 200 && !jsonError && jsonObject && [jsonObject isKindOfClass:[QCOAuth2Token class]]) {
                oauthToken = (QCOAuth2Token*)jsonObject;
                
            } else if (error) {
                if (statusCode == 400 && jsonError) {
                    
                    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:_responseData options:0 error:nil];
                    if (jsonObject && [jsonObject[@"error"] isEqualToString:@"invalid_grant"]) {
                        if (jsonObject[@"error_description"] != nil) {
                            NSString *description = jsonObject[@"error_description"];
                            NSArray *components = [description componentsSeparatedByString:@"[ms]: "];
                            if (components.count > 1) {
                                NSInteger delay = [components.lastObject integerValue];
                                *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                    code:REFRESH_AUTH_REQUEST_FAILED
                                                                userInfo:@{@"delay": [NSString stringWithFormat:@"%ld", (long) delay]}];
                            } else {
                                *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                    code:REFRESH_AUTH_REQUEST_FAILED
                                                                userInfo:@{NSLocalizedDescriptionKey:REFRESH_AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long) statusCode]}];
                            }
                        } else {
                            *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                                code:REFRESH_AUTH_REQUEST_FAILED
                                                            userInfo:@{NSLocalizedDescriptionKey:REFRESH_AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long) statusCode]}];
                        }
                    }
                } else {
                    *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                        code:AUTH_REQUEST_FAILED
                                                    userInfo: @{NSLocalizedDescriptionKey:AUTH_REQUEST_FAILED_STRING, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"%ld", (long)  statusCode]}];
                }
            }
        } else {
            if (error) {
                if (_connError.code == NSURLErrorTimedOut) {
                    *error = [self hostUnreachableError];
                } else {
                    *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                        code:AUTH_CONN_ERROR
                                                    userInfo: @{NSLocalizedDescriptionKey:AUTH_CONN_ERROR_STRING}];
                }
            }
        }
        
        _authInProgress = NO;
    }
    
    return oauthToken;
}

#
# pragma mark Longrunning Task
#


- (BOOL)canStopBackgroundActivity{
    //are there open requests ?
    if (_queue.operationCount == 0) {
        
        if ([NSDate timeIntervalSinceReferenceDate] - _lastRequestFinishedTime > 5.0f) {
            return YES;
        } else {
            return NO;
        }
        
    }
    
    return NO;
}

- (void)startLongRunningTask {
#ifndef TARGET_IS_EXTENSION
    if (bgTask == UIBackgroundTaskInvalid) {
        // we cant user this code for NSExtensions
        UIApplication *application = [UIApplication sharedApplication];
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            // Clean up any unfinished task business by marking where you
            // stopped or ending the task outright.
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        [self performSelector:@selector(checkBackgroundActivity) withObject:nil afterDelay:0.25f];
    }
#endif
}

- (void)checkBackgroundActivity {
#ifndef TARGET_IS_EXTENSION
    if ([self canStopBackgroundActivity]) {
        [UIApplication.sharedApplication endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    } else {
        [self performSelector:@selector(checkBackgroundActivity) withObject:nil afterDelay:0.25f];
    }
#endif
}

#pragma mark - Private methods

- (NSError *)hostUnreachableError {
    NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{NSLocalizedDescriptionKey: QCErrorDomainAuth,
                                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"%ld", (long) NSURLErrorTimedOut]};
    NSError *error = [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                code:AUTH_REQUEST_TIME_OUT
                                            userInfo:userInfo];
    return error;
}

@end
