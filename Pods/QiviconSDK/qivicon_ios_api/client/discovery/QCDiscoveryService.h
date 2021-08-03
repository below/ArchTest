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

#import "QCDiscoveryDelegate.h"
#import "QCPersistentTokenStorage.h"

/**
 * Protocol for all discovery services. Discovery services are used to find
 * locally connected <i>Service Gateways</i>.
 *
 */
@protocol QCDiscoveryService <NSObject>

/**
 * Searches for <i>Service Gateways</i>. A default timeout of 10,000 ms is
 * used.
 *
 * @param connectionContext
 *            connection context to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @return array of LocalConnection objects of all gateways found or null.
 * @throws DiscoveryException
 *             on errors
 */
- (NSArray *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                          tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                 error:(NSError **)error;

/**
 * Searches for <i>Service Gateways</i>.
 *
 * @param connectionContext
 *            connection context to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param timeout
 *            search timeout in milliseconds. Timeout must be specified
 *            between 1000 and 20000.
 * @return array of LocalConnection objects of all gateways found or null.
 * @throws DiscoveryException
 *             on errors
 */
- (NSArray *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                          tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                               timeout:(int)timeout
                                 error:(NSError **)error;

/**
 * Searches for <i>Service Gateways</i>.
 *
 * @param globalSettings
 *            global settings to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param timeout
 *            search timeout in milliseconds. Timeout must be specified
 *            between 1000 and 20000.
 * @param delegate
 *            will be called for each device found
 * @return array of LocalConnection objects of all gateways found or null.
 * @throws DiscoveryException
 *             on errors
 */
- (NSArray *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                          tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                               timeout:(int)timeout
                              delegate:(id <QCDiscoveryDelegate>)delegate
                                 error:(NSError **)error;

/**
 * Searches for a <i>Service Gateway</i> with a specific id. A default timeout of
 * 10s is used. The method returns immediately on device found. If the searched
 * Service Gateway cannot be found, null is returned.
 *
 * @param globalSettings
 *            global settings to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param identifier
 *            serial number (id) of the gateway to be looked up
 * @return Successfull broadcast.
 * @throws DiscoveryException
 *             on errors
 */
- (QCLocalServiceGatewayConnection *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                                  tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                              deviceIdentifier:(NSString*) identifier
                                                         error:(NSError **)error;
@end
