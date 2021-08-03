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
//  QCURLConnection.m
//  qivicon_ios_api
//
//  Created by m.fischer on 17.01.13.
//

#import "QCURLConnection.h"
#import "QCCertificateManager.h"

@implementation QCURLConnection

+ (void) clearCookies {
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/* In fact, only used in one place, QCLocalServiceGatewayConnection */
+ (NSData * __nullable)sendSynchronousRequest:(NSURLRequest * __nonnull)request usingSession:(NSURLSession * __nonnull)session returningResponse:(NSURLResponse * __autoreleasing * __nullable)returningResponse error:(NSError * __autoreleasing * __nullable)returningError {
    
    [self clearCookies];
    
    NSData * __block receivedData = nil;

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (returningError) {
            *returningError = error;
        }
        if (returningResponse) {
            *returningResponse = response;
        }
        if (error == nil) {
            receivedData = data;
        }
        dispatch_semaphore_signal(sem);
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    return receivedData;
}

@end
