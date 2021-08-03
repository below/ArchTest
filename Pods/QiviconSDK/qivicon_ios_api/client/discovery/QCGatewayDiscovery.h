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
//  QCGatewayDiscovery.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 07.02.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCDiscoveryDelegate.h"
#import "QCPersistentTokenStorage.h"

/** UPnP discovery service */
static const int UPNP_DISCOVERY = 1;

/** default timeout for UPnP requests: 5s */
static const int TIMEOUT = 5000;

@interface QCGatewayDiscovery : NSObject

+ (id <QCDiscoveryService>) discoveryWithType:(int)discoveryType;

- (id) initWithDiscoveryService:(id <QCDiscoveryService>)service;

- (void) refreshConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                 tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                     delegate:(id <QCDiscoveryDelegate>) delegate;

- (QCLocalServiceGatewayConnection *) connectionWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                                      tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                                         gatewayId:(NSString *) gwId
                                                             error:(NSError **)error;

- (NSDictionary *) allConnectionsWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                       tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                                           delegate:(id<QCDiscoveryDelegate>)delegate
                                       forceRefresh:(BOOL)forceRefresh;

@end
