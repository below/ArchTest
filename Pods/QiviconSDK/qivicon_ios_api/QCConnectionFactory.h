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

#import <Foundation/Foundation.h>
#import "QCGlobalSettings.h"
#import "QCServiceGatewayConnection.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCBackendConnection.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCGlobalSettingsProvider.h"

@protocol QCPersistentTokenStorage;
@protocol QCDiscoveryService;
@protocol QCHTTPConnectionContextFactory;

/**
 * This connection factory is used to create the specific connections:
 * <ul>
 * <li>{@link QCBackendConnection}
 * <li>{@link QCServiceGatewayConnection}
 * <ul>
 * <li>local connections - methods are provided to find local connections either
 * with or without discovery.
 * <li>remote connections
 * </ul>
 * </ul>
 * The returned connections are <strong>not</strong> authorized. <strong>This
 * behavior has been changed compared to the previous release!</strong>
 */
@interface QCConnectionFactory : NSObject

/**
 * Initialize connection factory with default global settings.
 */
- (id) init;

/**
 * Initialize connection factory with a specific
 * {@link QCGlobalSettingsProvider}.
 *
 * @param globalSettingsProvider
 *            {@link QCGlobalSettingsProvider} which is used to create the
 *            {@link QCGlobalSettings}.
 */
- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)globalSettingsProvider;

/**
 * Initialize connection factory with a specific
 * {@link QCGlobalSettingsProvider} and
 * {@link QCPersistentTokenStorage}
 *
 * @param globalSettingsProvider
 *            {@link QCGlobalSettingsProvider} which is used to create the
 *            {@link QCGlobalSettings}.
 * @param tokenStorage
 *            {@link QCPersistentTokenStorage} used to persist OAuth2 refresh
 *            tokens used for all connections; may be null
 */
- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)globalSettingsProvider
                        tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage;
/**
 * Initialize connection factory with a specific
 * {@link QCGlobalSettingsProvider}, a specific
 * <i>QCHttpConnectionContextFactory</i> and a specific
 * <i>QCDiscoveryService</i>.
 *
 * @param globalSettingsProvider
 *            {@link QCGlobalSettingsProvider} which is used to create the
 *            {@link QCGlobalSettings}.
 * @param connectionContextFactory
 *            <i>QCHttpConnectionContextFactory</i> which is used to create
 *            the  <i>QCHttpConnectionContext</i>.
 * @param discoveryService
 *            <i>QCDiscoveryService</i> which is used for gateway discovery
 * @param webSocketConnectionFactory
 *            <i>QCWebSocketConnectionFactory</i> to create web socket
 *            connections; may be null
 * @param tokenStorage
 *            {@link QCPersistentTokenStorage} used to persist OAuth2 refresh
 *            tokens used for all connections; may be null
 */
- (id)initWithGlobalSettingsProvider:(id <QCGlobalSettingsProvider>)globalSettingsProvider
    connectionContextFactory:(id<QCHTTPConnectionContextFactory>)connectionContextFactory
            discoveryService:(id<QCDiscoveryService>) discoveryService
  webSocketConnectionFactory:(QCWebSocketConnectionFactory*) webSocketConnectionFactory
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage;

/**
 * Set a new global settings provider.
 *
 * @param globalSettingsProvider
 *            new provider; must not be nil
 */
@property (nonatomic,readwrite,assign) id <QCGlobalSettingsProvider> globalSettingsProvider;

/**
 * Set a new persistent storage provider.
 *
 * @param tokenStorage
 *            new provider; may be null
 */
@property (nonatomic,readwrite,strong)id<QCPersistentTokenStorage> tokenStorage;

/**
 * A discovery in the local network is performed to find a given <i>Service
 * Gateway</i>. In Case of success a {@link QCLocalServiceGatewayConnection}
 * will be established and returned. If not, error will be set *
 * @param gwID
 *            id (serial number) of Service Gateway
 * @param error
 *          Contains error if appropirate, can be nil
 * @return {@link QCLocalServiceGatewayConnection}
 * @throws DiscoveryException
 *             if a gateway with the given id cannot be found
 */
- (QCLocalServiceGatewayConnection *) findLocalGatewayConnectionWithGatewayId:(NSString *)gwID
                                                                        error:(NSError **)error;


/**
 * Returns a local connection to the user's <i>Service Gateway</i>. No
 * discovery of local Service Gateways is made.
 * <p>
 * This method does <strong>ONLY</strong> use HTTPS connections!
 * <p>
 * Without discovery it cannot be verified, whether the serial number or the
 * given name match with the corresponding number or name of the Service
 * Gateway. Therefore this call could be used also to connect to QIVICON
 * emulators.
 * <p>
 * It is not verified, if the IP address is correct and reachable!
 * <p>
 * Service Gateway ID and Service Gateway name are set to
 * the textual IP address.
 *
 * @param address
 *            IP address of the Service Gateway
 * @return {@link QCLocalServiceGatewayConnection}
 */
