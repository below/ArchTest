//
//  QCConnHelperMethodCall.h
//  
//
//  Created by Michael on 17.12.15.
//
//

#import <Foundation/Foundation.h>

@protocol QCHTTPConnectionContext;
@protocol QCHTTPConnectionContextDelegate;
@protocol QCConnectionDelegate;

@interface QCConnHelperMethodCall : NSObject
@property(nonatomic, readwrite, strong)NSMutableURLRequest *request;
@property(nonatomic, readwrite, strong)NSArray *methods;
@property(nonatomic, readwrite, weak)id<QCHTTPConnectionContextDelegate> contextDelegate;
@property(nonatomic, readwrite, weak)id <QCConnectionDelegate> remoteCallDelegate;
@property(nonatomic, readwrite, strong) NSString *customIdentifier;
@property(nonatomic, readwrite, strong) NSString *gwID;
@property(nonatomic, readwrite, strong) NSNumber *requestID;
@property(nonatomic, readwrite)BOOL executed;
@property(nonatomic, readwrite)BOOL asyncCall;
@property(nonatomic, readwrite, strong)id result;
@property(nonatomic, readwrite, strong)NSError *error;
@property(nonatomic, readwrite, strong) id classOfT;
@end
