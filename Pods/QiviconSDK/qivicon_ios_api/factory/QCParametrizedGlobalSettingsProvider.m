//
//  QCParametrizedGlobalSettingsProvider.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 28.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import "QCParametrizedGlobalSettingsProvider.h"

@interface QCParametrizedGlobalSettingsProvider ()
@property (readwrite, nonatomic) QCGlobalSettings *remoteConnectionSettings;
@property (readwrite, nonatomic) QCGlobalSettings *localConnectionSettings;
@end

@implementation QCParametrizedGlobalSettingsProvider
@synthesize remoteConnectionSettings, localConnectionSettings;

- (id) initWithOaEP:(NSString *)oaEP
          oaTokenEP:(NSString*)oaTokenEP
           remoteEP:(NSString*)remoteEP
          backendEP:(NSString*)backendEP
  backendGatewayIdEP:(NSString*)backendGatewayIdEP
   qiviconBackendEP:(NSString *)qiviconBackendEP
        websocketEP:(NSString*)websocketEP
             appUrl:(NSString*)appUrl
              scope:(NSString*)scope
           clientId:(NSString*)clientId
       clientSecret:(NSString*)clientSecret
           useProxy:(BOOL)useProxy
          proxyHost:(NSString*)proxyHost
          proxyPort:(NSInteger)proxyPort
        localAppUrl:(NSString *) localAppUrl
      localClientId:(NSString *) localClientId
  localClientSecret:(NSString *) localClientSecret
{
    if (( self = [super init])) {
        self.remoteConnectionSettings = [[QCGlobalSettings alloc] initWithOaEP:oaEP
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

        self.localConnectionSettings = [[QCGlobalSettings alloc] initWithOaEP:nil
                                                                    oaTokenEP:nil
                                                                     remoteEP:nil
                                                                    backendEP:nil
                                                            backendGatewayIdEP:nil
                                                             qiviconBackendEP:nil
                                                                 websocketEP:nil
                                                                       appUrl:localAppUrl
                                                                        scope:nil
                                                                     clientId:localClientId
                                                                 clientSecret:localClientSecret
                                                                     useProxy:NO
                                                                    proxyHost:nil
                                                                    proxyPort:0];

    }
    return self;
}

@end
