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
//  QCServiceGatewayConnection.h
//  qivicon_ios_api
//
//  Created by m.fischer on 18.01.13.
//

#import <Foundation/Foundation.h>
#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCAuthorizedConnection.h"
#import "QCServiceGatewayConnection.h"
#import "QCHTTPConnectionContext.h"
#import "QCAuthorizedConnection_private.h"

@protocol QCPersistentTokenStorage;

@interface GatewayMethodContext : NSObject
@property (weak) id<QCConnectionDelegate> delegate;
@property (atomic) BOOL attemptedReAuth;
@property (atomic) NSError *connectionError;
@property NSArray *methods;
@end

@interface QCServiceGatewayConnection ()

@property NSURL *url;
@property (readwrite) NSString *gwId;
/**
 * Create a new Service Gateway connection with default connection
 * parameters. Token storage will be provided.
 *
 * @param globalSettings
 *            globalSettings which will be used to establish the
 *            connection
 * @param tokenStorage
 *            token storage provider to persist the refresh token
 * @param gwID
 *            serial number (id) of the Service Gateway
 * @return initialized Object
 * @throws Exception
 *             Thrown on argument errors.
 *
 */
- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID;

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate
                        gwID:(NSString *)gwID
                       token:(QCOAuth2Token *)token;

- (void) setContext:(GatewayMethodContext *)context forMethodId:(NSNumber *)methodId;

- (GatewayMethodContext *) contextForMethodId:(NSNumber *)methodId;

- (void) removeContextForMethodId:(NSNumber *)methodId;

/**
 * Get the URL for web socket connections. This URL can be null, if web
 * sockets are not supported by the underlying connection.
 * <p>
 * To subscribe to events of a <i>Service Gateway</i>, web sockets could be
 * used. The {@link QCServiceGatewayEventConnection} is used to implement such
 * connections. Web sockets need an URL to subscribe, this URL can be
 * retrieved here.
 *
 * @return web socket URL or null
 */
- (NSString*)webSocketUrl;

/**
 * Returns {@code true} if the connection is of type
 * {@link QCLocalServiceGatewayConnection} and {@code false} if it is not.
 * Note, there is no specific interface for remote connections as they do
 * not have any special attributes.
 *
 * @return YES if it is a local connect, false otherwise.
 */
- (BOOL) isLocal __attribute__((deprecated));

@end
