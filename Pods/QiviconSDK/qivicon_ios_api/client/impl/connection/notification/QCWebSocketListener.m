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

#import "QCWebSocketListener.h"
#import <SocketRocket/SRWebSocket.h>
#import "QCErrors.h"

@interface QCWebSocketListener()

@property (readwrite) NSString* subscriptionID;
@property (readwrite) id<QCServiceGatewayEventConnection> eventConnection;
@property (readwrite) QCServiceGatewayConnection* conn;
@property (readwrite) NSString* gwID;
@property (readwrite, weak) id<QCServiceGatewayEventListener> listener;
@property (readwrite) SRWebSocket* socket;
@property (nonatomic, weak) NSTimer *pingTimer;

@end

@implementation QCWebSocketListener

static NSString const  *PROPERTIES_KEY = @"properties";
static NSString const  *TOPIC_KEY = @"topic";

- (void) startSocketListenerForSubscriptionID:(NSString*)subscriptionID
                           eventConnection:(id<QCServiceGatewayEventConnection>)eventConnection
                                connection:(QCServiceGatewayConnection*)conn
                                      gwID:(NSString*)gwID
                                 webSocket:(SRWebSocket*)socket
                                  listener:(__weak id<QCServiceGatewayEventListener>)listener{

    self.listener = listener;
    self.gwID = gwID;
    self.conn = conn;
    self.eventConnection = eventConnection;
    self.subscriptionID = subscriptionID;
    self.socket = socket;
    socket.delegate = self;
    [socket open];
}

- (void)close {
    self.socket.delegate = nil;
    [self.socket close];
    
    if (_pingTimer) {
        [self stopPingTimer];
    }
}

- (void)schedulePingTimer {
    if (!_pingTimer) {
        __weak typeof (self) weakSelf = self;
        NSTimer *timer = [NSTimer timerWithTimeInterval:15 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if(weakSelf.socket.readyState == SR_OPEN) {
                [weakSelf.socket sendPing:[NSData data]];
            }
        }];
        _pingTimer = timer;
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}
- (void)stopPingTimer {
    [self.pingTimer invalidate];
    self.pingTimer = nil;
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self.listener onConnectionEstablished:self.eventConnection];
    [self schedulePingTimer];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self.listener onError:error connection:self.eventConnection];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSError *jsonError = nil;

    QCServiceGatewayEvent *event = nil;

    if (message) {
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:0
                                                                     error:&jsonError];
        if (jsonError == nil) {
            NSDictionary *properties = [jsonObject objectForKey:PROPERTIES_KEY];
            NSString *topic = [jsonObject objectForKey:TOPIC_KEY];
            
            if (properties && [properties isKindOfClass:[NSDictionary class]] && topic && [topic isKindOfClass:[NSString class]]) {
                event = [[QCServiceGatewayEvent alloc] initWithGWID:self.gwID topic:topic content:properties];
            }
        }
        
    }

    if (event) {
        [self.listener onEvent:event connection:self.eventConnection];
    }

}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if (!wasClean) {
        NSError *error = [[NSError alloc] initWithDomain:QCErrorDomainConnector
                                           code:code
                                       userInfo:@{NSLocalizedDescriptionKey:reason}];
        [self.listener onError:error connection:self.eventConnection];
    } else {
        if ([self.listener respondsToSelector:@selector(onConnectionClosed:)]) {
            [self.listener onConnectionClosed:self.eventConnection];
        }
    }
    
    if (_pingTimer) {
        [self stopPingTimer];
    }
}

@end
