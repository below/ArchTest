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
//  QCLocalServiceGatewayConnection.m
//  qivicon_ios_api
//
//  Created by m.fischer on 18.01.13.
//


// the time how long we want to wait to receive the answer for the system info call
#define localTimeOutInterval 10.0f

#import "QCLogger.h"
#import "QCErrors.h"
#import "QCServiceGatewayConnection_private.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCRemoteMethod.h"
#import "QCURLConnection.h"
#import "JSONRPC.h"
#import "QCUtils.h"

@interface QCLocalServiceGatewayConnection () {
}
@property (readwrite) NSURL *baseUrl;
@property (readwrite) NSURL *oauthAuthorizeUrl;
@property (readwrite) NSURL *oauthTokenUrl;
@property (readwrite) NSString *addr;
@property (nonatomic, readwrite) NSString *friendlyName;
@property (readwrite) NSString *authCode;
@property (nonatomic, readwrite) GatewayType gatewayType;
@property (nonatomic, readwrite) QCCertificateManager*  sessionDelegate;
@property (nonatomic, strong) QCOAuth2Token *localOAuthToken;
@end

/**
 * Connection to a locally connected <i>Service Gateway</i>. Local connections
 * contain an IP address of the connected Service Gateway and an URL to connect to
 * this Service Gateway.
 */
@implementation QCLocalServiceGatewayConnection

- (NSString *) friendlyName {
    return _friendlyName;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id <QCPersistentTokenStorage, QCCertificateStorageDelegate>)tokenStorage
                        GWID:(NSString *)gwID
                     address:(NSString*)address
                        name:(NSString*)name {
    if (!address) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"no address" userInfo:nil] raise];
    }
    
    QCCertificateManager *manager = [[QCCertificateManager alloc] initWithGwID:gwID];
    manager.certificateStorage = tokenStorage;
    
    QCOAuth2Token *token = [tokenStorage oAuthTokenForID:gwID];
    
    if (token) {
        self.localOAuthToken = token;
        
        self = [self initWithGlobalSettings:globalSettings
                               tokenStorage:tokenStorage
                            sessionDelegate:manager
                                       gwID:gwID
                                      token:token];
    } else {
        self = [self initWithGlobalSettings:globalSettings
                               tokenStorage:tokenStorage
                            sessionDelegate:manager
                                       gwID:gwID];
    }
    
    if (self) {
        self.sessionDelegate = manager;
        address = [address stringByFormattingForIPv6];
        self.addr = address;
        self.friendlyName = name;
        NSString *scheme = HTTPS_PROTOCOL;
        int port = HTTPS_PORT;
        
        NSString *host = [address stringByAppendingFormat:@":%i", port];
        self.baseUrl = [[NSURL alloc] initWithScheme:scheme host:host path:@"/"];
        self.url = [NSURL URLWithString:RPC_URL relativeToURL:self.baseUrl];

        self.oauthAuthorizeUrl = [NSURL URLWithString:OAUTH_AUTHORIZE_ENDPOINT
                                        relativeToURL:self.baseUrl];
        self.oauthTokenUrl = [NSURL URLWithString:OAUTH_TOKEN_ENDPOINT
                                    relativeToURL:self.baseUrl];
        
        _gatewayType = GatewayType_Unknown;
        
    }
    return self;
}

-(BOOL)isAuthorized {
    if (self.localOAuthToken) {
        return [self.localOAuthToken isAuthorized];
    }
    return [super isAuthorized];
}

- (BOOL)isAccessTokenRefreshNeeded {
    if (self.localOAuthToken) {
        return [self.localOAuthToken isAccessTokenRefreshNeeded];
    }
    return [super isAccessTokenRefreshNeeded];    
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
                          url:self.url
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
                                url:self.url
                          authToken:self.accessToken
                               gwId:self.gwId
                            methods:methods
                   customIdentifier:customIdentifier
                    contextDelegate:self
                 remoteCallDelegate:delegate
                              error:error];
}

/**
 * Retrieves Gateway Info and returns the type of the <i>GatewayType</i>
 *
 * @return the Service Gateway type or default value if gateway type can not be retrieved
 */

- (GatewayType) gatewayType {
    
    if (_gatewayType == GatewayType_Unknown) {
        
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSURL *url = [NSURL URLWithString:SYSTEM_INFO_ENDPOINT relativeToURL:self.baseUrl];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:localTimeOutInterval];
        NSData *data = [QCURLConnection sendSynchronousRequest:request usingSession:self.session returningResponse:&response error:&error];
        
        _gatewayType = GatewayType_Simulator;
        if (!error) {
            
            if (data) {
                NSError *jsonError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:&jsonError];
                if (jsonError) {
                    return _gatewayType;
                }
                
                NSDictionary *json = (NSDictionary *)jsonObject;
                
                if (json) {
                    NSString *type = json[@"type"] ? json[@"type"] : @"";
                    
                    if ([type caseInsensitiveCompare:@"qhb1"] == NSOrderedSame) {
                        _gatewayType = GatewayType_QHB1;
                    } else if ([type caseInsensitiveCompare:@"qhb2"] == NSOrderedSame) {
                        _gatewayType = GatewayType_QHB2;
                    } else if ([type caseInsensitiveCompare:@"embedded_qhb"] == NSOrderedSame ||
                               [type caseInsensitiveCompare:@"embeddedqhb"] == NSOrderedSame) {
                        _gatewayType = GatewayType_Embedded_QHB;
                    } else {
                        _gatewayType = GatewayType_Simulator;
                    }
                }
            }
        }
    }
    return _gatewayType;
}


- (NSURL*) oAuthEndpoint {
    return _oauthAuthorizeUrl;
}

- (NSURL *) oAuthTokenEndpoint {
    return _oauthTokenUrl;
}

- (NSString*)webSocketUrl{
    NSString *protocol = WSS_PROTOCOL;
    int port = [self wssPort];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%i%@", protocol, self.addr, port, WS_URL];
    
    return urlString;
}

- (ConnectionType) connectionType{
    return ConnectionType_Service_Gateway_Local;
}

- (NSString *) gatewayId {
    return self.gwId;
}

- (QCOAuth2Token *) refreshTokenForEndpoint:(NSURL *)url postParams:(NSDictionary *)postParams error:(NSError **)error {
    return [self tokenFromOAuthProvider:url
                         withPostParams:postParams
                                  error:error];
}
    
- (void) refreshTokenForEndpoint:(NSURL *)url postParams:(NSDictionary *)postParams delegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError **)error {
    [self tokenFromOAuthProvider:url
                  withPostParams:postParams
                        delegate:delegate
                           error:error];
}

- (int)wssPort {
    switch (self.gatewayType) {
        case GatewayType_QHB1:
        case GatewayType_Simulator:
        case GatewayType_Unknown:
            return WSS_PORT;

        case GatewayType_Embedded_QHB:
        case GatewayType_QHB2:
            return HTTPS_PORT;
    }
}

@end
