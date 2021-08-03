//
//  QCCertificateManager.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 15.11.13.
//  Copyright (c) 2013 Deutsche Telekom AG. All rights reserved.
//

#import "QCCertificateManager.h"

@implementation QCCertificateManager
- (id)init __attribute((unavailable("Call initWith Session!")))
{
    NSAssert(NO, @"Call initWith Session!");
    return nil;
}

- (instancetype) initWithGwID:(NSString*)gwID {
    if (self = [super init]) {
        self.gwID = gwID;
    }
    return self;
}

#pragma mark - QCCertificateDataStore methods
- (NSArray *)certificates {
    NSMutableArray *certificates = [[NSMutableArray alloc] init];
    if (self.certificateStorage) {
        NSData * certData = [self.certificateStorage certificateDataForGwID:self.gwID];
        SecCertificateRef existingCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        [certificates addObject:CFBridgingRelease(existingCert)];
    }
    
    return certificates;
}

#pragma mark - NSURLSessionDelegate methods
    // Important: This is for local connections to a HomeBase
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler{
    
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust ) {
        
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        SecTrustResultType secTrustResult;
        
        // First thing: disable strict namechecking
        
        trust = [self createNamespaceIndependentTrust:trust];
        
        NSAssert(self.gwID.length > 0, @"gwID must be set in QCCertificateManager!");
        NSData * certData = [self.certificateStorage certificateDataForGwID:self.gwID];
        SecCertificateRef existingCert = SecCertificateCreateWithData(nil, CFBridgingRetain(certData));
        
        if (existingCert == nil) { // If there is no existing certificate for this gwID
            CFIndex certCount = SecTrustGetCertificateCount(trust);
            if (certCount > 0) {
                existingCert = SecTrustGetCertificateAtIndex(trust, certCount -1);
                [self.certificateStorage storeCertificateForCurrentGwID:existingCert];
            }
        }
        if (existingCert != nil) {
            // If we have an existing certificate for the box, we add the certificate …
            
            OSStatus status = SecTrustSetAnchorCertificates(trust, (__bridge CFTypeRef _Nonnull)([NSArray arrayWithObject:CFBridgingRelease(existingCert)]));
            status = SecTrustSetAnchorCertificatesOnly(trust, YES);
        }
        
        SecTrustEvaluate(trust, &secTrustResult);
        switch (secTrustResult) {
            case kSecTrustResultProceed:
            case kSecTrustResultUnspecified:
            completionHandler (NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:trust]);
            break;
            
            case kSecTrustResultRecoverableTrustFailure:
            // This actually means we have a mismatching certificate
            default:
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            break;
        }
        
        return;
    }
    else {
        // We don't handle this kind of challenge
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma mark - Private methods
- (SecTrustRef __nullable) createNamespaceIndependentTrust:(SecTrustRef)trust {
    NSMutableArray * newChain = [NSMutableArray new];
    SecTrustRef newTrust = NULL;
    
    for (CFIndex i = 0; i < SecTrustGetCertificateCount(trust); i++) {
        SecCertificateRef certRef = SecTrustGetCertificateAtIndex(trust, i);
        [newChain addObject:CFBridgingRelease(certRef)];
    }
    
    if (SecTrustCreateWithCertificates((__bridge CFTypeRef _Nonnull)(newChain), SecPolicyCreateBasicX509(), &newTrust) == noErr) {
        return newTrust;
    }
    else {
        return nil;
    }
}

@end
