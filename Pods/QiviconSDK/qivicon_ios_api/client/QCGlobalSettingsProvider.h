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
#import "QCGlobalSettings.h"

/**
 * This interface must be implemented to provide the {@link QCGlobalSettings} to
 * the client API. Different implementations may exist for different
 * initialization methods.
 */
@protocol QCGlobalSettingsProvider <NSObject>
/**
 * Get initialized remote connection settings.
 *
 * @return created global settings object
 */
@property (nonatomic, readonly) QCGlobalSettings * remoteConnectionSettings;

/**
 * Get initialized local connections settings.
 *
 * @return create global settings object
 */
@property (nonatomic, readonly) QCGlobalSettings * localConnectionSettings;

@end
