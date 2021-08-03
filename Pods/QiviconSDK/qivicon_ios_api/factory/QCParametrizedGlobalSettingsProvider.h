//
//  QCParametrizedGlobalSettingsProvider.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 28.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QCGlobalSettingsProvider.h"

/**
 * This class implements a {@link QCGlobalSettingsProvider}, that gets the
 * initialization values during construction.
 */
@interface QCParametrizedGlobalSettingsProvider : NSObject <QCGlobalSettingsProvider>
/**
 * Initialize {@link QCGlobalSettings}.
 *
 * @param oaEP
 *            OAuth2 Endpoint
 * @param oaTokenEP
 *            OAuth2 Token Endpoint
 * @param remoteEP
 *            Remote Endpoint
 * @param backendEP
 *            Backend Endpoint
 * @param qiviconBackendEP
 *            Endpoint of QIVICON backend
* @param websocketEP
 *            Endpoint for web socket communication
 * @param appUrl
 *            Redirection URL
 * @param scope
 *            Scope
 * @param clientId
 *            Client ID
 * @param clientSecret
 *            Client Secret
 * @param useProxy
 *            true, if proxy must be used
 * @param proxyHost
 *            proxy host
 * @param proxyPort
 *            proxy port
 * @param localAppUrl
 *            Redirection URL
 * @param localClientId
 *            Client ID
 * @param localClientSecret
 *            Client Secret
 */
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
  localClientSecret:(NSString *) localClientSecret;

@end
