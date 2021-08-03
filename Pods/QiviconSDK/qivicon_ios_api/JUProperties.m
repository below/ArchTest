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
//  JUProperties.m
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 13.01.13.
//

#import "JUProperties.h"

@implementation JUProperties {
    NSMutableDictionary * _properties;
}

- (id) loadURL:(NSURL *)url withError:(NSError * __autoreleasing *)error {
    NSError *localError = nil;
    NSString *propString = [NSString stringWithContentsOfURL:url
                                                usedEncoding:nil
                                                       error:&localError];
    if (localError != nil) {
        if (error)
            *error = localError;
        return nil;
    }
    return [self propertiesWithContentsOfString:propString error:error];
}

- (id) propertiesWithContentsOfString:(NSString *)string error:(NSError * __autoreleasing *)error {
    NSError *localError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([^#\r\n][^=]*)=(.*)$"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:&localError];
    if (localError != nil) {
        if (error)
            *error = localError;
        return nil;
    }
    
    [_properties removeAllObjects];
    
    NSArray *matches = [regex matchesInString:string
                                      options:0
                                        range:NSMakeRange(0, [string length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange keyRange = [match rangeAtIndex:1];
        NSRange valueRange = [match rangeAtIndex:2];
        NSString *key = [string substringWithRange:keyRange];
        NSString *value = [string substringWithRange:valueRange];
        if (key != nil && value != nil) {
            if (_properties == nil)
                _properties = [NSMutableDictionary dictionaryWithCapacity:matches.count];
            [_properties setValue:value forKey:key];
        }
    }

    return [_properties copy];
}

- (id) property:(NSString *)key {
    return [self valueForKey:key];
}

// This enables the modern objective C subscripting syntax
- (id)objectForKeyedSubscript: (id)key {
    return [self valueForKey:key];
}

- (id) valueForKey:(NSString *)key {
    return [_properties valueForKey:key];
}
@end
