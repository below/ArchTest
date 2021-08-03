//
//  QCConnHelper.m
//  
//
//  Created by Michael on 16.12.15.
//
//

#import "QCConnHelper.h"
#import "QCRemoteMethod.h"
#import "JSONRPC.h"
#import "QCLogger.h"
#import "QCHTTPConnectionContext.h"
#import "QCErrors.h"
#import "QCConnHelperMethodCall.h"
#import "QCCertificateManager.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

/** Content type for HTTP requests */
NSString * const APPLICATION_JSON = @"application/json";

/** error message for wrong encoding. */
NSString * const WRONG_ENCODING = @"Wrong encoding";

/** Header field 'content-type' */
NSString * const CONTENT_TYPE = @"Content-Type";

/** For the Authorization Header */
NSString * const BEARER = @"Bearer";

@interface JSONErrorParser : NSObject

+ (NSError * _Nullable)errorFromJSON:(NSDictionary *)json;

@end

@implementation JSONErrorParser

+ (NSError * _Nullable)errorFromJSON:(NSDictionary *)json {
    
    NSDictionary *errorDict = [json objectForKey:@"error"];
    
    
    if ([errorDict isKindOfClass:[NSDictionary class]]) {
        
        if ([[errorDict objectForKey:@"error"] isKindOfClass:[NSString class]]) {
            
            if ([errorDict[@"error"] isEqualToString:@"invalid_token"]) {
                // there seems to be a problem with the access token. s
                return [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                  code:NOT_AUTHORIZED
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Access token seems to be invalid!" }];
            } else if ([errorDict[@"error"] isEqualToString:@"gateway_offline"]) {
                return [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                                  code:GATEWAY_OFFLINE
                                              userInfo:@{ NSLocalizedDescriptionKey: errorDict[@"error_description"] }];
            }
        }
        
        if (errorDict[@"code"]) {
            return [[NSError alloc] initWithDomain:QCErrorDomainAuth
                                              code:[errorDict[@"code"] integerValue]
                                          userInfo:@{ NSLocalizedDescriptionKey: @"Access token seems to be invalid!" }];
        }
    }
    
    return nil;
}

@end


@interface QCConnHelper(){
    //multitasking
    NSUInteger bgTask;
}

@property(nonatomic, readwrite, strong)NSOperationQueue *queue;
@property(nonatomic, readwrite, strong)NSURLSession *session;
@property(nonatomic, readwrite)NSTimeInterval lastRequestFinishedTime;
@property(nonatomic, strong) NSMutableDictionary *connectionLossRetryMap;
@end


@implementation QCConnHelper

static void runOnMainThread(void (^block)(void))
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
        self.session = session;
        self.connectionLossRetryMap = [NSMutableDictionary new];
    }
    return self;
}


- (id)callRPCWithClass:(id)classOfT url:(NSURL*)url authToken:(NSString *)authToken
                  gwID:(NSString *)gwID
               methods:(NSArray *)methods
      customIdentifier:(NSString*)customIdentifier
                 error:(NSError *__autoreleasing * )error
{
    
    NSError *localError = nil;
    
    QCConnHelperMethodCall *call = [self callRPCAsyncWithClass:classOfT
                                                           url:url
                                                     authToken:authToken
                                                          gwID:gwID
                                                       methods:methods
                                               contextDelegate:nil
                                            remoteCallDelegate:nil
                                              customIdentifier:customIdentifier
                                                         error:&localError];
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    } else {
        call.asyncCall = NO;
        
        while (!call.executed) {
            @autoreleasepool {
                [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.5]];
            }
        }

        if (call.error) {
            if (error) {
                *error = call.error;
            }
            return nil;
        }
    }
    return call.result;
}

- (void)callRPCAsyncWithURL:(NSURL *)url authToken:(NSString *)authToken gatewayID:(NSString *)gwID methods:(NSArray *)methods completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completion {

    QCConnHelperMethodCall *call = [self buildMethodCallWithURL:url authToken:authToken gatewayID:gwID andMethods:methods error:nil];
    
    [self execute:call.request completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        completion(result, error);
    }];
}

