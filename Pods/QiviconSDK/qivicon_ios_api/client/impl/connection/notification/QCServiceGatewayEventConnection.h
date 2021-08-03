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

@protocol QCServiceGatewayEventListener; // Forward declaration necessary

#import <Foundation/Foundation.h>
#import "QCServiceGatewayEventListener.h"
#import "QCConnection.h"

@class QCServiceGatewayConnection;
@class QCWebSocketConnectionFactory;
@protocol QCCertificateDataStore;

typedef enum PushMethod {
	PushMethod_All,
	PushMethod_WebSocket,
	PushMethod_Long_Polling
} PushMethod;

/**
 * This connection uses internally a {@link QCServiceGatewayConnection} to
 * subscribe to events of that specific <i>Service Gateway</i>.
 * {@link QCServiceGatewayEventListener} is used to handle such
 * {@link QCServiceGatewayEvent}s.
 * <p>
 * Methods are provided to subscribe to specific properties (e. g.
 * <code>"com/qivicon/sample/push/ *"</code>) using a filter in LDAP-style to
 * filter only the events of a specific source (e. g.
 * <code>"(filter.name=TEST_FILTER)"</code>).
 * <p>
 * Internally the class provides two different methods for subscription:
 * <ul>
 * <li><i>WebSockets</i> - Used, if the underlying
 * {@link QCServiceGatewayConnection} supports web sockets
 * <li><i>LongPolling</i> - Used, if the underlying
 * {@link QCServiceGatewayConnection} does not support web sockets or if a remote
 * connection is being used.
 * </ul>
 * <p>
 * {@link QCConnectionFactory#gatewayEventConnectionWithConnection:}
 * must be used to establish this connection. The factory decides about the
 * underlying implementation, whether web sockets could be used or not.
 * <p>
 */
@protocol QCServiceGatewayEventConnection <NSObject>

/**
 * Add a listener for events. The listener will be called for all events
 * fired on the specific topic matching the provided filter.
 *
 * @param topic
 *            Topic to subscribe to.
 * @param filter
 *            The event filter in LDAP style syntax. May be null.
 * @param listener
 *            listener to call
 * @param error
 *            error object
 * @return id of created listener
 * @throws Exception
 *             Thrown on argument errors.
 */
- (NSString*) addEventListenerWithTopic:(NSString*)topic
                                 filter:(NSString*)filter
                               listener:(id <QCServiceGatewayEventListener>)
listener error:(NSError *__autoreleasing *)error;

/**
 * Remove a listener specified by it's id. If the listener with that
 * specific id does not exist, nothing happens.
 *
 * @param listenerID
 *            listener id
 * @param error
 *            error object
 */
- (void) removeEventListenerWithID:(NSString *)listenerID error:(NSError *__autoreleasing *)error;

/**
 * Remove all registered event listeners.
 *
 * @param error
 *            error object
 */
- (void) removeAllEventListenersWithError:(NSError *__autoreleasing *)error;

/**
 * Get the Service Gateway ID from the underlying Service Gateway connection.
 *
 * @return Service Gateway id
 * @throws Exception
 *             Thrown when no listener was added.
 */
- (NSString*) serviceGatewayId;

/**
 * Get the push method type of the underlying connection. The specific type
 * of the selected connection is returned, either
 * PushMethod_WEBSOCKETlink or PushMethod_LONG_POLLING;
 * PushMethod_ALL is never returned.
 *
 * @return type of underlying connection
 * @throws Exception
 *             Thrown when no listener was added.
 */
- (PushMethod)pushMethodType;

@end

@interface QCServiceGatewayEventConnection : QCConnection <QCServiceGatewayEventConnection>
/**
 * Initializes the connection to receive events from a <i>Service
 * Gateway</i>. Depending on the type of the underlying connection and the
 * specified <i>pushMethod</i> an implementation is chosen later.
 * <p>
 * Note, that the push method is not verified in this constructor! The first
 * attempt to add an event listener with
 * {@link #addEventListener(String, String, ServiceGatewayEventListener)}
 * verifies the push method and chooses the correct implementation.
 *
 * @param globalSettings
 *            global settings which will be used to establish the
 *            connection
 * @param connection
 *            underlying {@link ServiceGatewayConnection}, must be
 *            authorized
 * @param websocketURL
 *            URL for web socket connections
 * @param pushMethod
 *            Configures, which push method is allowed:
 *            <ul>
 *            <li><code>ALL</code>: The connection makes a decision which
 *            implementation to be used. If a web socket connection might be
 *            possible but is not working, an automatic fallback to long
 *            polling is provided. <li><code>WEBSOCKET</code>: Use web
 *            sockets <li><code>LONG_POLLING</code>: Use long polling
 *            </ul>
 *
 * @return intialized object
 *
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
  webSocketConnectionFactory:(QCWebSocketConnectionFactory*)wsFactory
                  connection:(QCServiceGatewayConnection*)connection
                websocketURL:(NSString*)websocketURL
                  pushMethod:(PushMethod)pushMethod;
@end
