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
//  QCJsonRpcIDProvider.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 21.10.13.
//

#import "QCJsonRpcIDProvider.h"

@interface QCJsonRpcIDProvider () {
    int _nextId;
    NSLock * _idLock;
}
@end

@implementation QCJsonRpcIDProvider

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[super alloc] initSharedObject];
    });
    return _sharedObject;
}

- (id)initSharedObject {
    if (( self = [super init])) {
        _nextId = 1;
        _idLock = [[NSLock alloc] init];
    }
    return self;
}

- (int) nextId {
    [_idLock lock];
    int next = _nextId++;
    [_idLock unlock];
    return next;
}

@end
