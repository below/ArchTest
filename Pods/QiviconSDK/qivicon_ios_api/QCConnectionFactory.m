
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
//  QCConnectionFactory.m
//  qivicon_ios_api
//
//  Created by m.fischer on 06.02.13.
//

#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCConnectionFactory.h"
#import "QCGlobalSettings.h"
#import "QCServiceGatewayConnection.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCRemoteServiceGatewayConnection.h"
#import "QCBackendConnection.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCLongPolling.h"
#import "QCErrors.h"
#import "QCDiscoveryService.h"
#import "QCGatewayDiscovery.h"
#import "QCWebSocket.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCHTTPConnectionContextFactory.h"
#import "QCHTTPClientConnectionContextFactory.h"
#import "QCWebSocketConnectionFactory.h"
#import "QCPersistentTokenStorage.h"
#import "QCServiceGatewayConnection_private.h"
#import "QCSystemPropertiesGlobalSettingsProvider.h"
#import "QCLogger.h"
#import "QCRemoteCertificateManager.h"
#import "QCCertificateManager.h"

@interface QCConnectionFactory()

@property (nonatomic,readwrite) QCGlobalSettings* remoteConnectionSettings;
@property (nonatomic,readwrite) QCGlobalSettings* localConnectionSettings;
@property (nonatomic,readwrite) id<QCDiscoveryService> discoveryService;
@property (nonatomic,readwrite) QCGatewayDiscovery* discovery;
@property (nonatomic,readwrite) id<QCHTTPConnectionContextFactory> connectionContextFactory;
@property (nonatomic,readwrite) QCWebSocketConnectionFactory* webSocketConnectionFactory;
@end

@implementation QCConnectionFactory

- (id)init {
    return [self initWithGlobalSettingsProvider:[QCSystemPropertiesGlobalSettingsProvider new]];
    
}

- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)gsp {
    return [self initWithGlobalSettingsProvider:gsp
                                   tokenStorage:nil];
}

- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)gsp
                        tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage {
    return [self initWithGlobalSettingsProvider:gsp
                       connectionContextFactory:[QCHTTPClientConnectionContextFactory new]
                               discoveryService:[QCGatewayDiscovery discoveryWithType:UPNP_DISCOVERY]
                     webSocketConnectionFactory:[QCWebSocketConnectionFactory new]
                                   tokenStorage:tokenStorage];
}

// Designated initializer
- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)gsp
            connectionContextFactory:(id<QCHTTPConnectionContextFactory>)connectionContextFactory
                    discoveryService:(id<QCDiscoveryService>) discoveryService
          webSocketConnectionFactory:(QCWebSocketConnectionFactory*) webSocketConnectionFactory
                        tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage {
    if (!connectionContextFactory) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"connection context factory must not be null!"
                               userInfo:nil] raise];
    }
    
    if (!discoveryService) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"discovery service must not be null!"
                               userInfo:nil] raise];
    }
    
    self = [super init];
    
    if (self) {
        _globalSettingsProvider = gsp;
        self.remoteConnectionSettings = gsp.remoteConnectionSettings;
        self.localConnectionSettings = gsp.localConnectionSettings;
        
        self.connectionContextFactory = connectionContextFactory;
        self.webSocketConnectionFactory = webSocketConnectionFactory;
        self.discoveryService =  discoveryService;
        self.tokenStorage =  tokenStorage;
    }
    
    return self;
}

- (void) setGlobalSettingsProvider:(id<QCGlobalSettingsProvider>)globalSettingsProvider {
    if (globalSettingsProvider == nil)
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Provider must not be nil!"
                               userInfo:nil] raise];
    self.remoteConnectionSettings = globalSettingsProvider.remoteConnectionSettings;
    self.localConnectionSettings = globalSettingsProvider.localConnectionSettings;
}

- (QCLocalServiceGatewayConnection *) findLocalGatewayConnectionWithGatewayId:(NSString *)gwID
                                                                        error:(NSError **)error {
    @synchronized(self) {
        
        if (gwID.length == 0) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Service Gateway ID must not be null!"
                                   userInfo:nil] raise];
        }
        
        if (self.discovery == nil) {
            [[QCLogger defaultLogger] debug:@"Initialize local discovery"];
            self.discovery = [[QCGatewayDiscovery alloc] initWithDiscoveryService:self.discoveryService];
        }
        
        return [self.discovery connectionWithGlobalSettings:self.localConnectionSettings
                                               tokenStorage:self.tokenStorage
                                                  gatewayId:gwID
                                                      error:error];
    }
}

- (QCLocalServiceGatewayConnection*) localGatewayConnectionWithAddress:(NSString*)address gatewayId:(NSString*)gwID {
    @synchronized(self) {
        if (address.length == 0) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"IP Address must not be null!"
                                   userInfo:nil] raise];
        }
        if (gwID.length == 0) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Service Gateway ID must not be null!"
                                   userInfo:nil] raise];
        }
        
        return [[QCLocalServiceGatewayConnection alloc] initWithGlobalSettings:self.localConnectionSettings
                                                                  tokenStorage:self.tokenStorage
                                                                          GWID:gwID
                                                                       address:address
                                                                          name:gwID];
    }
}

- (NSArray*)discoverLocalGatewayIDsWithError:(NSError * __autoreleasing *)error{
    return [self discoverLocalGatewayIDsForceRefresh:YES error:error];
}

- (NSArray*)discoverLocalGatewayIDsForceRefresh:(BOOL)forceRefresh error:(NSError **)error{
    @synchronized(self) {
        self.discovery = [[QCGatewayDiscovery alloc] initWithDiscoveryService:self.discoveryService];
    }
    NSDictionary *allConnections = [self.discovery allConnectionsWithGlobalSettings:self.localConnectionSettings
                                                                       tokenStorage:self.tokenStorage
                                                                           delegate:nil
                                                                       forceRefresh:forceRefresh];
    return [allConnections allKeys];
}

- (QCServiceGatewayConnection*)remoteGatewayConnectionWithGWID:(NSString*)gwID error:(NSError **)error{
    if (gwID.length == 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Service Gateway ID must not be null or empty!"
                               userInfo:nil] raise];
        return nil;
    }

    return [[QCRemoteServiceGatewayConnection alloc] initWithGlobalSettings:self.remoteConnectionSettings
                                                               tokenStorage:self.tokenStorage
                                                                       gwID:gwID
                                                   localClientAuthorization:self.localConnectionSettings.clientAuthorization];
}

- (QCBackendConnection*) backendConnection {
    return [[QCBackendConnection alloc] initWithGlobalSettings:self.remoteConnectionSettings
                                                  tokenStorage:self.tokenStorage
                                               sessionDelegate:nil];
}

- (id<QCServiceGatewayEventConnection>)gatewayEventConnectionWithConnection:(QCServiceGatewayConnection*)conn pushMethod:(PushMethod)pushMethod {
    
    if (!conn) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Service Gateway connection must not be null"
                               userInfo:nil] raise];
        return nil;
    }

    return [[QCServiceGatewayEventConnection alloc] initWithGlobalSettings:self.remoteConnectionSettings
                                                webSocketConnectionFactory:self.webSocketConnectionFactory
                                                                connection:conn
                                                              websocketURL:conn.webSocketUrl
                                                                pushMethod:pushMethod];
}

- (id<QCServiceGatewayEventConnection>)gatewayEventConnectionWithConnection:(QCServiceGatewayConnection*)conn {
    return [self gatewayEventConnectionWithConnection:conn
                                           pushMethod:PushMethod_All];
}

@end
