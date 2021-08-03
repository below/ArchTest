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
//  QCLongPollingDispatchedCall.m
//  qivicon_ios_api
//
//  Created by m.fischer on 23.01.13.
//

#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCLongPollingDispatchedCall.h"
#import "QCServiceGatewayConnection.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCLongPolling.h"
#import "QCResultElement.h"
#import "QCLogger.h"

@interface QCLongPollingDispatchedCall ()
@property(readwrite)id<QCServiceGatewayEventConnection> eventConnection;
@property(readwrite, weak)id<QCServiceGatewayEventListener> listener;
@end

@implementation QCLongPollingDispatchedCall

/** try to re-synchronize on lost events 3 times */
static int const  NUM_TRY_RESYNC = 3;
static NSString  *PROPERTIES_KEY = @"properties";
static NSString  *TOPIC_KEY = @"topic";
static dispatch_queue_t backgroundQueue = nil;

+ (void) initialize {
    backgroundQueue = dispatch_queue_create("de.qivicon.longpolling", DISPATCH_QUEUE_CONCURRENT);
}

- (id)init{
    
    self = [super init];
    
    if (self) {
   }
    
    return self;
}


- (void)startLongPollingForSubscriptionID:(NSString*)subscriptionID
                          eventConnection:(id<QCServiceGatewayEventConnection>)eventConnection
                               connection:(QCServiceGatewayConnection *)conn
                                  timeout:(int)timeout
                                 listener:(__weak id<QCServiceGatewayEventListener>)listener {
    self.eventConnection = eventConnection;
    self.listener = listener;
    
    dispatch_async(backgroundQueue, ^{
        leaveLoop = NO;
        int seqNr = -1;
        int numLostEvents = 0;
        int resync = NUM_TRY_RESYNC;
        do {
            NSError *error = nil;
            NSArray *returnedResponse = [conn callWithError:&error methods:[QCRemoteMethod remoteMethodWithName:POLL parameters:subscriptionID, [NSNumber numberWithInt:timeout], [NSNumber numberWithInt:seqNr < 1 ? 0 : seqNr - 1],nil], nil];
            
            if (error) {
                [self performSelectorOnMainThread:@selector(listenerOnError:) withObject:error waitUntilDone:NO];
            }
            
            NSString *gwId = conn.gwId;
            
            QCResultElement *element = [returnedResponse firstObject];
            
            for (NSDictionary *event in element.result) {
                
                if (leaveLoop) {
                    break;
                }
                NSDictionary *properties = [event valueForKey:PROPERTIES_KEY];
                NSString *topic = [event valueForKey:TOPIC_KEY];
                
                NSNumber *curSeqNr = [properties objectForKey:SEQUENCE_NR];
                
                
                if (curSeqNr) {
                    /*
                     * The event lost detection mechanism is supported. the
                     * detection bases on sequence numbers. Every event sent
                     * by the 'Remote Event Admin' service will add an
                     * increasing number to events, so that the loss of
                     * events can be detected if there is a gap between the
                     * received sequence number and the expected one.
                     */
                    int curSeq = [curSeqNr intValue];
                    if (seqNr == -1) {
                        // synchronize
                        seqNr = curSeq;
                    }
                    
                    if (seqNr != curSeq) {
                        numLostEvents = curSeq - seqNr;
                        resync--;
                        break;
                    } else {
                        seqNr++;
                        resync = NUM_TRY_RESYNC;
                        
                        QCServiceGatewayEvent *event = [[QCServiceGatewayEvent alloc] initWithGWID:gwId
                                                                                             topic:topic
                                                                                           content:properties];
                        [self performSelectorOnMainThread:@selector(listenerOnEvent:) withObject:event waitUntilDone:NO];
                    }
                } else {
                    // sequence numbers not supported
#warning This is not working!
                    if (properties && topic) {
                        QCServiceGatewayEvent *event = [[QCServiceGatewayEvent alloc] initWithGWID:gwId topic:topic content:properties];
                        
                        [self performSelectorOnMainThread:@selector(listenerOnEvent:) withObject:event waitUntilDone:NO];
                    }
                    else
                        [[QCLogger defaultLogger] error:@"Bad notification received! %@", returnedResponse];
                }
            }
            
            // check if number of resync exceeded
            if (resync < 0) {
                [self performSelectorOnMainThread:@selector(listenerOnEventsLost:) withObject:[NSNumber numberWithInt:numLostEvents] waitUntilDone:NO];
                leaveLoop = YES;
            }
        } while (!leaveLoop);
    });
}

- (void)listenerOnEvent:(QCServiceGatewayEvent*)event{
    [self.listener onEvent:event connection:self.eventConnection];
}

- (void)listenerOnEventsLost:(NSNumber*)lostEvents{
    [self.listener onEventsLost:[lostEvents intValue] connection:self.eventConnection];
}

- (void)listenerOnError:(NSError*)error{
    [self.listener onError:error connection:self.eventConnection];
}

-(void)cancel{
    leaveLoop = YES;
}

@end

