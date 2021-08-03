//
//  QCSystemPropertiesGlobalSettingsProvider.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCAbstractInputStreamGlobalSettingsProvider.h"

/**
 * This class implements a {@link QCGlobalSettingsProvider}, that reads the initialization
 * values from the property file {@link #QIVICON_CONNECTOR_PROPERTIES_FILE}.
 */
@interface QCSystemPropertiesGlobalSettingsProvider : QCAbstractInputStreamGlobalSettingsProvider

/**
 * Name of the property file that is used to initialize all end points,
 * proxy settings, etc.
 */
+ (NSString *) QIVICON_CONNECTOR_PROPERTIES_FILE;

/**
 * Name of the property file that is used to initialize all end points,
 * proxy settings, etc.
 */
+ (NSString *) QIVICON_LOCAL_CONNECTOR_PROPERTIES_FILE;

@end
