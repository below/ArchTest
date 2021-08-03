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
//  QCHTTPClientConnectionContextFactory.h
//  qivicon_ios_api
//
//  Created by m.fischer on 18.03.13.
//

#import <Foundation/Foundation.h>
#import "QCHTTPConnectionContextFactory.h"

@class QCHTTPConnectionContext;
@class QCHTTPClientConnectionContext;
@class QCGlobalSettings;

@interface QCHTTPClientConnectionContextFactory : NSObject <QCHTTPConnectionContextFactory>

/**
 * Create an instance of {@link QCHTTPClientConnectionContext} for a given
 * {@link QCGlobalSettings} object.
 *
 * @param globalSettings
 *            global settings to use for the {@link QCHttpConnectionContext}
 * @return connection {@link QCHTTPClientConnectionContext} object
 */

@end
