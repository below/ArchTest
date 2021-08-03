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
//  QCLongPollingDispatchedCall.h
//  qivicon_ios_api
//
//  Created by m.fischer on 23.01.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCServiceGatewayEventConnection.h"
#import "QCServiceGatewayConnection.h"

@interface QCLongPollingDispatchedCall : NSObject{
    BOOL leaveLoop;
}

- (void) startLongPollingForSubscriptionID:(NSString*)subscriptionID
                           eventConnection:(id<QCServiceGatewayEventConnection>)eventConnection
                                connection:(QCServiceGatewayConnection*)conn
                                   timeout:(int)timeout
                                  listener:(__weak id<QCServiceGatewayEventListener>)listener;

-(void)cancel;

@end
