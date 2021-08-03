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
//  JSONRPC.h
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 11.01.13.
//

#import <Foundation/Foundation.h>
#import "QCRemoteMethod.h"

extern NSString  * JSONRPCErrorDomain;

extern NSInteger cannotConvertToTargetClass;    // Unable to convert the result to the intended target class
extern NSInteger resultClassUnknown;            // The result from the backend were not key/value pairs


@interface JSONRPC : NSObject
+ (id) resultFromJsonData:(id)jsonData asClass:(Class)class error:(NSError * __autoreleasing *)error;

+ (NSDictionary *) methodDictionaryWithMethod:(QCRemoteMethod *)method;
@end
