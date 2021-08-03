//
//  QCRemoteCertificateManager.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 15.02.19.
//  Copyright © 2019 Deutsche Telekom AG. All rights reserved.
//

#import "QCRemoteCertificateManager.h"

static NSString * const globalroot_class_2 = @"MIIDwzCCAqugAwIBAgIBATANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCREUx\
KzApBgNVBAoMIlQtU3lzdGVtcyBFbnRlcnByaXNlIFNlcnZpY2VzIEdtYkgxHzAd\
BgNVBAsMFlQtU3lzdGVtcyBUcnVzdCBDZW50ZXIxJTAjBgNVBAMMHFQtVGVsZVNl\
YyBHbG9iYWxSb290IENsYXNzIDIwHhcNMDgxMDAxMTA0MDE0WhcNMzMxMDAxMjM1\
OTU5WjCBgjELMAkGA1UEBhMCREUxKzApBgNVBAoMIlQtU3lzdGVtcyBFbnRlcnBy\
aXNlIFNlcnZpY2VzIEdtYkgxHzAdBgNVBAsMFlQtU3lzdGVtcyBUcnVzdCBDZW50\
ZXIxJTAjBgNVBAMMHFQtVGVsZVNlYyBHbG9iYWxSb290IENsYXNzIDIwggEiMA0G\
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqX9obX+hzkeXaXPSi5kfl82hVYAUd\
AqSzm1nzHoqvNK38DcLZSBnuaY/JIPwhqgcZ7bBcrGXHX+0CfHt8LRvWurmAwhiC\
FoT6ZrAIxlQjgeTNuUk/9k9uN0goOA/FvudocP05l03Sx5iRUKrERLMjfTlH6VJi\
1hKTXrcxlkIF+3anHqP1wvzpesVsqXFP6st4vGCvx9702cu+fjOlbpSD8DT6Iavq\
jnKgP6TeMFvvhk1qlVtDRKgQFRzlAVfFmPHmBiiRqiDFt1MmUUOyCxGVWOHAD3bZ\
wI18gfNycJ5v/hqO2V81xrJvNHy+SE/iWjnX2J14np+GPgNeGYtEotXHAgMBAAGj\
QjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBS/\
WSA2AHmgoCJrjNXyYdK4LMuCSjANBgkqhkiG9w0BAQsFAAOCAQEAMQOiYQsfdOhy\
NsZt+U2e+iKo4YFWz827n+qrkRk4r6p8FU3ztqONpfSO9kSpp+ghla0+AGIWiPAC\
uvxhI+YzmzB6azZie60EI4RYZeLbK4rnJVM3YlNfvNoBYimipidx5joifsFvHZVw\
IEoHNN/q/xWA5brXethbdXwFeilHfkCoMRN3zUA7tFFHei4R40cR3p1m0IvVVGb6\
g1XqfMIpiRvpb7PO4gWEyS8+eIVibslfwXhjdFjASBgMmTnrpMwatXlajRWc2BQN\
9noHV8cigwUtPJslJj0Ys6lDfMjIq2SPDqO/nBudMNva0Bkuqjzx+zOAduTNrRlP\
BSeOE6Fuwg==";

