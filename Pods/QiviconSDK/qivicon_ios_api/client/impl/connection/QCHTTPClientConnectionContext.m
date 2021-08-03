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
//  QCHTTPClientConnectionContext.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 19.03.13.
//

#import "QCHTTPClientConnectionContext.h"
#import "QCLogger.h"
#import "JSONRPC.h"
#import "QCErrors.h"
#import "QCUtils.h"
#import "QCURLConnection.h"
#import "QCOAuth2Token.h"
#import "QCRemoteMethod.h"
#import "QCResultElement.h"
#import <objc/runtime.h>
#import "QCCertificateManager.h"
#import "QCAuthHelper.h"
#import "QCConnHelper.h"

NSString const * const CONTEXT_KEY;


@interface QCHTTPClientConnectionContext () {
}
@property(nonatomic, readwrite) QCGlobalSettings *gbl;

// For the synchronous execution
@property (atomic) BOOL requestFinished;
@property (strong) NSError *connectionError;
@property (strong) id entity;

@end

@implementation QCHTTPClientConnectionContext

- (id) initWithGlobalSettings:(QCGlobalSettings *) gbl {
    if ((self = [super init])) {
        self.gbl = gbl;
    }
    return self;
}


- (QCGlobalSettings*) globalSettings{
    return self.gbl;
}

- (id) callWithClass:(Class)classOfT
                 url:(NSURL*)url
           authToken:(NSString *)authToken
                gwId:(NSString *)gwId
               error:(NSError ** )error
             methods:(QCRemoteMethod *)firstMethod, ... {
    
    
    NSArray *methodArray = nil;
    if (firstMethod) {
        va_list argumentList;
        va_start(argumentList, firstMethod); // Start scanning for arguments after firstObject.
        methodArray = [QCUtils arrayWithParameter:firstMethod va_list:argumentList];
        va_end(argumentList);
    }
    
    return [self callWithClass:classOfT url:url authToken:authToken gwId:gwId methods:methodArray error:error];
}


- (id) callWithClass:(Class)classOfT
                 url:(NSURL *)url
           authToken:(NSString *)authToken
                gwId:(NSString *)gwId
             methods:(NSArray *)methods
               error:(NSError * __autoreleasing *)error
{
    assert (NO);
    return nil;
//    return [_connHelper callRPCWithClass:classOfT url:url authToken:authToken gwID:gwId methods:methods customIdentifier:nil error:error];
    
}

- (BOOL) callAsyncWithClass:(Class)classOfT
                        url:(NSURL *)url
                  authToken:(NSString *)authToken
                       gwId:(NSString *)gwId
                    methods:(NSArray *)methods
           customIdentifier:(NSString*)customIdentifier
            contextDelegate:(id<QCHTTPConnectionContextDelegate>)contextDelegate
         remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
                      error:(NSError * __autoreleasing *)error
{
    assert(NO);
    return false;
    NSError *callError;
//    [_connHelper callRPCAsyncWithClass:classOfT
//                                   url:url
//                             authToken:authToken
//                                  gwID:gwId
//                               methods:methods
//                       contextDelegate:contextDelegate
//                    remoteCallDelegate:remoteCallDelegate
//                      customIdentifier:customIdentifier
//                                 error:&callError];
    
    if (callError) {
        if (error) {
            *error = callError;
        }
        return NO;
    }
    
    return YES;
}

@end
