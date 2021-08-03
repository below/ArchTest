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
//  QCWebSocket.h
//  qivicon_ios_api
//
//  Created by m.fischer on 18.02.13.
//

#import <Foundation/Foundation.h>
#import "QCConnection.h"
#import "QCServiceGatewayEventConnection.h"
@protocol QCCertificateDataStore;

@class QCServiceGatewayConnection;

@interface QCWebSocket : QCConnection <QCServiceGatewayEventConnection>


/**
 * Creates a web socket connection.
 *
 * @param globalSettings
 *            global settings which will be used to establish the
 *            connection
 * @param connection
 *            local Service Gateway connection to use
 * @param websocketURL
 *            web socket URL, must not be null
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                  connection:(QCServiceGatewayConnection*)connection
                webSocketURL:(NSString*)webSocketURL;
@end
