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
//  QCServiceGatewayConnection.m
//  qivicon_ios_api
//
//  Created by m.fischer on 18.01.13.
//

#import "QCServiceGatewayConnection_private.h"
#import "QCGlobalSettings.h"
#import "QCPersistentTokenStorage.h"
#import "QCLogger.h"

/**
 * Connection to <i>Service Gateway</i>. A connection is identified by the ID of the
 * connected Service Gateway (serial number).
 * <p>
 * This class is abstract as there are two possible connections to a QIVICON
 * Service Gateway:
 * <ul>
 * <li><strong>Local connections ({@link QCLocalServiceGatewayConnection}): </strong>If
 * the Service Gateway is accessible in the same network, a local connection is
 * established.</li>
 * <li><strong>Remote connections ({@link QCRemoteServiceGatewayConnection}):
 * </strong>If the Service Gateway is not in the same network, the QIVICON backend
 * will be used as a stepping stone to connect to the <i>Service Gateway</i>.</li>
 * </ul>
 */
@implementation QCServiceGatewayConnection {
    NSMutableDictionary *_methodContexts;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID
                       token:(QCOAuth2Token *)token {
    if (!gwID) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid Service Gateway serial number." userInfo:nil] raise];
        return nil;
    }
    
    self = [super initWithGlobalSettings:globalSettings tokenStorage:tokenStorage sessionDelegate:delegate authToken:token];
    
    if (self) {
        self.gwId = gwID;
    }
    
    return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID {
    if (!gwID) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid Service Gateway serial number." userInfo:nil] raise];
        return nil;
    }
    self.gwId = gwID;
    self = [super initWithGlobalSettings:globalSettings tokenStorage:tokenStorage sessionDelegate:delegate];
    return self;
}


/**
 * We always need a serial number so don't use this default initializer.
 */
- (id)init{
    [[NSException exceptionWithName:NSGenericException reason:@"Wrong initializer" userInfo:nil] raise];
    return nil;
}

- (void) connection:(id <QCHTTPConnectionContext>)connection
       withMethodId:(NSNumber *)methodId
   didFailWithError:(NSError *)error {
}

- (void) setContext:(GatewayMethodContext *)context
        forMethodId:(NSNumber *)methodId {
    if (_methodContexts == nil)
        _methodContexts = [NSMutableDictionary new];
    [_methodContexts setObject:context forKey:methodId];
}

- (GatewayMethodContext *) contextForMethodId:(NSNumber *)methodId {
    GatewayMethodContext *context = [_methodContexts objectForKey:methodId];
    NSAssert(context != nil, @"Context for ID %@ must not be nil!", methodId);
    return context;
}

- (void) removeContextForMethodId:(NSNumber *)methodId {
    [_methodContexts removeObjectForKey:methodId];
}

// This looks a bit deprecated …
- (NSString*)webSocketUrl{
    return nil;

}

- (BOOL) isLocal{
    return self.connectionType == ConnectionType_Service_Gateway_Local;
}

@end

@implementation GatewayMethodContext
@end