static NSString * const globalroot_class_3 = @"MIIDwzCCAqugAwIBAgIBATANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCREUx\
KzApBgNVBAoMIlQtU3lzdGVtcyBFbnRlcnByaXNlIFNlcnZpY2VzIEdtYkgxHzAd\
BgNVBAsMFlQtU3lzdGVtcyBUcnVzdCBDZW50ZXIxJTAjBgNVBAMMHFQtVGVsZVNl\
YyBHbG9iYWxSb290IENsYXNzIDMwHhcNMDgxMDAxMTAyOTU2WhcNMzMxMDAxMjM1\
OTU5WjCBgjELMAkGA1UEBhMCREUxKzApBgNVBAoMIlQtU3lzdGVtcyBFbnRlcnBy\
aXNlIFNlcnZpY2VzIEdtYkgxHzAdBgNVBAsMFlQtU3lzdGVtcyBUcnVzdCBDZW50\
ZXIxJTAjBgNVBAMMHFQtVGVsZVNlYyBHbG9iYWxSb290IENsYXNzIDMwggEiMA0G\
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC9dZPwYiJvJK7genasfb3ZJNW4t/zN\
8ELg63iIVl6bmlQdTQyK9tPPcPRStdiTBONGhnFBSivwKixVA9ZIw+A5OO3yXDw/\
RLyTPWGrTs0NvvAgJ1gORH8EGoel15YUNpDQSXuhdfsaa3Ox+M6pCSzyU9XDFES4\
hqX2iys52qMzVNn6chr3IhUciJFrf2blw2qAsCTz34ZFiP0Zf3WHHx+xGwpzJFu5\
ZeAsVMhg02YXP+HMVDNzkQI6pn97djmiH5a2OK61yJN0HZ65tOVgnS9W0eDrXltM\
EnAMbEQgqxHY9Bn20pxSN+f6tsIxO0rUFJmtxxr1XV/6B7h8DR/Wgx6zAgMBAAGj\
QjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBS1\
A/d2O2GCahKqGFPrAyGUv/7OyjANBgkqhkiG9w0BAQsFAAOCAQEAVj3vlNW92nOy\
WL6ukK2YJ5f+AbGwUgC4TeQbIXQbfsDuXmkqJa9c1h3a0nnJ85cp4IaH3gRZD/FZ\
1GSFS5mvJQQeyUapl96Cshtwn5z2r3Ex3XsFpSzTucpH9sry9uetuUg/vBa3wW30\
6gmv7PO15wWeph6KU1HWk4HMdJP2udqmJQV0eVp+QD6CSyYRMG7hP0HHRwA11fXT\
91Q+gT3aSWqas+8QPebrb9HIIkfLzM8BMZLZGOMivgkeGj5asuRrDFR6fUNOuIml\
e9eiPZaGzPImNC1qkp2aGtAw4l1OBLBfiyB+d8E9lYLRRpo7PHi4b6HQDWSieB4p\
TpPDpFQUWw==";

static NSString * const server_Pass_2 = @"MIIFYDCCBEigAwIBAgIEByeyFjANBgkqhkiG9w0BAQsFADBaMQswCQYDVQQGEwJJ\
RTESMBAGA1UEChMJQmFsdGltb3JlMRMwEQYDVQQLEwpDeWJlclRydXN0MSIwIAYD\
VQQDExlCYWx0aW1vcmUgQ3liZXJUcnVzdCBSb290MB4XDTE0MDcwOTE3MTQ1MFoX\
DTIxMDcwOTE3MDkwNFowgdgxCzAJBgNVBAYTAkRFMSUwIwYDVQQKExxULVN5c3Rl\
bXMgSW50ZXJuYXRpb25hbCBHbWJIMR4wHAYDVQQLExVUcnVzdCBDZW50ZXIgU2Vy\
dmljZXMxIDAeBgNVBAMTF1RlbGVTZWMgU2VydmVyUGFzcyBDQSAyMRwwGgYDVQQI\
ExNOb3JkcmhlaW4gV2VzdGZhbGVuMQ4wDAYDVQQREwU1NzI1MDEQMA4GA1UEBxMH\
TmV0cGhlbjEgMB4GA1UECRMXVW50ZXJlIEluZHVzdHJpZXN0ci4gMjAwggEiMA0G\
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDOiwnq/1yGnxwkfemFGfSS2hk4YW3c\
42GhrWjVwzDb7Mp5h0TrM0Dl1CFk0tq7IllMhdvQUjSTjpmu6LswGeEI4riwnSsF\
XqDv83nzTEBx3hCR1N03ioT1Ob9iWCmEhCIskt2AsxPFXB2s1Dspiwg5ZY6OyC4A\
P08ySY+Sl+Fn0b2VUSRJJEaH2lY9NMAN9RKsC0mfTsYN6HAnXgCGVpYLc94Ltbdk\
BO6sevsMn9TBRldq5IFzKd1Dx/r9OJszya1kZSvp/vrSP629JdANRWQVnBoLLJu3\
zp8k6dLG96AD3Z/lYPWurNeAjhP6OPoTg+mB6Lhu+hw06hrXGJzwPGpBAgMBAAGj\
ggGtMIIBqTASBgNVHRMBAf8ECDAGAQH/AgEAMIGbBgNVHSAEgZMwgZAwSAYJKwYB\
BAGxPgEAMDswOQYIKwYBBQUHAgEWLWh0dHA6Ly9jeWJlcnRydXN0Lm9tbmlyb290\
LmNvbS9yZXBvc2l0b3J5LmNmbTBEBgkrBgEEAb1HDQIwNzA1BggrBgEFBQcCARYp\
aHR0cDovL3d3dy50ZWxlc2VjLmRlL3NlcnZlcnBhc3MvY3BzLmh0bWwwQgYIKwYB\
BQUHAQEENjA0MDIGCCsGAQUFBzABhiZodHRwOi8vb2NzcC5vbW5pcm9vdC5jb20v\
YmFsdGltb3Jlcm9vdDAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0lBBYwFAYIKwYBBQUH\
AwEGCCsGAQUFBwMCMB8GA1UdIwQYMBaAFOWdWTCCR1jMrPoIVDaGezq1BE3wMEIG\
A1UdHwQ7MDkwN6A1oDOGMWh0dHA6Ly9jZHAxLnB1YmxpYy10cnVzdC5jb20vQ1JM\
L09tbmlyb290MjAyNS5jcmwwHQYDVR0OBBYEFBW73tYlb73yMZ9iE9xcpvRltG3y\
MA0GCSqGSIb3DQEBCwUAA4IBAQBNSC2Jb3V64H4ivhM2fK53fnvypHgiodSitLvY\
48vy6gWIlbZaac19iroZSDrQC/pcijupH92HQ2V8TPPIa/M1e4iV/ANQTRIyrBiQ\
76N0xpx7wQFn8EdRO0NjCJ3BS+MITK0W4+Dy8/xqTjGbcvTXe9O3I/o4CGUOI93L\
WbxEwulUg/XBm/usvqIu7KEWvl9KJ9E1MX+/xllkkwr3sEBtKzUsMriuQZIPagk4\
Sopmwkt94g8k0xC4L7zkmzOWbc3usSrEJSJmBcclCl0W3+D6enOnNQDQSeTtN82B\
TlYoBJHkStMogP3lYYCI8YZsHAyYxjwAiuSO3dzi1wBs0aiO";

