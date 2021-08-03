//
//  QCFileGlobalSettingsProvider.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 31.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCAbstractInputStreamGlobalSettingsProvider.h"

/**
 * This class implements a {@link QCGlobalSettingsProvider},
 * that reads the initialization values from the specified property file.
 */
@interface QCFileGlobalSettingsProvider : QCAbstractInputStreamGlobalSettingsProvider

/**
 * Read the property files and initialize the {@link QCGlobalSettings}
 * accordingly.
 *
 * @param urlForRemoteConnections
 *            url for remote connection properties
 * @param urlForLocalConnections
 *            url for local connections properties
 */
- (id) initWithURLForRemoteConnections:(NSURL *)urlForRemoteConnections
                urlForLocalConnections:(NSURL *)urlForLocalConnections;

@end
