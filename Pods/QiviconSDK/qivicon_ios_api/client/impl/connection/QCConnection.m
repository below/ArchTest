//
//  QCConnection.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 29.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import "QCConnection.h"

@interface QCConnection () {
    QCGlobalSettings * _gbl;
}
@property (readwrite, nonnull) NSURLSession *session;
@property(nonatomic, readwrite, strong) NSOperationQueue *queue;
@end

@implementation QCConnection

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
             sessionDelegate:(id<NSURLSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        _gbl = globalSettings;
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        
        if (@available(iOS 11.0, *)) {
            config.waitsForConnectivity = YES;
            config.timeoutIntervalForResource = 30;
        }
        
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 5;
        self.session = [NSURLSession sessionWithConfiguration:config
                                                     delegate:delegate
                                                delegateQueue:_queue];
    }
    
    return self;
}


- (QCGlobalSettings *) globalSettings {
    return _gbl;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
}

@end