static NSString * const ibs = @"MIIGWTCCBUGgAwIBAgIQDnPXZMiGB6NY9ezlIB5whzANBgkqhkiG9w0BAQsFADBe\
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3\
d3cuZGlnaWNlcnQuY29tMR0wGwYDVQQDExRSYXBpZFNTTCBSU0EgQ0EgMjAxODAe\
Fw0xODAzMDUwMDAwMDBaFw0yMDAzMDQxMjAwMDBaMCcxJTAjBgNVBAMMHCouaW50\
ZXJuZXQtYnVzaW5lc3Mtc3VpdGUuZGUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\
ggEKAoIBAQC7WGILE5zFuN7QFhm4UDo7P1EfxBmnZS49mG2MNpCSaZ/6nNlcMR7V\
TkkEI/KKUFnsxjchuxVB9gLESi8ogre3la+t2k8yI7q5nJsWUmqLoKwe1mXjzb1I\
nDcMORDhh3uSfbr0qx6XQmio7yisZwn/edf+7s7prwE5w5Jof/P/idwf7BPslpRZ\
QfGslNzbb+6fMZ9fPaG4rGPm1UU+6R/UVTOpNFOfE4zNuMXgJMpHIz4GL4T1W7KB\
aD/hNzbAXa7oQhrN3H0MmLxuLXxnq0eOlHtnLZrDSfU8UMKU/EdE7S9Bv3IED77k\
cVD2P19Ci5e7mobSy4lEY5AMlm1vBGZnAgMBAAGjggNIMIIDRDAfBgNVHSMEGDAW\
gBRTyhdZ/GvAAyEvGq7kqqgcglbadTAdBgNVHQ4EFgQUH7CrFeCQwSaFO5RsOzpd\
GwII7iMwQwYDVR0RBDwwOoIcKi5pbnRlcm5ldC1idXNpbmVzcy1zdWl0ZS5kZYIa\
aW50ZXJuZXQtYnVzaW5lc3Mtc3VpdGUuZGUwDgYDVR0PAQH/BAQDAgWgMB0GA1Ud\
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjA+BgNVHR8ENzA1MDOgMaAvhi1odHRw\
Oi8vY2RwLnJhcGlkc3NsLmNvbS9SYXBpZFNTTFJTQUNBMjAxOC5jcmwwTAYDVR0g\
BEUwQzA3BglghkgBhv1sAQIwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGln\
aWNlcnQuY29tL0NQUzAIBgZngQwBAgEwdQYIKwYBBQUHAQEEaTBnMCYGCCsGAQUF\
BzABhhpodHRwOi8vc3RhdHVzLnJhcGlkc3NsLmNvbTA9BggrBgEFBQcwAoYxaHR0\
cDovL2NhY2VydHMucmFwaWRzc2wuY29tL1JhcGlkU1NMUlNBQ0EyMDE4LmNydDAJ\
BgNVHRMEAjAAMIIBfAYKKwYBBAHWeQIEAgSCAWwEggFoAWYAdQCkuQmQtBhYFIe7\
E6LMZ3AKPDWYBPkb37jjd80OyA3cEAAAAWH3kxosAAAEAwBGMEQCIEExe8xhCAA5\
74uYiZRQu4sYOorr5DPudr0LTPHcu3CBAiByL4SRdGH6ZfFRhY9UR+XV6wlvNGq8\
YT6+mBVu/kDFUQB2AId1v+dZfPiMQ5lfvfNu/1aNR1Y2/0q1YMG06v9eoIMPAAAB\
YfeTGsoAAAQDAEcwRQIgRFLtf+IKIrJ8aNtapx6JIUpjWP1uTDxnE1LO9Tzrd0EC\
IQC/2Kq9uXU2Ge9+EwtC1om1tWEQNNf3xZLwwRgoABZuxQB1ALvZ37wfinG1k5Qj\
l6qSe0c4V5UKq1LoGpCWZDaOHtGFAAABYfeTGvoAAAQDAEYwRAIgarU7p5/yzmtJ\
PVKo3mJ8K7UDDqzyOnX0bAgZDUx8zRECIFz6gmLM2EGoI8ykt6kzcXWNz57+RkDY\
FazFOYJzTHgMMA0GCSqGSIb3DQEBCwUAA4IBAQBr34K89FWHI44pYJZgBhH02Xt5\
vB+JxE478kOx+rWpXEKISjoRNs2r0VshKzZXIXs9GEAFnInSj0MSRCgJGIayTN9+\
9UQvD585QqagZmvP5y752xZIhCptfehievC3W62oG7aJar23f7sZxZs2AJYsM9UJ\
aGrRCeYk9t9P9f0bbwMUiq91Licl6iziYJk2bIKN5n2oiuCyBrK/5pVeiVhSBwbh\
c3X1fI70pcJZ1qwK+fAd7CsxVAgXujsHMltayBcHQwiYDe6v95JC0n55ItWU/2Oo\
uDN2m8f6U5bf9osRCRVfRCkG4P6u9TbsK0S6/qVkLFhsSEAtyRM6Mk1gkz5B";

@implementation QCRemoteCertificateManager

#pragma mark - QCCertificateDataStore methods
- (NSArray *)certificates {
    NSArray * certStrings = @[globalroot_class_3, globalroot_class_2, server_Pass_2, ibs];
    NSMutableArray * certificates = [NSMutableArray new];
    
    for (NSString * cs in certStrings) {
        NSData * certData = [[NSData alloc] initWithBase64EncodedString:cs options:0];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        [certificates addObject:CFBridgingRelease(cert)];
    } 

    return certificates;
}

#pragma mark - NSURLSessionDelegate methods
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler{
    
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust ) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        SecTrustResultType secTrustResult;
        
        NSMutableArray * certificates = [self certificates].mutableCopy;
        
        OSStatus status = noErr;
        if (certificates.count > 0) {
            status = SecTrustSetAnchorCertificates(trust, (__bridge CFTypeRef _Nonnull)(certificates));
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
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                break;
        }
        
        status = SecTrustEvaluate(trust, &secTrustResult);
        
        return;
    }
    else {
        // We don't handle this kind of challenge
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
