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
#import "QCAuthorizedConnection.h"

/**
 * Provides all methods necessary to connect to the
 * QiviconBackend and to call JSON-RPC methods on the backend.
 */
@interface QCBackendConnection : QCAuthorizedConnection

@property (weak) id <QCConnectionDelegate> delegate;

/**
 * Get a list of <i>Service Gateways</i> for the authorized user.
 * Normally a user has only one Service Gateway assigned.
 *
 * @param error
 *            Contains the error if the call has failed.
 * @return list of gateways
 */
- (NSArray*) userGatewaysWithError:(NSError **)error;

/**
 * Get the last known local address of the gateway.
 *
 * @param gwId
 *            GateqayID.
 * @param error
 *            Contains the error if the call has failed.
 * @return list of gateways
 */
- (NSString*) userGatewayAddressForGwId:(NSString*)gwId error:(NSError * __autoreleasing *)error;
@end
