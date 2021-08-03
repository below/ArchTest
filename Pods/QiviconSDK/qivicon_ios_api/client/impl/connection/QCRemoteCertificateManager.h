//
//  QCRemoteCertificateManager.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 15.02.19.
//  Copyright © 2019 Deutsche Telekom AG. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol QCCertificateDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface QCRemoteCertificateManager : NSObject <NSURLSessionDelegate, QCCertificateDataStore>

@end

NS_ASSUME_NONNULL_END
