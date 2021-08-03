/*
 * (C) Copyright 2011-2013 by Deutsche Telekom AG.
 *
 * This software is property of Deutsche Telekom AG and has
 * been developed for QIVICON platform.
 *
 * See also http://www.qivicon.com
 *
 * DO NOT DISTRIBUTE OR COPY THIS SOFTWARE OR PARTS OF THE SOFTWARE
 * TO UNAUTHORIZED PERSONS OUTSIDE THE DEUTSCHE TELEKOM ORGANIZATION.
 *
 * VIOLATIONS WILL BE PURSUED!
 */

#import "QCGlobalSettings.h"
#import "JUProperties.h"
#import "QCUtils.h"

@interface QCGlobalSettings ()
@property NSString *oaEP;
@property NSString *oaTokenEP;
@property NSString *remoteEP;
@property NSString *backendEP;
@property NSString *backendGatewayIdEP;
@property NSString *qiviconBackendEP;
@property NSString *websocketEP;
@property NSString *appUrl;
@property NSString *scope;
@property NSString *clientId;
@property NSString *clientSecret;
@property BOOL useProxy;
@property NSString *proxyHost;
@property NSInteger proxyPort;
@end

/** url parameter */
NSString * const  REFRESH_TOKEN = @"refresh_token";
/** url parameter */
NSString * const  AUTHORIZATION_CODE = @"authorization_code";
/** url parameter */
NSString * const  PASSWORD = @"password";
/** url parameter */
NSString * const  USERNAME = @"username";
/** url parameter */
NSString * const  GRANT_TYPE = @"grant_type";
/** url parameter */
NSString * const  CODE = @"code";
/** url parameter */
NSString * const  REDIRECT_URI = @"redirect_uri";
/** url parameter */
NSString * const  RESPONSE_TYPE = @"response_type";
/** url parameter */
NSString * const  SCOPE = @"scope";
/** url parameter */
NSString * const  STATE = @"state";
/** url parameter */
NSString * const  CLIENT_ID = @"client_id";


@implementation QCGlobalSettings

/**
 * Initialize connection utilities. End points will be set according to the
 * content of the property file defined in
 * {@link #QIVICON_CONNECTOR_PROPERTIES_FILE}.
 */

- (id) initWithPropertiesURL:(NSURL*) propURL {
        JUProperties *properties = nil;
        if (propURL != nil) {
            properties = [JUProperties new];
            [properties loadURL:propURL withError:nil];
        }
    return [self initWithOaEP:[properties property:@"endpoint.oauth"]
                    oaTokenEP:[properties property:@"endpoint.oauth.token"]
                     remoteEP:[properties property:@"endpoint.remote"]
                    backendEP:[properties property:@"endpoint.backend"]
           backendGatewayIdEP:[properties property:@"endpoint.backendGatewayId"]
             qiviconBackendEP:[properties property:@"endpoint.qiviconbackend"]
                  websocketEP:[properties property:@"endpoint.websockets"]
                       appUrl:[properties property:@"app.url"]
                        scope:[properties property:@"scope"]
                     clientId:[properties property:@"client.id"]
                 clientSecret:[properties property:@"client.secret"]
                     useProxy:[@"true" isEqualToString:[properties property:@"useProxy"]]
                    proxyHost:[properties property:@"proxy.host"]
                    proxyPort:[[properties property:@"proxy.port"] intValue]]; 
}

- (id)initWithOaEP:(NSString *)oaEP
         oaTokenEP:(NSString *)oaTokenEP
          remoteEP:(NSString *)remoteEP
         backendEP:(NSString *)backendEP
