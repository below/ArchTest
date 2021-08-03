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
#import "QCServiceGatewayConnection.h"
#import "QCPersistentTokenStorage.h"
#import "QCCertificateManager.h"

/**
 * Connection to a locally connected <i>Service Gateway</i>. Local connections
 * contain an IP address of the connected Service Gateway and an URL to connect to
 * this Service Gateway.
 */
@interface QCLocalServiceGatewayConnection : QCServiceGatewayConnection


/**
 * Get base URL of the Service Gateway. The URL base consists of http:// or
 * https://, address and port.
 *
 * @return url base as String
 */
@property (readonly) NSURL *baseUrl;

/**
 * Get IP address of Service Gateway.
 *
 * @return IP address
 */
@property (readonly) NSString *addr;

/**
 * Get name of the Service Gateway.
 *
 * @return Service Gateway name
 */
@property (nonatomic, readonly) NSString *friendlyName;

/**
 * Check whether the underlying connection is use https.
 *
 * @return true, if https must be used
 */
@property (readonly) NSURL *oAuthEndpoint;
@property (readonly) NSURL *oAuthTokenEndpoint;

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
 * @param address
 *            IP address of Service Gateway
 * @param name
 *            name of <i>Service Gateway</i>
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id <QCPersistentTokenStorage, QCCertificateStorageDelegate>)tokenStorage
                        GWID:(NSString *)gwID
                     address:(NSString*)address
                        name:(NSString*)name;

@end
