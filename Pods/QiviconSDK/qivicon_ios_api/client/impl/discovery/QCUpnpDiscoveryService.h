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
//  QCUpnpDiscoveryService.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 07.02.13.
//

#import <Foundation/Foundation.h>
#import "QCDiscoveryService.h"
#import "QCGCDAsyncUdpSocket.h"

@interface QCUpnpDiscoveryService : NSObject <QCDiscoveryService, QCGCDAsyncUdpSocketDelegate>

- (BOOL)lookupAsyncWithGlobalSettings:(QCGlobalSettings *)globalSettings
                         tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                            gatewayId:(NSString*) identifier
                              timeout:(int)timeout
                             delegate:(id <QCAsyncDiscoveryDelegate>)delegate;

@end