backendGatewayIdEP:(NSString *)backendGatewayIdEP
  qiviconBackendEP:(NSString *)qiviconBackendEP
       websocketEP:(NSString *)websocketEP
            appUrl:(NSString *)appUrl
             scope:(NSString *)scope
          clientId:(NSString *)clientId
      clientSecret:(NSString *)clientSecret
          useProxy:(BOOL)useProxy
         proxyHost:(NSString *)proxyHost
         proxyPort:(NSInteger)proxyPort {
    
    if ((self = [super init])) {
        self.oaEP = oaEP;
        self.oaTokenEP = oaTokenEP;
        self.remoteEP = remoteEP;
        self.backendEP = backendEP;
        self.backendGatewayIdEP = backendGatewayIdEP;
        self.qiviconBackendEP = qiviconBackendEP;
        self.websocketEP = websocketEP;
        self.appUrl = appUrl;
        self.scope = scope;
        self.clientId = clientId;
        self.clientSecret = clientSecret;
        self.useProxy = useProxy;
        self.proxyHost = proxyHost;
        self.proxyPort = proxyPort;
    }
    return self;
}

- (NSURL *) loginURLForEndpoint:(NSURL *)endpoint {
    return [self loginURLForEndpoint:endpoint state:nil];
}

- (NSURL *) loginURLForEndpoint:(NSURL *)endpoint state:(NSString*) state {
    NSString *parameterString = [NSString stringWithFormat:@"?client_id=%@&response_type=code",
                                 self.clientId];
    
    if (self.scope.length != 0)
        parameterString = [parameterString stringByAppendingFormat:@"&scope=%@", self.scope];

    if (state.length != 0)
        parameterString = [parameterString stringByAppendingFormat:@"&state=%@", state];
    
    parameterString = [parameterString stringByAppendingFormat:@"&redirect_uri=%@", [self.appUrl urlEncoded]];
    NSURL *url = [NSURL URLWithString:parameterString
                        relativeToURL:endpoint];
    return url;
}

- (NSDictionary *) oAuthRequestParametersWithUsername:(NSString *)username
                                             password:(NSString *)password {
    
    NSMutableDictionary * map = [NSMutableDictionary new];
    if (self.scope)
        map[SCOPE] = self.scope;
    map[GRANT_TYPE] = PASSWORD;
    map[USERNAME] = username;
    map[PASSWORD] = password;
    
    if (self.clientSecret.length == 0) {
        map[CLIENT_ID] = self.clientId;
    }
    return map;
}

- (NSDictionary *) oAuthRequestParametersWithAuthCode:(NSString *) code {

    NSMutableDictionary * map = [NSMutableDictionary new];
    if (self.scope)
        map[SCOPE] = self.scope;
    map[GRANT_TYPE] = AUTHORIZATION_CODE;
    map[CODE] = code;
    map[REDIRECT_URI] = self.appUrl;
    if (self.clientSecret.length == 0) {
        map[CLIENT_ID] = self.clientId;
    }
    return map;
}

- (NSDictionary *) oAuthRefreshRequestParametersWithRefreshToken:(NSString *)refreshToken {
    
    NSMutableDictionary * map = [NSMutableDictionary new];
    if (self.scope)
        map[SCOPE] = self.scope;
    map[GRANT_TYPE] = REFRESH_TOKEN;
    map[REFRESH_TOKEN] = refreshToken;
    map[REDIRECT_URI] = self.appUrl;
    if (self.clientSecret.length == 0) {
        map[CLIENT_ID] = self.clientId;
    }
    return map;
}

- (NSString *) clientAuthorization; {
    if (self.clientSecret.length == 0) {
        return nil;
    }
    NSString *str = [NSString stringWithFormat:@"%@:%@", self.clientId, self.clientSecret];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSString *result = [QCUtils base64EncodedStringFromData:data];
    return result;
}

- (NSURL *)qiviconBackendURL {
    return [NSURL URLWithString:self.qiviconBackendEP];
}

- (NSURL *)backendURL {
    return [NSURL URLWithString:self.backendEP];
}

- (NSURL *)backendGatewayIdURL {
    return [NSURL URLWithString:self.backendGatewayIdEP];
}

- (NSURL *) remoteAccessURL {
    return [NSURL URLWithString:self.remoteEP];
}

- (NSURL *) webSocketURL {
    return [NSURL URLWithString:self.websocketEP];
}

- (NSURL *) oAuthEndpoint {
    return [NSURL URLWithString:self.oaEP];
}

- (NSURL *) oAuthTokenEndpoint {
    return [NSURL URLWithString:self.oaTokenEP];
}

@end
