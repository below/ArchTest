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
//  QCBatchResultElement.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.03.13.
//

#import "QCResultElement.h"
#import "JSONRPC.h"

@interface QCResultElement ()
@property int Id;
@property NSError *error;
@property (strong) id result;
@end

@implementation QCResultElement

- (id)init {
    return [self initWithId:1 result:nil];
}

- (id) initWithId:(int)Id result:(id)result {
    if (( self = [super init])) {
        self.result = result;
        self.Id = Id;
    }
    return self;
}

+ (QCResultElement *) batchResultElementWithJSONDictionary:(NSDictionary *)jsonElement {
    id e =  jsonElement[@"error"];   // All hail the new Literal Overloards
    id result = jsonElement[@"result"];
    int Id = [jsonElement[@"id"] intValue];
    NSError *error = nil;
    if (e != nil && [e isKindOfClass:[NSDictionary class]]) {
        id code = e[@"code"];
        id message = e[@"message"];
        NSDictionary *userInfo = nil;
        
        // One error can be:
        
        // -32601
        // "Cannot find Module/Service with PID:SMHM"
        
        if (message != nil)
            userInfo = @{NSLocalizedDescriptionKey:message};
        error = [[NSError alloc] initWithDomain:JSONRPCErrorDomain
                                            code:[code intValue]
                                        userInfo:userInfo];
    }
    QCResultElement *bre = [[QCResultElement alloc] initWithId:Id result:result];
    if (error)
        bre.error = error;
    return bre;
}

- (BOOL) hasError {
    return self.error != nil;
}
    
- (NSString *) description {
    if (self.hasError)
        return [NSString stringWithFormat:@"Error: %@", self.error.description];
    else
        return [NSString stringWithFormat:@"<ID:%d> %@", self.Id, self.result];
}

@end
