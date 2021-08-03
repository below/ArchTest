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

@interface QCDiscoveryParserDelegate : NSObject <NSXMLParserDelegate>
@property (strong, readonly) NSString *modelName;
@property (strong, readonly) NSString *serialNumber;
@property (strong, readonly) NSString *friendlyName;
@property (strong, readonly) NSString *modelDescription;
@property (strong, readonly) NSString *deviceType;
@property (strong, readonly) NSError *error;
@end
