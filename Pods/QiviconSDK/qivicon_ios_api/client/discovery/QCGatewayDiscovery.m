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
//  QCGatewayDiscovery.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 07.02.13.
//

#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCGatewayDiscovery.h"
#import "QCDiscoveryService.h"
#import "QCUpnpDiscoveryService.h"
#import "QCLogger.h"
#import "QCServiceGatewayConnection_private.h"
#import "QCErrors.h"

@interface QCGatewayDiscovery ()

@property (readonly) NSDictionary *connections;

@property (strong) id <QCDiscoveryService> discoveryService;

@end

/**
 * Searches for locally connected <i>Service Gateways</i>. A <i>Service Gateway</i> is
 * normally registered in DNS as "qivicon.ip".
 * <p>
 * Currently this class uses only UPnP-discovery.
 */
@implementation QCGatewayDiscovery {
    /**
     * List of local Service Gateway connections. Key: serial number (id) of the
     * connected Service Gateway.
     */
    NSMutableDictionary *_connections;
    
}

@synthesize connections = _connections;

- (void) addConnection:(QCLocalServiceGatewayConnection *)conn {
    if (_connections == nil)
        _connections = [NSMutableDictionary new];
    [_connections setValue:conn forKey:conn.gwId];
}

/**
 * Creates a discovery service according the given type.
 *
 * @param discoveryType
 *            type of discovery service. Currently only
 *            {@link DiscoveryType#UPNP_DISCOVERY} is supported
 * @param gbl
 *            global settings object
 * @return instance of discovery service
 */
+ (id <QCDiscoveryService>) discoveryWithType:(int)discoveryType {
    /*
     * FIXME: the reference to UpnpDiscoveryService creates a circular
     * dependency between this classes's package and the impl package.
     */
    switch (discoveryType) {
        case UPNP_DISCOVERY:
            return [[QCUpnpDiscoveryService alloc] init];
        default:
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Wrong discovery type"
                                   userInfo:nil] raise];
            return nil;
    }
}

/**
 * Create the discovery factory.
 *
 * @param service
 *            UPnPDiscoverService
 */
- (id) initWithDiscoveryService:(id <QCDiscoveryService>)service {
    if (( self = [super init])) {
        _connections = [NSMutableDictionary new];
        self.discoveryService = service;
    }
    return self;
}

/**
 * Refreshes the list of managed local connections using the
 * DiscoveryService. Currently only UPnP is supported.
 *
 * @param delegate
 *            delegate to be called on each device found or null
 * @see DiscoveryService
 */
- (void) refreshConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                    tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                        delegate:(id <QCDiscoveryDelegate>) delegate {
    [[QCLogger defaultLogger] debug:@"Looking up using UPnPDiscoveryService"];
    
    NSArray *localConnections = [self.discoveryService lookupWithGlobalSettings:globalSettings
                                                                   tokenStorage:tokenStorage
                                                                        timeout:TIMEOUT
                                                                       delegate:delegate
                                                                          error:nil];
    _connections = [NSMutableDictionary new];
    if (localConnections == nil) {
        [[QCLogger defaultLogger] warn:@"Nothing found!"];
    }
    else {
        for (QCLocalServiceGatewayConnection *l in localConnections) {
            [self addConnection:l];
        }
    }
}

/**
 * Get the connection to the specified Service Gateway id. If it has been already
 * looked up, it is returned immediately. Otherwise a discovery for gthat
 * specific connection is done.
 *
 * @param globalSettings
 *            global settings context to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 
 * @param gwId
 *            gateway id
 * @return LocalConnection or null
 * @throws DiscoveryException
 *             if Service Gateway cannot be found
 */
- (QCLocalServiceGatewayConnection *) connectionWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                                      tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                                         gatewayId:(NSString *) gwId
                                                             error:(NSError **)error {
    QCLocalServiceGatewayConnection *conn = nil;
    
    if (conn == nil) {
        // lookup this specific connection
        conn = [self.discoveryService lookupWithGlobalSettings:globalSettings
                                                     tokenStorage:tokenStorage
                                                 deviceIdentifier:gwId
                                                            error:nil];
        if (conn == nil) {
            [[QCLogger defaultLogger] error:@"Service Gateway %@ not found.", gwId];
            if (error)
                *error = [[NSError alloc] initWithDomain:QCErrorDomainConnector
                                                    code:GATEWAYID_NOT_FOUND
                                                userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Service Gateway %@ not found.", gwId]}];
        } else
            [self addConnection:conn];
    }
    return conn;
}

/**
 * Get a map of all connections. If there are no connections cached
 * yet, a {@link #refreshConnectionsWithPersistenTokenStorage:delegate} is done. If there
 * is at least one connection cached, a refresh will not be performed.
 *
 * @param connectionContext
 *            connection context to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param delegate
 *            delegate to be called on each device found or null
 * @param forceRefresh
 *            a refresh is enforced
 * @return all connections
 */

- (NSDictionary *) allConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                       tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                           delegate:(id<QCDiscoveryDelegate>)delegate
                                       forceRefresh:(BOOL)forceRefresh {
    if (forceRefresh || self.connections.count == 0) {
        // first refresh
        [self refreshConnectionsWithGlobalSettings:globalSettings
                                      tokenStorage:tokenStorage
                                          delegate:delegate];
    }
    return self.connections;
}

/**
 * Get a map of all connections. If there are no connections cached
 * yet, a {@link #refreshConnectionsWithPersistenTokenStorage:delegate} is done. If there
 * is at least one connection cached, a refresh will not be performed.
 *
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param delegate
 *            delegate to be called on each device found or null
 * @return all connections
 */
- (NSDictionary *) allConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                       tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                           delegate:(id<QCDiscoveryDelegate>)delegate {
    
    return [self allConnectionsWithGlobalSettings:globalSettings
                                     tokenStorage:tokenStorage
                                         delegate:delegate
                                     forceRefresh:NO];
}

/**
 * Get a map of all connections.
 *
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param forceRefresh
 *            a refresh is enforced
 * @return all connections
 */
- (NSDictionary *) allConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                       tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                       forceRefresh:(BOOL)forceRefresh {
    
    return [self allConnectionsWithGlobalSettings:globalSettings
                                     tokenStorage:tokenStorage
                                         delegate:nil
                                     forceRefresh:forceRefresh];
}
@end