- (QCConnHelperMethodCall *)buildMethodCallWithURL:(NSURL *)url authToken:(NSString *)token gatewayID:(NSString *)gwID andMethods:(NSArray *)methods error:(NSError *__autoreleasing * )error {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    [self checkArgumentsAuthToken:token gwID:gwID methods:methods];
    [self requestHeaderWithAuthToken:token gwID:gwID request:request];
    
    NSMutableArray *methodArray = [NSMutableArray arrayWithCapacity:methods.count];
    
    for (QCRemoteMethod * method in methods) {
        NSDictionary *json = [JSONRPC methodDictionaryWithMethod:method];
        [methodArray addObject:json];
    }
    id jsonObject = methodArray;
    
    NSError *jsonError = nil;
    NSData *entity = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                     options:0
                                                       error:&jsonError];
    if (jsonError != nil) {
        [[QCLogger defaultLogger] warn:@"Wrong encoding"];
        if (error != nil)
            *error = jsonError;
        return nil;
    }
    [request setHTTPBody:entity];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)request.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    
    QCConnHelperMethodCall *call = [[QCConnHelperMethodCall alloc] init];
    QCRemoteMethod *firstMethod = [methods firstObject];
    NSNumber * methodId = [NSNumber numberWithInt:firstMethod.ID] ;
    
    call.request = request;
    call.methods = methods;
    call.requestID = methodId;
    call.gwID = gwID;
    call.asyncCall = YES;
    call.executed = NO;
    
    return call;
}

- (QCConnHelperMethodCall*)callRPCAsyncWithClass:(id)classOfT
                                             url:(NSURL*)url
                                       authToken:(NSString *)authToken
                                            gwID:(NSString *)gwID
                                         methods:(NSArray *)methods
                                 contextDelegate:(id<QCHTTPConnectionContextDelegate>)contextDelegate
                              remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
                                customIdentifier:(NSString*)customIdentifier
                                           error:(NSError *__autoreleasing * )error {
    
    QCConnHelperMethodCall *call = [self buildMethodCallWithURL:url authToken:authToken gatewayID:gwID andMethods:methods error:error];
    call.customIdentifier = customIdentifier;
    call.contextDelegate = contextDelegate;
    call.classOfT = classOfT;
    call.remoteCallDelegate = remoteCallDelegate;
    
    _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (bgTask == UIBackgroundTaskInvalid) {
        [self startLongRunningTask];
    }
    
    [self execute:call];
    
    return call;
}

- (void)execute:(QCConnHelperMethodCall *)call {
    
    [self execute:call.request decodingType:call.classOfT completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (call.asyncCall) {
            runOnMainThread(^{
                if (result) {
                    [self.connectionLossRetryMap removeObjectForKey:@(call.request.hash)];
                    
                    [call.contextDelegate callWithMethodId:call.requestID
                                        remoteCallDelegate:call.remoteCallDelegate
                                          customIdentifier:call.customIdentifier
                            didFinishLoadingWithJSONResult:result];
                    return;
                }
                
                // Retry on connection lost
                if (error && error.code == -1005) {
                    NSNumber *retry = self.connectionLossRetryMap[@(call.request.hash)];
                    
                    if (retry) {
                        NSUInteger retryCount = retry.integerValue;
                        
                        if (retryCount > 3) {
                            [self.connectionLossRetryMap removeObjectForKey:@(call.request.hash)];
                            
                            [call.contextDelegate callWithMethodId:call.requestID
                                                remoteCallDelegate:call.remoteCallDelegate
                                                  customIdentifier:call.customIdentifier
                                                  didFailWithError:error];
                            return;;
                        }
                        
                        retryCount += 1;
                        self.connectionLossRetryMap[@(call.request.hash)] = @(retryCount);
                    } else {
                        self.connectionLossRetryMap[@(call.request.hash)] = @(0);
                    }
                    
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [self execute:call];
                    });
                    return;
                }
                
                [call.contextDelegate callWithMethodId:call.requestID
                                    remoteCallDelegate:call.remoteCallDelegate
                                      customIdentifier:call.customIdentifier
                                      didFailWithError:error];
                
            });
        } else {
            if (result) {
                call.result = result;
            } else {
                call.error = error;
            }
        }
        call.executed = YES;
    }];
}

