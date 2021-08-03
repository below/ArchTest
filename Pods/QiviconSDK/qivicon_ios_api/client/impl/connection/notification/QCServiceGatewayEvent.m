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
//  QCServiceGatewayEvent.m
//  qivicon_ios_api
//
//  Created by m.fischer on 23.01.13.
//

#import "QCServiceGatewayEvent.h"

NSString * const  SEQUENCE_NR = @"com.qivicon.services.remote.event.sequence.number";
NSString * const  FILTER = @"filter.name";
NSString * const  TIMESTAMP = @"timestamp";

@interface QCServiceGatewayEvent ()

@property (readwrite) long long sequenceNumber;
@property (readwrite) long long timestamp;
@property (readwrite) NSString *topic;
@property (readwrite) NSString *filter;
@property (readwrite) NSString *serviceGatewayId;
@property (readwrite) NSDictionary* content;

@end


@implementation QCServiceGatewayEvent


- (id)initWithGWID:(NSString *)gwID topic:(NSString*)topic content:(NSDictionary*)content{
 
    if (!gwID || !topic || !content) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Argmuents must not be null" userInfo:nil] raise];
     }

    self = [super init];
    if (self) {
        self.serviceGatewayId = gwID;
        self.topic = topic;
        self.content = content;
        self.sequenceNumber = [(NSNumber*)[content objectForKey:SEQUENCE_NR] longLongValue];
        self.timestamp = [(NSNumber*)[content objectForKey:TIMESTAMP] longLongValue];
        self.filter = [content objectForKey:FILTER];

    }
    return self;
}


- (NSString*) contentForKey:(NSString*)key{
    return [self.content objectForKey:key];
}

@end