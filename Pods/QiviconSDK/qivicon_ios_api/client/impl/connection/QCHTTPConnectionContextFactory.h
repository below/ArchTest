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

@protocol QCHTTPConnectionContext;
@class QCGlobalSettings;

/**
 * This class creates instances of {@link QCHTTPConnectionContext} for a given
 * {@link QCGlobalSettings} object.
 */

@protocol QCHTTPConnectionContextFactory <NSObject>

/**
 * Create an instance of {@link QCHTTPConnectionContext} for a given
 * {@link QCGlobalSettings} object.
 *
 * @param globalSettings
 *            global settings to use for the {@link QCHTTPConnectionContext}
 * @return connection {@link QCHTTPConnectionContext} object
 */
+ (id<QCHTTPConnectionContext>)connectionContextWithConnectionSettings:(QCGlobalSettings*)globalSettings;

@end
