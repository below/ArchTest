//
//  QCConnHelper.h
//  
//
//  Created by Michael on 16.12.15.
//
//

#import <Foundation/Foundation.h>
#import "QCConnHelperMethodCall.h"


@protocol QCHTTPConnectionContext;
@protocol QCHTTPConnectionContextDelegate;
@protocol QCConnectionDelegate;

@interface QCConnHelper : NSObject


- (id _Null_unspecified) init __attribute((unavailable("Call initWithSession!")));

- (id _Nonnull)initWithSession:(NSURLSession * __nonnull)session;

- (id _Nullable)callRPCWithClass:(id _Nonnull)classOfT url:(NSURL* _Nonnull)url authToken:(NSString * _Nonnull)authToken
                  gwID:(NSString * _Nonnull)gwID
               methods:(NSArray * _Nullable)methods
      customIdentifier:(NSString* _Nonnull)customIdentifier
                 error:(NSError * _Nonnull __autoreleasing * _Nullable)error;

- (QCConnHelperMethodCall* _Nonnull)callRPCAsyncWithClass:(id _Nonnull)classOfT
                                             url:(NSURL* _Nonnull)url
                                       authToken:(NSString * _Nonnull)authToken
                                            gwID:(NSString * _Nonnull)gwID
                                         methods:(NSArray * _Nullable)methods
                                 contextDelegate:(id<QCHTTPConnectionContextDelegate> _Nonnull)contextDelegate
                              remoteCallDelegate:(id <QCConnectionDelegate> _Nonnull)remoteCallDelegate
                                customIdentifier:(NSString* _Nonnull)customIdentifier
                                           error:(NSError * _Nonnull __autoreleasing *  _Nullable)error;

- (void)callRPCAsyncWithURL:(NSURL * _Nonnull)url
                  authToken:(NSString * _Nonnull)authToken
                  gatewayID:(NSString * _Nonnull)gwID
                    methods:(NSArray * _Nonnull)methods
          completionHandler:(void (^_Nullable)(id _Nullable, NSError * _Nullable))completion;
@end
