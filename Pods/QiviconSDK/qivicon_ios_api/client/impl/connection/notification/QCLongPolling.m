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
//  QCLongPolling.m
//  qivicon_ios_api
//
//  Created by m.fischer on 21.01.13.
//

#import "QCLongPolling.h"
#import "QCServiceGatewayConnection.h"
#import "QCLongPollingDispatchedCall.h"
#import "QCErrors.h"
#import "QCHTTPConnectionContext.h"
#import "QCResultElement.h"

NSString * const  POLL = @"RE/longPoll";

@interface QCLongPolling ()
@property (readwrite) QCServiceGatewayConnection* conn;
@property (readwrite) NSMutableDictionary *listeners;
@end


@implementation QCLongPolling

static NSString * const  SUBSCRIBE = @"RE/subscribe";
static NSString * const  UNSUBSCRIBE = @"RE/unsubscribe";
static int  const  TIMEOUT = 20;


- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                  connection:(QCServiceGatewayConnection*)connection {
    
    self = [super initWithGlobalSettings:globalSettings sessionDelegate:nil];
    
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
        
        self.conn = connection;
        self.listeners = [NSMutableDictionary new];
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
   
    NSError *conError = nil;
    QCRemoteMethod * method;
    if (filter) {
        method = [QCRemoteMethod remoteMethodWithName:SUBSCRIBE parameters:topic, filter, nil];

    } else {
        method = [QCRemoteMethod remoteMethodWithName:SUBSCRIBE parameters:topic, nil];
    }

    QCResultElement *callResult = [[self.conn callWithMethod:method error:&conError]
                      firstObject];

    if (conError) {
        if (error)
            *error = conError;
        return nil;
    }
    
    NSString *subscriptionID = callResult.result;

    if ([subscriptionID length] > 0){

        QCLongPollingDispatchedCall *poll = [[QCLongPollingDispatchedCall alloc] init];
        if (poll) {
            [self.listeners setValue:poll forKey:subscriptionID];
            [poll startLongPollingForSubscriptionID:subscriptionID eventConnection:self connection:self.conn timeout:TIMEOUT listener:listener];
        } else {
            *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                     userInfo:@{NSLocalizedDescriptionKey:@"Can't add listener"}];
        }
    }
   
    return subscriptionID;
}

- (void) removeEventListenerWithID:(NSString *)listenerID error:(NSError *__autoreleasing *)error{
    QCLongPollingDispatchedCall *poll = [self.listeners objectForKey:listenerID];
    if (!poll && error) {
        *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"No listener found with id %@", listenerID]}];
    } else {
        [poll cancel];
        NSError *unsubscribeError = nil;
        [self.conn callWithMethod:[QCRemoteMethod remoteMethodWithName:UNSUBSCRIBE parameters:listenerID, nil] error:&unsubscribeError];
        if (unsubscribeError && error) {
            *error = [NSError errorWithDomain:QCErrorDomainListener code:LISTENER_NOT_FOUND
                                     userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Cannot remove listener with id %@ due to %li - %@", listenerID, (long)unsubscribeError.code, unsubscribeError.description]}];
        }
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
            return;
        }
    }
    [self.listeners removeAllObjects];
}

- (NSString*) serviceGatewayId{
    return self.conn.gwId;
}

- (PushMethod)pushMethodType{
    return PushMethod_Long_Polling;
}

@end
