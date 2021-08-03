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
//  QCServiceGatewayEventConnection.m
//  qivicon_ios_api
//
//  Created by m.fischer on 07.03.13.
//

#import "QCServiceGatewayEventConnection.h"
#import "QCServiceGatewayConnection.h"
#import "QCLongPolling.h"
#import "QCWebSocket.h"
#import "QCWebSocketConnectionFactory.h"
#import "QCErrors.h"
#import "QCHTTPConnectionContext.h"

@interface QCServiceGatewayEventConnection()

@property (readwrite)QCServiceGatewayConnection *gatewayConnection;
@property (readwrite)id<QCHTTPConnectionContext> connectionContext;
@property (readwrite)NSString *websocketUrl;
@property (readwrite)id<QCServiceGatewayEventConnection> pushImplementation;
@property (readwrite)PushMethod pushMethod;

@property (readwrite) QCWebSocketConnectionFactory *wsFactory;
@property (readwrite) QCLongPolling *polling;
@property (readwrite) QCWebSocket *websocket;
@property (readwrite) NSMutableSet *listeners;

@end


@implementation QCServiceGatewayEventConnection

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
  webSocketConnectionFactory:(QCWebSocketConnectionFactory*)wsFactory
                  connection:(QCServiceGatewayConnection*)connection
                websocketURL:(NSString*)websocketURL
                  pushMethod:(PushMethod)pushMethod {

    self = [self initWithGlobalSettings:globalSettings sessionDelegate:connection.session.delegate];
    
    if (self) {
        self.wsFactory = wsFactory;
        self.gatewayConnection = connection;
        self.websocketUrl = websocketURL;
        
        if (pushMethod == PushMethod_All) {
            /* if (connection.isLocal)
                pushMethod = PushMethod_Long_Polling;
            else */
                pushMethod = PushMethod_WebSocket;
        }
        
        self.pushMethod = pushMethod;
        
        if (!self.wsFactory || pushMethod == PushMethod_Long_Polling) {
            self.polling =  [[QCLongPolling alloc] initWithGlobalSettings:globalSettings connection:connection];
            self.pushImplementation = self.polling;
        }
        else {
            self.websocket = [self.wsFactory webSocketConnectionWithGlobalSettings:globalSettings
                                                                        connection:connection
                                                                      webSocketURL:websocketURL];
            self.pushImplementation = self.websocket;
        }

        self.listeners = [NSMutableSet new]; 
        
    }
    return self;
}

- (NSString*) addEventListenerWithTopic:(NSString*)topic
                                 filter:(NSString*)filter
                               listener:(__weak id <QCServiceGatewayEventListener>)
                listener error:(NSError *__autoreleasing *)error {
    
    NSString *ret;
    
    if (self.wsFactory && (self.pushMethod == PushMethod_All || self.pushMethod == PushMethod_WebSocket)) {
        @try {
            ret = [self.websocket addEventListenerWithTopic:topic filter:filter listener:listener error:error];
        } @catch (NSException * e) {
            if (!self.polling){
                self.polling =  [[QCLongPolling alloc] initWithGlobalSettings:self.globalSettings
                                                                      connection:self.gatewayConnection];
            }
            if (self.pushMethod == PushMethod_All) {
                ret = [self startLongPollingWithTopic:topic filter:filter listener:listener error:error];
                self.pushMethod = PushMethod_Long_Polling;
            } else {
               [[NSException exceptionWithName:NSGenericException
                                        reason:@"Web sockets not available"
                                      userInfo:nil] raise];
           }
        }
    } else {
        ret = [self startLongPollingWithTopic:topic filter:filter listener:listener error:error];
    }
    if (ret) {
        [self.listeners addObject:ret];
    } else {
        *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                 userInfo:@{NSLocalizedDescriptionKey:@"Can't add listener"}];
    }
    
    return ret;

}


- (NSString*)startLongPollingWithTopic:(NSString*)topic filter:(NSString*)filter listener:(__weak id <QCServiceGatewayEventListener>)listener error:(NSError *__autoreleasing *)error{
    self.pushImplementation = self.polling;
    return [self.polling addEventListenerWithTopic:topic filter:filter listener:listener error:error];

}

- (void) removeEventListenerWithID:(NSString *)listenerID error:(NSError *__autoreleasing *)error{
    if (!self.pushImplementation) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                     userInfo:@{NSLocalizedDescriptionKey: @"No Listener"}];
        }
        return;
    }
    [self.pushImplementation removeEventListenerWithID:listenerID error:error];
    [self.listeners removeObject:(listenerID)];
}

- (void) removeAllEventListenersWithError:(NSError *__autoreleasing *)error{
    if (!self.pushImplementation) {
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                     userInfo:@{NSLocalizedDescriptionKey: @"No Listener"}];
        }
        return;
    }
    
    NSString* id;
    
    for (id in self.listeners) {
        [self.pushImplementation removeEventListenerWithID:id error:error];
        if (error) {
            *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                     userInfo:@{NSLocalizedDescriptionKey: @"No Listener"}];
            return;
        }
    }
    
    [self.listeners removeAllObjects];
}

- (NSString*) serviceGatewayId{
    return [self.pushImplementation serviceGatewayId];
}

- (PushMethod)pushMethodType{
    return [self.pushImplementation pushMethodType];
}

@end
