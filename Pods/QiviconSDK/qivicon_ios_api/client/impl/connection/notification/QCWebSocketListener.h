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
#import "QCServiceGatewayEventConnection.h"
#import "QCServiceGatewayConnection.h"
#import <SocketRocket/SRWebSocket.h>

@interface QCWebSocketListener : NSObject <SRWebSocketDelegate>

- (void) startSocketListenerForSubscriptionID:(NSString*)subscriptionID
                           eventConnection:(id<QCServiceGatewayEventConnection>)eventConnection
                                connection:(QCServiceGatewayConnection*)conn
                                      gwID:(NSString*)gwID
                                 webSocket:(SRWebSocket*)socket
                                  listener:(__weak id<QCServiceGatewayEventListener>)listener;


- (void) close;
@end
