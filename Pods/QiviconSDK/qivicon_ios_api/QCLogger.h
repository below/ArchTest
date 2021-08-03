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

@interface QCLogger : NSObject
+ (QCLogger *) defaultLogger;
+ (void) setDefaultLogger:(QCLogger *)logger;

- (void) debug:(NSString *)format, ...;
- (void) info:(NSString *)format, ...;
- (void) warn:(NSString *)format, ...;
- (void) error:(NSString *)format, ...;
@end
