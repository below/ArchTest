//
//  QCCertificateManager.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 15.11.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QCCertificateStorageDelegate <NSObject>
- (NSData * __nullable) certificateDataForGwID:(NSString * __nonnull) gwID;
- (void) storeCertificateForCurrentGwID:(SecCertificateRef _Nonnull )certificate;
@end

@protocol QCCertificateDataStore <NSObject>

- (NSArray * _Nonnull)certificates;

@end

@interface QCCertificateManager : NSObject <NSURLSessionDelegate, QCCertificateDataStore>
    
@property (nonatomic, nonnull) NSString *gwID;
@property (weak, nullable) id<QCCertificateStorageDelegate> certificateStorage;

- (id _Nonnull ) init __attribute((unavailable("Call initWithGwID!")));

- (instancetype __nonnull) initWithGwID:(NSString * __nonnull)gwID;
    
@end
