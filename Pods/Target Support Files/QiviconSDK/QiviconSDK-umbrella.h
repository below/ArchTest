#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JSONRPC.h"
#import "JUProperties.h"
#import "QCConnectionFactory.h"
#import "QCLogger.h"
#import "QCUtils.h"
#import "qivicon.h"
#import "QCDiscoveryDelegate.h"
#import "QCDiscoveryService.h"
#import "QCGatewayDiscovery.h"
#import "QCAuthHelper.h"
#import "QCConnHelper.h"
#import "QCConnHelperMethodCall.h"
#import "QCLongPolling.h"
#import "QCLongPollingDispatchedCall.h"
#import "QCServiceGatewayEvent.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCServiceGatewayEventListener.h"
#import "QCWebSocket.h"
#import "QCWebSocketConnectionFactory.h"
#import "QCWebSocketListener.h"
#import "QCAsyncAuthDelegateProtocol.h"
#import "QCAuthorizedConnection_private.h"
#import "QCBackendConnection_private.h"
#import "QCCertificateManager.h"
#import "QCConnection.h"
#import "QCHTTPClientConnectionContext.h"
#import "QCHTTPClientConnectionContextFactory.h"
#import "QCHTTPConnectionContext.h"
#import "QCHTTPConnectionContextFactory.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCRemoteCertificateManager.h"
#import "QCRemoteServiceGatewayConnection.h"
#import "QCServiceGatewayConnection_private.h"
#import "QCURLConnection.h"
#import "QCDiscoveryParserDelegate.h"
#import "QCGCDAsyncUdpSocket.h"
#import "QCUpnpDiscoveryService.h"
#import "QCAuthorizedConnection.h"
#import "QCBackendConnection.h"
#import "QCErrors.h"
#import "QCGlobalSettings.h"
#import "QCGlobalSettingsProvider.h"
#import "QCJsonRpcIDProvider.h"
#import "QCPersistentTokenStorage.h"
#import "QCServiceGatewayConnection.h"
#import "QCOAuth2Token.h"
#import "QCRemoteMethod.h"
#import "QCResultElement.h"
#import "QCAbstractInputStreamGlobalSettingsProvider.h"
#import "QCFileGlobalSettingsProvider.h"
#import "QCParametrizedGlobalSettingsProvider.h"
#import "QCSystemPropertiesGlobalSettingsProvider.h"

FOUNDATION_EXPORT double QiviconSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char QiviconSDKVersionString[];

