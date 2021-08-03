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

/**
 * This protocol must be implemented to handle events from a <i>Service
 * Gateway</i>. The following methods must be implemented:
 * <ul>
 * <li>{@link #onEvent(ServiceGatewayEvent)} - This method is called for each
 * event the method is registered for. The event fired will be available as
 * method parameter.
 * <li>{@link #onError(String)} - On any error that would usually result in an
 * exception this method will be called. The error message is provided as a
 * parameter.
 * <li>{@link #onEventsLost(long)} - If events have been lost, this method will
 * be used for notification. The parameter specifies the number of lost events.
 * </ul>
 */

@protocol QCServiceGatewayEventConnection; // Forward declaration necessary

#import <Foundation/Foundation.h>
#import "QCServiceGatewayEvent.h"

@protocol QCServiceGatewayEventConnection;
@protocol QCServiceGatewayEventListener <NSObject>

/**
 * Called if the event this listener is registered for has been fired.
 * Implement this method to handle the event notifications.
 *
 * @param event
 *            Fired event. Cannot be null nor empty.
 * @param connection
 *            Event source connection. cannot be null or empty.
 *
 */
- (void) onEvent:(id<QCServiceGatewayEvent>)event connection:(id<QCServiceGatewayEventConnection>)connection;

/**
 * If any error occurs in the underlying event listening connection, this
 * method will be called. The message will specify the error in more detail.
 * Implement this method to handle possible exceptions.
 *
 * @param connection
 *            Event source connection. cannot be null or empty.
 * @param error
 *            Error object.
 */
- (void) onError:(NSError*)error connection:(id<QCServiceGatewayEventConnection>)connection;

/**
 * This method notifies the listener if events have been lost. As the Event
 * Admin numbers all events this could be easily recognized.
 * <p>
 * Please note, that this method should be used only to be informed about
 * event loss, there is <strong>no need</strong> to handle lost events. The
 * framework tries to re-synchronize and to retrieve missing events. If this
 * fails, {@link #onError(String)} will be called.
 *
 * @param numLostEvents
 *            Number of lost events.
 * @param connection
 *            Event source connection. cannot be null or empty.
 */
- (void) onEventsLost:(int)numLostEvents connection:(id<QCServiceGatewayEventConnection>)connection;

@optional
/**
 * If the websocket was closed without an error, this
 * method will be called. The message will specify the error in more detail.
 * Implement this method to handle possible exceptions.
 *
 * @param connection
 *            Event source connection. cannot be null or empty.
 */
- (void) onConnectionClosed:(id<QCServiceGatewayEventConnection>)connection;

/**
 * Called if a sockent connection is open
 * @param connection
 *            Event source connection. cannot be null or empty.
 *
 */
- (void) onConnectionEstablished:(id<QCServiceGatewayEventConnection>)connection;

@end
