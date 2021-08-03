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

#import "QCUtils.h"

#define XX 65
#define UNITS(arr) (sizeof(arr)/sizeof(arr[0]))

@implementation QCUtils
+ (NSArray *) arrayWithParameter:(id)firstParam va_list:(va_list) argumentList {
    NSMutableArray *paramArray;
    
    if (firstParam != nil) {
        id eachParam = nil;
        paramArray = [NSMutableArray array];
        [paramArray addObject:firstParam];
        while (( eachParam = va_arg(argumentList, id) )) // As many times as we can get an argument of type "id"
            [paramArray addObject:eachParam];
    }
    return paramArray;
}


+ (NSData*)dataWithBase64EncodedString:(NSString*)string
{
    return [[NSData alloc] initWithBase64EncodedString:string
                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
}


+ (NSString *)base64EncodedStringFromData:(NSData*)data
{
    return [data base64EncodedStringWithOptions:0];
}


@end


#include <arpa/inet.h>
@implementation NSString (urlExtras)

- (NSString *) urlEncoded {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
}
/** Check if an IP address is valid.
 
 Looks for both IPv4 and IPv6.
 Based on: http://stackoverflow.com/questions/1679152/how-to-validate-an-ip-address-with-regular-expression-in-objective-c/10971521#10971521
 
 @param ip IP address as string.
 @return Returns true if given IP address is valid, false otherwise.
 
 */
- (BOOL)isValidIpAddress {
    const char *utf8 = [self UTF8String];
    
    // Check valid IPv4.
    struct in_addr dst;
    int success = inet_pton(AF_INET, utf8, &(dst.s_addr));
    if (success != 1) {
        // Check valid IPv6.
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    return (success == 1);
}

/** Check if an IP address is a valid IPv6 address.
 
 Looks for IPv6 only.
 
 @param ip IP address as string.
 @return Returns true if given IP address is valid IPv6 address, false otherwise.
 
 */
- (BOOL)isValidIPv6Address {
    const char *utf8 = [self UTF8String];
    struct in6_addr dst6;
    // Check valid IPv6.
    int success = success = inet_pton(AF_INET6, utf8, &dst6);
    return (success == 1);
}

- (NSString*)stringByFormattingForIPv6 {
    NSString * returnString = [self isValidIPv6Address] ? [NSString stringWithFormat:@"[%@]", self] : self;
    return returnString;
}

@end


