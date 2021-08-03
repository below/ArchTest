//
//  QCAbstractInputStreamGlobalSettingsProvider.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import "QCAbstractInputStreamGlobalSettingsProvider.h"
#import "JUProperties.h"
#import "QCLogger.h"

@implementation QCAbstractInputStreamGlobalSettingsProvider

- (id) init {
    NSAssert([self class] != [QCAbstractInputStreamGlobalSettingsProvider class],  @"This is an abstract class, do not instantiate");
    return [super init];
}

- (QCGlobalSettings *) readGlobalSettingsWithUrl:(NSURL *)url {
    if (url == nil)
        [[QCLogger defaultLogger] debug:@"Input stream must not be null."];
    else {
        JUProperties *properties = [JUProperties new];
        NSError *error;
        [properties loadURL:url withError:&error];
        NSString *oaEP = [properties property:@"endpoint.oauth"];
        NSString *oaTokenEP = [properties property:@"endpoint.oauth.token"];
        NSString *remoteEP = [properties property:@"endpoint.remote"];
        NSString *backendEP = [properties property:@"endpoint.backend"];
        NSString *backendGatewayIdEP = [properties property:@"endpoint.backendGatewayId"];
        NSString *qiviconBackendEP = [properties property:@"endpoint.qiviconbackend"];
        NSString *websocketEP = [properties property:@"endpoint.websockets"];
        NSString *appUrl = [properties property:@"app.url"];
        NSString *scope = [properties property:@"scope"];
        NSString *clientId = [properties property:@"client.id"];
        NSString *clientSecret = [properties property:@"client.secret"];
        BOOL useProxy = [[properties property:@"useProxy"] boolValue];
        NSString *proxyHost = [properties property:@"proxy.host"];
        int proxyPort = [[properties property:@"proxy.port"] intValue];
        return [[QCGlobalSettings alloc] initWithOaEP:oaEP
                                            oaTokenEP:oaTokenEP
                                             remoteEP:remoteEP
                                            backendEP:backendEP                
                                   backendGatewayIdEP:backendGatewayIdEP
                                     qiviconBackendEP:qiviconBackendEP
                                          websocketEP:websocketEP
                                               appUrl:appUrl
                                                scope:scope
                                             clientId:clientId
                                         clientSecret:clientSecret
                                             useProxy:useProxy
                                            proxyHost:proxyHost
                                            proxyPort:proxyPort];
    }
    return nil;
}

- (QCGlobalSettings *) remoteConnectionSettings  {
    NSAssert(NO, @"Do not call");
    return nil;
}

- (QCGlobalSettings *) localConnectionSettings {
    NSAssert(NO, @"Do not call");
    return nil;
}


@end
