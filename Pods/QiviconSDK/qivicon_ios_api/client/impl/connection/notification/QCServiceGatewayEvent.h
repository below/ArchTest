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
//  QCServiceGatewayEvent.h
//  qivicon_ios_api
//
//  Created by m.fischer on 23.01.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const  SEQUENCE_NR;
extern NSString * const  FILTER;
extern NSString * const  TIMESTAMP;

/**
 * Events are fired from the Event Admin of the <i>Service Gateway</i>.
 */
@protocol QCServiceGatewayEvent <NSObject>

/**
 * Get the sequence number of this event.
 *
 * @return sequence number
 */
@property (readonly) long long sequenceNumber;

/**
 * Get the time of the event occurrence.
 *
 * @return time as long value
 */
@property (readonly) long long timestamp;

/**
 * Get the topic that fired this event.
 *
 * @return topic
 */
@property (readonly) NSString *topic;

/**
 * Get the filter used to select this event.
 *
 * @return filter
 */
@property (readonly) NSString *filter;

/**
 * Get event content items. Return nil if no content available. *
 * @return event content
 */
@property (readonly) NSDictionary *content;

/**
 * Get event content item for key. Return nil if no content available for
 * the key specified.
 *
 * @param key
 *            key to look up
 * @return event content
 */

- (NSString*) contentForKey:(NSString*)key;
/**
 * Get Service Gateway ID that fired the event.
 *
 * @return ServiceGatewayID
 */
@property (readonly) NSString *serviceGatewayId;

@end

@interface QCServiceGatewayEvent : NSObject <QCServiceGatewayEvent>

/**
 * Creates a QIVICON event.
 *
 * @param gwID
 *            Service Gateway ID that fired the event
 * @param topic
 *            Event topic
 * @param content
 *            Event content
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id)initWithGWID:(NSString *)gwID topic:(NSString*)topic content:(NSDictionary*)content;

@end
