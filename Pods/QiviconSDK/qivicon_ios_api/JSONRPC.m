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
//  JSONRPC.m
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 11.01.13.
//

#import "JSONRPC.h"
#import "QCResultElement.h"

NSString * JSONRPCErrorDomain  =  @"com.qivicon.client.errors.remoteInvocation";

NSInteger cannotConvertToTargetClass = 1;   // Unable to convert the result to the intended target class
NSInteger resultClassUnknown = 2;           // The result from the backend were not key/value pairs

@implementation JSONRPC
+ (id) resultFromJsonData:(id)jsonData asClass:(Class)class error:(NSError * __autoreleasing *)error {
    // get error element
    NSError *jsonError = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:&jsonError];
    if (jsonError != nil) {
        if (error != nil)
            *error = jsonError;
        return nil;
    }
    
    // OK, here is the batch change
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[jsonObject count]];
        for (NSDictionary * jsonResponse in jsonObject) {
            QCResultElement *batchResultElement = [QCResultElement batchResultElementWithJSONDictionary:jsonResponse];
            [resultArray addObject:batchResultElement];
        }
        return resultArray;
    }
    else {
        
        id e =  jsonObject[@"error"];   // All hail the new Literal Overloards
            if (e != nil && [e isKindOfClass:[NSDictionary class]]) {
                id code = e[@"code"];
                id message = e[@"message"];
                if (message != nil) {
                *error = [[NSError alloc] initWithDomain:JSONRPCErrorDomain
                                                    code:[code intValue]
                                                userInfo:@{NSLocalizedDescriptionKey:message}];
                    return nil;
                }
                else {
                    return e;
                }
        }
        
        id result = jsonObject[@"result"];
        if (result == nil)
            result = jsonObject; // This is to handle the OAuthErrors
        if (class == nil || class == [NSObject class])
            return result;
        else {
            id classedResult = [[class alloc] init];
            if ([result isKindOfClass:[NSDictionary class]]) {
                for (NSString *key in result) {
                    id value = result[key];
                    
                    @try {
                        [classedResult setValue:value forKey:key];
                    }
                    @catch (NSException *exception) {
                        if (error)
                            *error = [[NSError alloc] initWithDomain:JSONRPCErrorDomain
                                                                code:cannotConvertToTargetClass
                                                            userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unable to convert result to class %@", class],
                                    NSLocalizedFailureReasonErrorKey:[result description]}];
                        return nil;
                        
                    }
                }
                return classedResult;
            }
            else {
                if (error)
                    *error = [[NSError alloc] initWithDomain:@"com.qivicon.client.errors.jsonrpc"
                                                        code:resultClassUnknown
                                                    userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unable to convert result to class %@", class],
                            NSLocalizedFailureReasonErrorKey:[result description]}];
                return nil;
            }
        }
    }
}

+ (NSDictionary *) methodDictionaryWithMethod:(QCRemoteMethod *)method {
    
    NSMutableDictionary *methodDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2.0", @"jsonrpc",
                                   method.method, @"method",
                                   [NSNumber numberWithInt:method.ID], @"id",
                                   nil];
    NSArray *parameters = method.params;
    
    if (parameters != nil)
        [methodDict setValue:parameters forKey:@"params"];
    
    return methodDict;
}
@end
