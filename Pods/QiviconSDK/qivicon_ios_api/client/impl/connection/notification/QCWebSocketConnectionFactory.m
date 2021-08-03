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
//  QCWebSocketConnectionFactory.m
//  qivicon_ios_api
//
//  Created by m.fischer on 18.03.13.
//

#import "QCWebSocketConnectionFactory.h"
#import "QCWebSocket.h"
#import "QCServiceGatewayConnection.h"

@implementation QCWebSocketConnectionFactory

- (QCWebSocket*)webSocketConnectionWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                           connection:(QCServiceGatewayConnection *)connection
                                         webSocketURL:(NSString *)webSocketURL {
    
    return [[QCWebSocket alloc] initWithGlobalSettings:globalSettings
                                            connection:connection
                                          webSocketURL:webSocketURL];
}

@end
