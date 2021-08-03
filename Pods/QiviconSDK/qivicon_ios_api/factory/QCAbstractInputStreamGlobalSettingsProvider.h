//
//  QCAbstractInputStreamGlobalSettingsProvider.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCGlobalSettingsProvider.h"

/**
 * This class is an abstract base class for input stream based
 * {@link QCGlobalSettingsProvider} implementations. It provides a method to read
 * {@link QCGlobalSettings} object from an input stream.
 */
@interface QCAbstractInputStreamGlobalSettingsProvider : NSObject <QCGlobalSettingsProvider>

/**
 * Reads {@link QCGlobalSettings} object from an input stream and closes the
 * stream.
 *
 * @param url
 *            The url pointing to the global settings
 * @return {@link QCGlobalSettings} object or null if the settings could not
 *         be read
 */

- (QCGlobalSettings *) readGlobalSettingsWithUrl:(NSURL *)url;

@end
