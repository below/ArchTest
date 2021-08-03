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
//  QCRemoteServiceGatewayConnection.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 18.01.13.
//

#import "QCServiceGatewayConnection.h"
#import "QCServiceGatewayConnection_private.h"

/**
 * Connection to a <i>Service Gateway</i> via backend. The QIVICON backend is used as
 * a stepping stone to connect to the Service Gateway. The user of this connection
 * must authenticate against the QIVICON backend not the <i>Service Gateway</i>
 * (since the Service Gateway is unreachable as long the user is not authenticated!).
 */
@interface QCRemoteServiceGatewayConnection : QCServiceGatewayConnection

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                        gwID:(NSString *)gwID;

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                        gwID:(NSString *)gwID
    localClientAuthorization:(NSString *)clientAuthorization;

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID
    localClientAuthorization:(NSString *)clientAuthorization;
@end
