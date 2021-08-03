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

#import "QCLogger.h"

QCLogger *gDefaultLogger = nil;

@implementation QCLogger

+ (QCLogger *) defaultLogger {
    return gDefaultLogger;
}

+ (void) setDefaultLogger:(QCLogger *)logger {
    gDefaultLogger = logger;
}

- (void) debug:(NSString *)format, ... {
    va_list argumentList;
    va_start(argumentList, format);
    NSLogv(format, argumentList);
    va_end(argumentList);
}

- (void) info:(NSString *)format, ... {
    va_list argumentList;
    va_start(argumentList, format);
    NSLogv(format, argumentList);
    va_end(argumentList);
}

- (void) warn:(NSString *)format, ... {
    va_list argumentList;
    va_start(argumentList, format);
    NSLogv(format, argumentList);
    va_end(argumentList);
}

- (void) error:(NSString *)format, ... {
    va_list argumentList;
    va_start(argumentList, format);
    NSLogv(format, argumentList);
    va_end(argumentList);
}

@end
