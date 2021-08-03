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

@interface NSString (urlExtras)
- (NSString *) urlEncoded;
- (BOOL)isValidIpAddress;
- (BOOL)isValidIPv6Address;
- (NSString*)stringByFormattingForIPv6;
@end

@interface QCUtils : NSObject
+ (NSArray *) arrayWithParameter:(id)firstParam va_list:(va_list) argumentList;
+ (NSData*)dataWithBase64EncodedString:(NSString*)string;
+ (NSString *)base64EncodedStringFromData:(NSData*)data;

@end
