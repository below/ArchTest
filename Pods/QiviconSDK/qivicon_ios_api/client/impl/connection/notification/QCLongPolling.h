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
//  QCLongPolling.h
//  qivicon_ios_api
//
//  Created by m.fischer on 21.01.13.
//

#import <Foundation/Foundation.h>
#import "QCConnection.h"
#import "QCServiceGatewayConnection.h"
#import "QCServiceGatewayEventConnection.h"

extern NSString * const  POLL;

@interface QCLongPolling : QCConnection <QCServiceGatewayEventConnection>

/**
 * Creates a long polling connection.
 *
 * @param globalSettings
 *            global settings which will be used to establish the connection
 * @param connection
 *            Service Gateway connection to use
 * @return  initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                  connection:(QCServiceGatewayConnection*)connection;

@end
