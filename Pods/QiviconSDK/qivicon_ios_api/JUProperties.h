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
//  JUProperties.h
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 13.01.13.
//

#import <Foundation/Foundation.h>

@interface JUProperties : NSObject
- (id) loadURL:(NSURL *)url withError:(NSError * __autoreleasing *)error;
- (id) propertiesWithContentsOfString:(NSString *)string error:(NSError * __autoreleasing *)error;
- (id) property:(NSString *)key;
- (id) objectForKeyedSubscript: (id)key;
@end
