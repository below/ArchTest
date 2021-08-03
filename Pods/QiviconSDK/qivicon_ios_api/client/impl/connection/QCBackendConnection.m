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
//  QCBackendConnection.m
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 10.01.13.
//

#import "QCBackendConnection_private.h"
#import "QCErrors.h"
#import "QCLogger.h"
#import "QCRemoteMethod.h"
#import "QCPersistentTokenStorage.h"
#import "QCResultElement.h"
#import "QCUtils.h"

@interface QCBackendConnection ()
@property (atomic) BOOL attemptedReAuth;
@property (atomic) BOOL requestFinished;
@property (atomic) NSError *connectionError;
@property id result;
@property NSError *error;
@property(nonatomic, readwrite, strong)NSOperationQueue *queue;
@property(nonatomic, readwrite, strong)NSURLSession *session;
@end

@implementation QCBackendConnection {
}

/**
 * Initializes a connection with connection parameters defined in
 * {@link com.qivicon.client.GlobalSettings}. Token storage will be
 * provided.
 *
 * @param globalSettings
 *            global settings which will be used to establish the
 *            connection
 * @param tokenStorage
 *            token storage provider to persist the refresh token
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate{
    
    self = [super initWithGlobalSettings:globalSettings tokenStorage:tokenStorage sessionDelegate:delegate];
    return self;
}

- (id) callWithReturnClass:(Class)classOfT methods:(NSArray *)methods error:(NSError * __autoreleasing *)error {
    if (!self.isAuthorized) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return nil;
    }
    
    if (![self refreshAccessTokenIfNeededWithError:error]) {
        return nil;
    }
    
    return [self callWithClass:classOfT
                           url:self.globalSettings.backendURL
                     authToken:self.accessToken
                          gwId:nil
                       methods:methods
                         error:error];
}

- (BOOL) callAsyncWithReturnClass:(Class)classOfT methods:(NSArray *)methods
                         delegate:(id <QCConnectionDelegate>)delegate
                 customIdentifier:(NSString*)customIdentifier
                            error:(NSError * __autoreleasing *)error {
    if (!self.isAuthorized) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return false;
    }
    
    if (![self refreshAccessTokenIfNeededWithError:error]) {
        return false;
    }

    return [self callAsyncWithClass:classOfT
                                url:self.globalSettings.backendURL
                          authToken:self.accessToken
                               gwId:nil
                            methods:methods
                   customIdentifier:customIdentifier
                    contextDelegate:self
                 remoteCallDelegate:delegate
                              error:error];
}

- (NSArray*)userGatewaysWithError:(NSError * __autoreleasing *)error{
    NSURL *backendURL = [self.globalSettings.backendGatewayIdURL URLByAppendingPathComponent:@"/services/homebase/ids"];
    NSError *gatewayError = nil;
    NSArray *gatewayIDs = [self userGatewaysWithURL:backendURL error:&gatewayError];
    
    if (gatewayError) {
        gatewayError = nil;
        backendURL = [self.globalSettings.qiviconBackendURL URLByAppendingPathComponent:@"/services/homebase/ids"];
        gatewayIDs = [self userGatewaysWithURL:backendURL error:&gatewayError];
    }
    *error = gatewayError;
    
    return gatewayIDs;
}

- (NSArray*)userGatewaysWithURL:(NSURL *)url error:(NSError * __autoreleasing *)error {
    if (!self.isAuthorized) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return nil;
    }
    
    if (![self refreshAccessTokenIfNeededWithError:error]) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return nil;
    }
    
    __block BOOL callFinished = NO;
    __block NSArray* gatewayIDs;
    __block NSError* callError;
    
    NSURL *gatewaysURL = url;
    NSString *accessToken = self.accessToken;
    
    if (gatewaysURL && accessToken) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:gatewaysURL];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSString *authorizationValue = nil;
        if (accessToken) {
            authorizationValue = [@"Bearer " stringByAppendingString:accessToken];
        }
        [request setValue:authorizationValue forHTTPHeaderField:@"Authorization"];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [HTTPResponse statusCode];
            
            NSMutableArray *avaiableGateways;
            
            if (!error && statusCode == 200) {
                if (data && [data length] > 0){
                    NSError *e = nil;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &e];
                    
                    if (!e && jsonDict && [jsonDict isKindOfClass:[NSArray class]]){
                        NSArray *gateways = (NSArray*)jsonDict;
                        for (NSDictionary *gateway in gateways) {
                            
                            if ([gateway isKindOfClass:[NSDictionary class]] && gateway[@"homebaseSerial"] && gateway[@"homebaseSerial"]) {
                                NSString *gwid = [gateway[@"homebaseSerial"] isKindOfClass:[NSNumber class]] ? [gateway[@"homebaseSerial"] stringValue] : gateway[@"homebaseSerial"];
                                if (gwid.length > 0) {
                                    if (!avaiableGateways) {
                                        avaiableGateways = [NSMutableArray new];
                                    }
                                    [avaiableGateways addObject:gwid];
                                }
                            }
                            
                        }
                        if (avaiableGateways) {
                            gatewayIDs = [NSArray arrayWithArray:avaiableGateways];
                        }
                    } else {
                        callError = e;
                    }
                }
            } else {
                if (error == nil) {
                    NSDictionary *info = @{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Error in HTTP Request, status code = %ld", (long)statusCode]};
                    error = [[NSError alloc] initWithDomain:QCErrorDomainConnector
                                                       code:statusCode
                                                   userInfo: info];
                }
                
                callError = error;
            }
            
            callFinished = YES;
        }];
        
        [dataTask resume];
        
    } else {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return nil;
    }
    while (!callFinished) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.5]];
        }
    }
    
    if (callError != nil) {
        if (error != nil) {
            *error = callError;
        }
        return nil;
    }
    
    return gatewayIDs;
}

- (NSString*) userGatewayAddressForGwId:(NSString*)gwId error:(NSError * __autoreleasing *)error {
    
    if (!self.isAuthorized) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                     userInfo:@{NSLocalizedDescriptionKey: NOT_AUTHORIZED_MESSAGE}];
        }
        return nil;
    }
    
    if (![self refreshAccessTokenIfNeededWithError:error]) {
        return nil;
    }
    
    NSError *localError;
    NSArray * result = [self callWithClass:nil
                                       url:self.globalSettings.backendURL
                                 authToken:self.accessToken
                                      gwId:gwId
                                   methods:@[[QCRemoteMethod remoteMethodWithName:@"ch_usergateways/getGatewayAddress"]]
                                     error:&localError];
    
    
    
    if (localError != nil) {
        if (error != nil) {
            *error = localError;
        }
        return nil;
    }
    
    QCResultElement *resultElement = [result firstObject];
    NSString * resultAddress = nil;
    if ([resultElement.result objectForKey:@"IpAddress"]) {
        resultAddress = [resultElement.result  objectForKey:@"IpAddress"];
    }
    
    return [resultAddress stringByFormattingForIPv6] ;
}

- (ConnectionType) connectionType{
    return ConnectionType_Backend;
}

- (NSURL *) oAuthEndpoint {
    return self.globalSettings.oAuthEndpoint;
}

- (NSURL *) oAuthTokenEndpoint {
    return self.globalSettings.oAuthTokenEndpoint;
}

@end