- (void)execute:(NSURLRequest *)request completionHandler:(void (^_Nullable)(id _Nullable, NSError * _Nullable))completion {
    [self execute:request decodingType:nil completionHandler:completion];
}

- (void)execute:(NSURLRequest *)request decodingType:(Class)classType completionHandler:(void (^_Nullable)(id _Nullable, NSError * _Nullable))completion {
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        _lastRequestFinishedTime = [NSDate timeIntervalSinceReferenceDate];
        
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [HTTPResponse statusCode];
        
        NSError *jsonError = nil;
        NSDictionary *jsonObject = nil;
        id result = nil;
        
        if (data) {
            result = [JSONRPC resultFromJsonData:data asClass:classType error:&jsonError];
        }
        
        if (statusCode == 200 && !error && !jsonError && result) {
            runOnMainThread(^{
                completion(result, nil);
            });
        } else {
            // handle errors
            
            NSError *errorFromJSON = nil;
            if (data) {
                jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&errorFromJSON];
            }
            
            NSError *responseError = errorFromJSON;
            if (error) {
                responseError = error;
            }
            
            if (!responseError) {
                if (jsonObject && [jsonObject isKindOfClass:[NSDictionary class]]) {
                    NSError *error = [JSONErrorParser errorFromJSON: jsonObject];
                    
                    if (error) {
                        responseError = error;
                    }
                }
            }
            
            if (!responseError) {
                responseError = [[NSError alloc] initWithDomain:QCErrorDomainConnector
                                                           code:statusCode
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Error in HTTP Request, status code = %ld", (long)statusCode]
                                                       }];
            }
            
            runOnMainThread(^{
                completion(nil, responseError);
            });
        }
    }];
    
    [dataTask resume];
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler{
  
    // Right now, perform default handling
completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);


}

#
# pragma marks private methods
#

NSString * deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

/**
 * Create the header of the HTTP POST request. The following steps are
 * performed:
 * <ul>
 * <li>content type is set to <code>application/json</code>
 * <li>the OAuth2 token will be added
 * <li>if the gateway id is specified it will be added to the header too
 * </ul>
 *
 * @param authToken
 *            authorization token or null
 * @param gwID
 *            gateway ID or null, if not necessary
 * @param req
 *            HTTP POST request
 * @return modified HTTP POST request
 * @throws ConnectorException
 *             if an error occurs
 */
- (NSMutableURLRequest *) requestHeaderWithAuthToken:(NSString *)authToken gwID:(NSString*)gwID
                                             request:(NSMutableURLRequest *)req {
    
    static NSString * agentString = nil;
    
    [req setValue:APPLICATION_JSON forHTTPHeaderField:CONTENT_TYPE];
    
    if (authToken.length != 0) {
        [req setValue:[NSString stringWithFormat:@"%@ %@", BEARER, authToken] forHTTPHeaderField:HEADER_AUTHORIZATION];
    }
    if (gwID.length != 0) {
        [req setValue:gwID forHTTPHeaderField:HEADER_QIVICON_SERVICE_GATEWAY_ID];
    }
    
    if (agentString == nil) {
        NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString * revision = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString * device = deviceName();
        NSString * os = [[UIDevice currentDevice] systemVersion];
        agentString = [NSString stringWithFormat:@"MSHM%@(%@)/%@/%@", appVersion, revision, device, os];
    }
    [req setValue:agentString forHTTPHeaderField:@"User-Agent"];
    return req;
}

/**
 * Check the arguments for null or emptiness. Throws an
 * <code>NSInvalidArgumentException</code> if there are any problems.
 *
 * @param authToken
 *            authorization token
 * @param gwID
 *            gateway ID or NULL, if not necessary
 * @param methods
 *            array of methods to call; cannot be null, must contain at
 *            least one element
 */
- (void) checkArgumentsAuthToken:(NSString *)authToken gwID:(NSString *)gwID methods:(NSArray *)methods {
    if (methods.count == 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"There must be at least one method specified!" userInfo:nil] raise];
    }
    if (authToken && [authToken rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Authentication token must not contain any whitespace characters!" userInfo:nil] raise];
    }
    if (gwID && [gwID rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Gateway id must not contain any whitespace characters!" userInfo:nil] raise];
    }
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

@end

