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
 * Connection to <i>Service Gateway</i>. A connection is identified by the ID of the
 * connected Service Gateway (serial number).
 */
@interface QCServiceGatewayConnection : QCAuthorizedConnection

/**
 * Get the serial number (id).
 *
 * @return id
 */
@property (readonly) NSString *gwId;
/**
 * Returns {@code true} if the connection is of type
 * {@link QCLocalServiceGatewayConnection} and {@code false} if it is not.
 * Note, there is no specific interface for remote connections as they do
 * not have any special attributes.
 *
 * @return true if it is a local connect, false otherwise.
 */
- (BOOL) isLocal;

@end
