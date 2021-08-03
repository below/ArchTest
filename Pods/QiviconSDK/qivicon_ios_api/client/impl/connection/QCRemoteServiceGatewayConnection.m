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
//  QCRemoteServiceGatewayConnection.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 18.01.13.
//

#import "QCServiceGatewayConnection_private.h"
#import "QCRemoteServiceGatewayConnection.h"
#import "QCErrors.h"
#import "QCLogger.h"
#import "QCBackendConnection_private.h"
#import "QCPersistentTokenStorage.h"
#import "QCRemoteCertificateManager.h"
#import "QCConnHelper.h"
#import "QCResultElement.h"
#import "JSONRPC.h"
#import "QCOAuth2Token.h"
#import "JSONRPC.h"

@interface QCRemoteServiceGatewayConnection ()
@property (nonatomic) QCRemoteCertificateManager * sessionDelegate;
@property (nonatomic, strong) QCConnHelper *networkService;
@property (nonatomic, strong) NSString *clientAuthorization;
@end

@implementation QCRemoteServiceGatewayConnection

/**
 * Create a new Service Gateway connection with default connection
 * parameters. Token storage for the OAuth2 refresh token will be provided.
 *
 * @param globalSettings
 *            global settings which will be used to establish the
 *            connection
 * @param tokenStorage
 *            token storage provider to persist the refresh token
 * @param gwID
 *            serial number (id) of the Service Gateway.
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                        gwID:(NSString *)gwID
    localClientAuthorization:(NSString *)clientAuthorization {
 
    self = [self initWithGlobalSettings:globalSettings
                           tokenStorage:tokenStorage
                                   gwID:gwID];
    if (self) {
        self.clientAuthorization = clientAuthorization;
    }
    
    return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID
    localClientAuthorization:(NSString *)clientAuthorization {
 
    self = [self initWithGlobalSettings:globalSettings
                           tokenStorage:tokenStorage
                        sessionDelegate:delegate
                                   gwID:gwID];
    if (self) {
        self.clientAuthorization = clientAuthorization;        
    }
    
    return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID {
 
    self = [super initWithGlobalSettings:globalSettings
                            tokenStorage:tokenStorage
                         sessionDelegate:delegate
                                    gwID:gwID];
    
    if (self) {
        self.sessionDelegate = delegate;
        self.networkService = [[QCConnHelper alloc] initWithSession:self.session];
    }
    
    return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                        gwID:(NSString *)gwID {

    QCRemoteCertificateManager *manager = [[QCRemoteCertificateManager alloc] init];
    self = [self initWithGlobalSettings:globalSettings
                           tokenStorage:tokenStorage
                        sessionDelegate:manager
                                   gwID:gwID];
    self.networkService = [[QCConnHelper alloc] initWithSession:self.session];
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
    
    return[self callWithClass:classOfT
                          url:self.globalSettings.remoteAccessURL
                    authToken:self.accessToken
                         gwId:self.gwId
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
                                url:self.globalSettings.remoteAccessURL
                          authToken:self.accessToken
                               gwId:self.gwId
                            methods:methods
                   customIdentifier:customIdentifier
                    contextDelegate:self
                 remoteCallDelegate:delegate
                              error:error];
}

- (NSURL *) oAuthEndpoint {
    return self.globalSettings.oAuthEndpoint;
}

- (NSURL *) oAuthTokenEndpoint {
    return self.globalSettings.oAuthTokenEndpoint;
}
- (NSString*)webSocketUrl{
    return [[self.globalSettings webSocketURL] absoluteString];
}

- (ConnectionType) connectionType{
    return ConnectionType_Service_Gateway_Remote;
}

- (NSString *)refreshWithRefreshToken:(NSString *)refreshToken error:(NSError *__autoreleasing *)error {
    
    [super refreshWithRefreshToken:refreshToken error:error];
    
    NSString *token = self.accessToken;
    if (token) {
        [self getLocalTokenUsingRemoteAccessToken:token];
    }
}

- (void)authOnConnection:(QCAuthorizedConnection *)connection wasSuccessfulWithAuthToken:(QCOAuth2Token *)authToken {
    [super authOnConnection:connection wasSuccessfulWithAuthToken:authToken];
    
    [self getLocalTokenUsingRemoteAccessToken:authToken.access_token];
}

- (void)authorizeWithAuthCode:(NSString *)authCode error:(NSError *__autoreleasing *)error {
    [super authorizeWithAuthCode:authCode error:error];
    
    NSString *token = self.accessToken;
    if (token) {
        [self getLocalTokenUsingRemoteAccessToken:token];
    }
}

- (void)authorizeWithToken:(QCOAuth2Token *)authToken error:(NSError *__autoreleasing *)error {
    [super authorizeWithToken:authToken error:error];
    [self getLocalTokenUsingRemoteAccessToken:authToken.access_token];
}

#pragma mark - Private methods
- (void)getLocalTokenUsingRemoteAccessToken:(NSString *)remoteAccessToken {
    
    NSString *authorization = [NSString stringWithFormat: @"Basic %@", self.clientAuthorization];
    NSString *body = [NSString stringWithFormat:@"scope=QIVICON&grant_type=x_remote_authentication&client_id=%@", self.globalSettings.clientId];
    NSDictionary *params = @{
        @"method": @"POST",
        @"path": @"system/oauth/token",
        @"body": body,
        @"headers": @{
                  @"Authorization": authorization,
                  @"Content-Type": @"application/x-www-form-urlencoded"
                },
        @"options": @"confidential"
    };
    
    QCRemoteMethod *method = [[QCRemoteMethod alloc] initWithMethod:@"smarthome.rest/proxy" parameterArray:@[params]];

    [self.networkService callRPCAsyncWithURL:self.globalSettings.remoteAccessURL
                                   authToken:remoteAccessToken
                                   gatewayID:self.gwId
                                     methods:@[method]
                           completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                 
        if (!result) {
            return;
        }
                
        NSDictionary *json = ((QCResultElement *)[(NSArray *)result firstObject]).result;
        
        if (!json) {
            return;
        }
        
        NSData *data = [(NSString *)json[@"Body"] dataUsingEncoding:NSUTF8StringEncoding];
        
        if (data) {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if (json) {
                [self getLocalTokenFromJSON:json];
                [self getIpAddressFromJSON:json];
            }
        }

    }];
}

- (void)getLocalTokenFromJSON:(NSDictionary *)json {
    NSString *acccess_token = json[@"access_token"];
    NSString *refresh_token = json[@"refresh_token"];
    NSString *scope = json[@"scope"];
    NSString *type = json[@"token_type"];
    double time = [[json objectForKey:@"expires_in"] doubleValue];

    if (acccess_token && refresh_token && scope && type) {
        QCOAuth2Token *token = [[QCOAuth2Token alloc] initWithAccessToken:acccess_token
                                                                tokenType:type
                                                               expireTime:time
                                                             refreshToken:refresh_token
                                                                    scope:scope];
        [token setExpires_in:time];
        [self.tokenStorage storeOAuthToken:token forID:self.gwId];
    }
}

- (void)getIpAddressFromJSON:(NSDictionary *)json {
    NSString *ip = json[@"x_ipv4"];
    
    if (ip) {
        [self.tokenStorage storeLocalIP:ip];
    }
}

@end
