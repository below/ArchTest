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
//  QCWebSocketConnectionFactory.h
//  qivicon_ios_api
//
//  Created by m.fischer on 18.03.13.
//

#import <Foundation/Foundation.h>

@protocol QCHTTPConnectionContext;
@protocol QCCertificateDataStore;

@class QCServiceGatewayConnection;
@class QCWebSocket;
@class QCGlobalSettings;

@interface QCWebSocketConnectionFactory : NSObject

/**
 * Create the web socket implementation.
 *
 * @param globalSettings
 *            current global settings
 * @param gatewayConnection
 *            connection to the home base the web socket connection should
 *            be based on
 * @param websocketUrl
 *            URL for the web socket connection
 * @return created connection
 * @throws Exception
 *             Thrown on argument errors.
 */
- (QCWebSocket*)webSocketConnectionWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                           connection:(QCServiceGatewayConnection*)connection
                                         webSocketURL:(NSString*)webSocketURL;

@end
