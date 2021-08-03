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

#import "QCLocalServiceGatewayConnection.h"
@protocol QCDiscoveryService;

/**
 * Delegate will be called from the discovery service for each device found.
 */
@protocol QCDiscoveryDelegate <NSObject>

/**
 * For each connection found this method will be called.
 * @param service which found the connection
 * @param connection connection found
 */
- (void) service:(id <QCDiscoveryService>)service foundDeviceWithConnection:(QCLocalServiceGatewayConnection *) connection;

@end

@protocol QCAsyncDiscoveryDelegate <QCDiscoveryDelegate>

- (void) discoveryServiceFinished:(id <QCDiscoveryService>)service;

- (void) discoveryService:(id <QCDiscoveryService>)service finishedWithError:(NSError *)error;

@end
