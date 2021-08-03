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
//  QCJsonRpcIDProvider.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 21.10.13.
//

#import <Foundation/Foundation.h>

/**
 * Implements a simple id provider for the id parameter in JSON-RPC calls as a
 * singleton.
 */

@interface QCJsonRpcIDProvider : NSObject

/**
 * Get the singleton instance of the id provider.
 *
 * @return instance
 */
+ (instancetype) sharedInstance;

/**
 * Get next unique id.
 *
 * @return id
 */
@property (nonatomic, readonly) int nextId;

+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

@end
