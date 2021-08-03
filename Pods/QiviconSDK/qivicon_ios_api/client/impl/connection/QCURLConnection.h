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
//  QCURLConnection.h
//  qivicon_ios_api
//
//  Created by m.fischer on 17.01.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QCURLConnection : NSObject {
}
+ (void) clearCookies;

+ (NSData * __nullable)sendSynchronousRequest:(NSURLRequest * __nonnull)request usingSession:(NSURLSession * __nonnull)session returningResponse:(NSURLResponse * __nonnull __autoreleasing * __nullable)returningResponse error:(NSError * __nonnull __autoreleasing * __nullable)returningError;

@end
