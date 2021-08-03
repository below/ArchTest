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
//  QCRemoteMethod.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 19.03.13.
//

#import "QCRemoteMethod.h"
#import "QCUtils.h"
#import "QCJsonRpcIDProvider.h"

@implementation QCRemoteMethod

- (id) init {
    // This will fail, which is intentional
    return [self initWithMethod:nil];
}

// Desginated Initializer
- (id) initWithId:(int)ID method:(NSString *)method parameterArray:(NSArray *)params {
    if (method.length == 0)
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Method must not be null or empty!" userInfo:nil] raise];
    
    if (( self = [super init] )) {
        self.ID = ID;
        self.method = method;
        self.params = params;
    }
    return self;
}

- (id) initWithMethod:(NSString *)method {
    return [self initWithMethod:method parameterArray:nil];
}

+ (QCRemoteMethod *) remoteMethodWithName:(NSString *)methodName {
    QCRemoteMethod *newMethod = [[[self class] alloc] initWithMethod:methodName];
    return newMethod;
}

+ (QCRemoteMethod *) remoteMethodWithName:(NSString *)method parameters:(id)firstParam, ... NS_REQUIRES_NIL_TERMINATION {
    
    NSArray *paramArray = nil;
    if (firstParam) {
        va_list argumentList;
        va_start(argumentList, firstParam); // Start scanning for arguments after firstObject.
        paramArray = [QCUtils arrayWithParameter:firstParam va_list:argumentList];
        va_end(argumentList);
    }

    return [[[self class] alloc] initWithMethod:method parameterArray:paramArray];
}

+ (QCRemoteMethod *) remoteMethodWithId:(int)identifer
                                 method:(NSString *)method
                             parameters:(id)firstParam, ... NS_REQUIRES_NIL_TERMINATION __attribute__((deprecated)){
    NSArray *paramArray = nil;
    if (firstParam) {
        va_list argumentList;
        va_start(argumentList, firstParam); // Start scanning for arguments after firstObject.
        paramArray = [QCUtils arrayWithParameter:firstParam va_list:argumentList];
        va_end(argumentList);
    }
    
    return [[[self class] alloc] initWithId:identifer method:method parameterArray:paramArray];

}

- (id) initWithMethod:(NSString *)method parameterArray:(NSArray *)params {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    return [self initWithId:[QCJsonRpcIDProvider sharedInstance].nextId
                     method:method parameterArray:params];
#pragma clang diagnostic pop
}

- (NSString *) description {
    return [NSString stringWithFormat:@"%@(%@)", self.method, self.params];
}

/**
 * Compares the specified object with this RemoteMethod. Returns
 * <code>true</code> only if both objects have the same method name, same id
 * and the same parameter list.
 *
 * @param obj
 *            the object to be compared for equality
 * @return <code>YES</code> if the specified object is equal to this
 *         RemoteMethod
 */
- (BOOL) isEqual:(id)object {
    BOOL ret = NO;
    
    if (object != nil && [object isKindOfClass:[self class]]) {
        QCRemoteMethod *r = (QCRemoteMethod *)object;
        ret = [r.method isEqual:self.method] && r.ID == self.ID && [self.params isEqual:r.params];
    }
    return ret;
}
/**
 * Returns the hash code for this object. Hash code is calculated using the
 * following calculation:
 *
 * <pre>
 * method.hashCode + id + params.hashCode()
 * </pre>
 *
 * This ensures that <code>remoteMethod.equals(remoteMethod)</code> implies
 * that <code>remoteMethod.hashCode()==remoteMethod.hashCode()</code> for
 * any two remote methods, as required by the general contract of
 * <code>Object.hashCode()</code>.
 *
 * @return the hash code value for this object
 */
- (NSUInteger) hash {
    return [self.method hash] + self.ID + [self.params hash];
}

@end