- (QCLocalServiceGatewayConnection*) localGatewayConnectionWithAddress:(NSString*)address
__attribute__((deprecated));

/**
 * Returns a local connection to the user's <i>Service Gateway</i>. No
 * discovery of local Service Gateways is made.
 * <p>
 * This method does <strong>ONLY</strong> use HTTPS connections!
 * <p>
 * Without discovery it cannot be verified, whether the serial number or the
 * given name match with the corresponding number or name of the Service
 * Gateway. Therefore this call could be used also to connect to QIVICON
 * emulators.
 * <p>
 * It is not verified, if the IP address and the GatewayID is correct and reachable!
 * <p>
 * Service Gateway ID and Service Gateway name are set to
 * the GatewayID.
 *
 * @param address
 *            IP address of the Service Gateway
 * @param gwID
 *            id (serial number) of Service Gateway
 * @return {@link QCLocalServiceGatewayConnection}
 */
- (QCLocalServiceGatewayConnection*) localGatewayConnectionWithAddress:(NSString*)address gatewayId:(NSString*)gwID;

/**
 * Call the discovery API to discover local Service Gateways. All
 * connections to locally connected Service Gateways will be cached and can
 * be found later without the need of an additional discovery.
 *
 * @param error
 *            Contains the error if the gateway connection could not returned. Can be nil
 *
 * @return Set containing all ids
 */
- (NSArray*)discoverLocalGatewayIDsWithError:(NSError * __autoreleasing *)error;

/**
 * Call the discovery API to discover local Service Gateways. All
 * connections to locally connected Service Gateways will be cached an can
 * be found later without the need of an additional discovery.
 *
 * @param forceRefresh
 *            define whether or not a refresh will be enforced
 * @param error
 *            Contains the error if the gateway connection could not returned.
 * @return array containing all local gateway ids.
 */
- (NSArray*)discoverLocalGatewayIDsForceRefresh:(BOOL)forceRefresh error:(NSError **)error;

/**
 * Returns a <b>remote</b> connection to the user's <i>Service Gateway</i>.
 * No discovery of local Service Gateways is made.
 * <p>
 * <b>It is not verified if the given gateway belongs to the user. If this
 * is not the case all calls on that connection will fail with HTTP status
 * code 403.</b>
 *
 * @param gwID
 *            id (serial number) of Service Gateway
 * @param error
 *            Contains the error if the gateway connection could not returned.
 * @return Service Gateway connection
 */
- (QCServiceGatewayConnection*)remoteGatewayConnectionWithGWID:(NSString*)gwID error:(NSError * __autoreleasing *)error;

/**
 * Returns a connection to the QIVICON backend.
 *
 * @return backend connection
 */
- (QCBackendConnection*) backendConnection;

/**
 * Returns a connection for QIVICON Events. This connection can be used to
 * handle events from the <i>Service Gateway</i>. It is based on an already
 * authorized {@link QCServiceGatewayConnection}.
 *
 * @param conn
 *            Connection to the <i>Service Gateway</i>. Must be authorized.
 * @param pushMethod
 *            Configures, which push method is allowed.
 *            <ul>
 *            <li><code>ALL</code>: The factory makes a decision, which
 *            method to be used
 *            <li><code>WEBSOCKET</code>: Use web sockets, if this is not
 *            working, an exception will be thrown.
 *            <li><code>LONG_POLLING</code>: Use long polling, if this is
 *            not working, an exception will be thrown.
 *            </ul>
 * @return A connection object is returned, that is either based on a long
 *         polling or a web socket connection. The factory chooses the
 *         connection type based on the given
 *         {@link QCServiceGatewayConnection} and the parameter
 *         <i>pushMethod</i>.
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id<QCServiceGatewayEventConnection>)gatewayEventConnectionWithConnection:(QCServiceGatewayConnection*)conn
                                                                 pushMethod:(PushMethod)pushMethod;

/**
 * Returns a connection for QIVICON Events. This connection can be used to
 * handle events from the <i>Service Gateway</i>. It is based on an already
 * authorized {@link QCServiceGatewayConnection}.
 *
 * @param conn
 *            Connection to the <i>Service Gateway</i>. Must be authorized.
 * @return A connection object is returned, that is either based on a long
 *         polling or a web socket connection. The factory chooses the
 *         connection type based on the given
 *         {@link QCServiceGatewayConnection}.
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id<QCServiceGatewayEventConnection>)gatewayEventConnectionWithConnection:(QCServiceGatewayConnection*)conn;

@end
