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
//  QCWebSocket.m
//  qivicon_ios_api
//
//  Created by m.fischer on 18.02.13.
//

#import "QCWebSocket.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCHTTPConnectionContext.h"
#import <SocketRocket/SRWebSocket.h>
#import "QCErrors.h"
#import "QCWebSocketListener.h"
#import "QCURLConnection.h"
#import "QCCertificateManager.h"
#import "QCUtils.h"

@interface QCWebSocket ()
@property (readwrite) QCServiceGatewayConnection* conn;
@property (readwrite) NSMutableDictionary *listeners;
@property (readwrite) NSString *webSocketURL;
@property (nonatomic, weak) id<QCCertificateDataStore> certificateStorage;
@end

@implementation QCWebSocket

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings sessionDelegate:(id<NSURLSessionDelegate>)delegate {
    self = [super initWithGlobalSettings:globalSettings sessionDelegate:delegate];
    return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                  connection:(QCServiceGatewayConnection*)connection
                webSocketURL:(NSString*)webSocketURL {
    
    self = [self initWithGlobalSettings:globalSettings sessionDelegate:connection.session.delegate];

    if (self) {
        if(!connection){
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Connection must not be null"
                                   userInfo:nil] raise];
            
        }
        if(![connection isAuthorized]){
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Provided connection must be authorized!"
                                   userInfo:nil] raise];
            
        }
        if(!webSocketURL){
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Web Socket URL must not be null."
                                   userInfo:nil] raise];
            
        }
        
        self.webSocketURL = webSocketURL;
        self.conn = connection;
        self.listeners = [NSMutableDictionary new];
        self.certificateStorage = (id<QCCertificateDataStore>)connection.session.delegate;
    }
    
    return self;
}

- (NSString*) addEventListenerWithTopic:(NSString *)topic
                                 filter:(NSString *)filter
                               listener:(__weak id <QCServiceGatewayEventListener>)listener
                                  error:(NSError *__autoreleasing *)error{
    
    if(!topic){
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Topic must not be null."
                               userInfo:nil] raise];
    }
    
    if(!listener){
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Listener must not be null."
                               userInfo:nil] raise];
    }
    
    NSURL *serverUrl = [self webSocketUrlWithTopic:topic filter:filter];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverUrl];
    [request setSR_SSLPinnedCertificates:[self.certificateStorage certificates]];
    
    if ([self.conn accessTokenWithError:nil] != 0) {
        [request setValue:[self.conn accessTokenWithError:nil] forHTTPHeaderField:HEADER_AUTHORIZATION];
    }
    if (self.conn.gwId.length != 0) {
        [request setValue:self.conn.gwId forHTTPHeaderField:HEADER_QIVICON_SERVICE_GATEWAY_ID];
    }
    
    SRWebSocket *socket = nil;
    if (self.conn.isLocal) {
        socket = [[SRWebSocket alloc] initWithURLRequest:request
                                               protocols:@[WSS_PROTOCOL]
                          allowsUntrustedSSLCertificates:YES];
    } else {
        socket = [[SRWebSocket alloc] initWithURLRequest:request];
    }
    
    if (socket) {        
        QCWebSocketListener *socketListener = [[QCWebSocketListener alloc] init];
        NSString *subscriptionID = [NSString stringWithFormat:@"%lu", (unsigned long)[socketListener hash]];
        [self.listeners setValue:socketListener forKey:subscriptionID];
        [socketListener startSocketListenerForSubscriptionID:subscriptionID
                                             eventConnection:self
                                                  connection:self.conn
                                                        gwID:self.conn.gwId
                                                   webSocket:socket
                                                    listener:listener];

        return subscriptionID;
    }
    return nil;
}

- (void) removeEventListenerWithID:(NSString *)listenerID error:(NSError *__autoreleasing *)error{
    QCWebSocketListener *socketListener  = [self.listeners objectForKey:listenerID];
    if (!socketListener && error) {
        *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"No listener found with id %@", listenerID]}];
    } else {
        [socketListener close];
        [self.listeners removeObjectForKey:listenerID];
    }
}

- (void) removeAllEventListenersWithError:(NSError *__autoreleasing *)error {
    NSError *localError;
    for (NSString * eventId  in self.listeners.keyEnumerator) {
        [self removeEventListenerWithID:eventId error:&localError];
        if (localError != nil) {
            if (error)
                *error = localError;
        }
    }
    [self.listeners removeAllObjects];
}

- (NSString*) serviceGatewayId{
    return self.conn.gwId;
}

- (NSURL*)webSocketUrlWithTopic:(NSString*)topic filter:(NSString*)filter {
    NSString *urlString = nil;
    NSString *topicString = [NSString stringWithFormat:@"[%@]", topic];
    
    if (![self.webSocketURL hasSuffix:@"?"]){
        self.webSocketURL = [self.webSocketURL stringByAppendingString:@"?"];
    }
    
    if ([filter length] == 0){
        urlString = [NSString stringWithFormat:@"%@topics=%@", self.webSocketURL, [topicString urlEncoded]];
    } else {
        urlString = [NSString stringWithFormat:@"%@topics=%@&filter=%@", self.webSocketURL, [topicString urlEncoded],
                     [filter urlEncoded]];
    }
        
    return [NSURL URLWithString:urlString];
}

- (PushMethod)pushMethodType{
    return PushMethod_WebSocket;
}

@end
