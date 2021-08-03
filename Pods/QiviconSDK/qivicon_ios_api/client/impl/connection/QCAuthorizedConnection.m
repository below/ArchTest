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

//
//  QCAuthorizedConnection.m
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 10.01.13.
//

#import "QCConnection.h"
#import "QCAuthorizedConnection.h"
#import "QCPersistentTokenStorage.h"
#import "QCErrors.h"
#import "QCHTTPConnectionContext.h"
#import "QCUtils.h"
#import "QCResultElement.h"
#import "QCLogger.h"
#import "QCAsyncAuthDelegateProtocol.h"
#import "QCAuthHelper.h"
#import "QCConnHelper.h"

@interface QCAuthorizedConnection()

@property(nonatomic, readwrite)id<QCPersistentTokenStorage> tokenStorage;
@property (nonatomic, readwrite, strong)QCOAuth2Token * authToken;
@property (nonatomic, readwrite, strong)NSRecursiveLock * authLock;
@property (nonatomic, readwrite, strong)NSRecursiveLock * accessTokenLock;
@property (nonatomic, readwrite, weak)id<QCAsyncAuthDelegate> delegate;

@property (nonatomic, readwrite, strong)NSString *previousRefreshToken;

@property (readonly) NSURL * oAuthTokenEndpoint;
@property (nonatomic) QCConnHelper * connHelper;
@property (nonatomic) QCAuthHelper * authHelper;
@end

@implementation QCAuthorizedConnection


NSString * const NOT_AUTHORIZED_MESSAGE = @"Not authorized";
NSString * const NO_TOKEN_STORAGE = @"No Token Storage available";
NSString * const NO_REFRESH_TOKEN_IN_TOKEN_STORAGE = @"Missing Refresh Token in Token Storage";

/**
* Pseudo gateway id to identify refresh tokens of the GCP used for
* communication with the backend or for remote connections.
*/
static NSString * const BACKEND_ID = @"BACKEND";

NSString * const CANNOT_GET_ACCESS_TOKEN = @"Cannot get access token.";


- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
               tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
            sessionDelegate:(id<NSURLSessionDelegate>)delegate authToken:(QCOAuth2Token *)token {

   self = [self initWithGlobalSettings:globalSettings tokenStorage:tokenStorage sessionDelegate:delegate];
   
   if (self) {
       self.authToken = token;
   }
   
   return self;
}

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
               tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
            sessionDelegate:(id<NSURLSessionDelegate>)delegate {
   
   self = [super initWithGlobalSettings:globalSettings sessionDelegate:delegate];
   
   if (self) {
       self.tokenStorage = tokenStorage;
       self.authLock = [NSRecursiveLock new];
       self.accessTokenLock = [NSRecursiveLock new];
       self.connHelper = [[QCConnHelper alloc] initWithSession:self.session];
       self.authHelper = [[QCAuthHelper alloc] initWithSession:self.session];
   }
   return self;
}

- (void) authorizeWithError:(NSError * __autoreleasing *)error {
   if (self.tokenStorage == nil){
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: NO_TOKEN_STORAGE}];
       }
       return;
   }

   self.authToken = [self.tokenStorage oAuthTokenForID:self.gatewayId];
   NSString *refreshToken = self.authToken.refresh_token ? self.authToken.refresh_token : [self loadRefreshToken];
   
   if ([refreshToken length] == 0){
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: NO_REFRESH_TOKEN_IN_TOKEN_STORAGE}];
       }
       return;
   }
   
   if (!self.isAuthorized || [self isAccessTokenRefreshNeeded]) {
       [self refreshWithRefreshToken:refreshToken error:error];
   }
}

- (void) authorizeWithAuthCode:(NSString *) authCode error:(NSError**)error {
   if (authCode.length == 0) {
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: @"Authentication code must not be null or empty!"}];
       }
       return;
   }
   
   [self logout];
   self.authToken = [self retrieveTokenForEndpoint:self.oAuthTokenEndpoint
                                        postParams:[self.globalSettings oAuthRequestParametersWithAuthCode:authCode]
                                             error:error];
   
   if (self.authToken && [self checkIfAuthorizedWithError:error]) {
       if (self.connectionType != ConnectionType_Service_Gateway_Local) {
           [self saveRemoteOAuth2Token:self.authToken];
       }
       [self.tokenStorage storeOAuthToken:self.authToken forID:self.gatewayId];
   }
   return;
}

- (void) authorizeWithToken:(QCOAuth2Token *) authToken error:(NSError**)error {
   if (authToken.access_token.length == 0) {
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: @"Authentication code must not be null or empty!"}];
       }
       return;
   }
   
   [self logout];
   self.authToken = authToken;
   
   if ([self checkIfAuthorizedWithError:error]) {
       if (self.connectionType != ConnectionType_Service_Gateway_Local) {
           [self saveRemoteOAuth2Token:authToken];
       }
       [self.tokenStorage storeOAuthToken:self.authToken forID:self.gatewayId];
   }
   return;
}

/**
* Login using OAuth2 authorization code. This code is typically retrieved
* from the OAuth web login with username and password.
*
* @deprecated This method has only package visibility and is intended to be
*             used only for testing purposes. It is highly discouraged to
*             submit username and password this way.
* @param authCode
*            authorization code
* @return OAuth2 refresh token
* @throws AuthException
*             on each error on OAuth provider
*/
- (NSString *) loginWithUsername:(NSString *)username
                     password:(NSString *) password
                     error:(NSError **)error __attribute__((deprecated)) {
   [self logout];
   self.authToken = [self retrieveTokenForEndpoint:self.oAuthTokenEndpoint
                                        postParams:[self.globalSettings oAuthRequestParametersWithUsername:username
                                                                                                  password:password]
                                             error:error];
   
   if (self.authToken && [self checkIfAuthorizedWithError:error]) {
       if (self.connectionType != ConnectionType_Service_Gateway_Local) {
           [self saveRemoteOAuth2Token:self.authToken];
       }
       [self.tokenStorage storeOAuthToken:self.authToken forID:self.gatewayId];
       return self.authToken.refresh_token;
   }
   return nil;
}

- (NSString *) refreshWithRefreshToken:(NSString *)refreshToken error:(NSError **)error {
   if (refreshToken.length == 0) {
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: @"Refresh token must not be null nor emtpy!"}];
           return nil;
       }
   }

   [self.authLock lock];
   self.authToken = [self refreshTokenForEndpoint:self.oAuthTokenEndpoint
                                       postParams:[self.globalSettings oAuthRefreshRequestParametersWithRefreshToken:refreshToken]
                                            error:error];
   
   // have to use the old refresh if there is no new one provided
   if (self.authToken && self.authToken.refresh_token.length == 0) {
       self.authToken.refresh_token = refreshToken;
   }
   
   if (self.authToken && [self checkIfAuthorizedWithError:error]) {
       if (self.connectionType != ConnectionType_Service_Gateway_Local) {
           [self saveRemoteOAuth2Token:self.authToken];
       }
       [self.tokenStorage storeOAuthToken:self.authToken forID:self.gatewayId];
       [self.authLock unlock];
       return self.authToken.refresh_token;
   }
   [self.authLock unlock];
   return nil;
}

- (void)refreshWithDelegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError **)error{
   _delegate = delegate;
   if (self.tokenStorage == nil && self.authToken == nil) {
       if (error)
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: @"No refresh token available!"}];
       return;
   }
   
   if (self.tokenStorage) {
       self.authToken = [self.tokenStorage oAuthTokenForID:self.gatewayId];
   }

   NSString *refreshToken = self.authToken.refresh_token ? self.authToken.refresh_token : [self loadRefreshToken];
   if (refreshToken.length == 0) {
       if (error){
           *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                    userInfo:@{NSLocalizedDescriptionKey: @"Refresh token must not be null nor emtpy!"}];
           return;
       }
   }
   
   if (!self.isAuthorized || [self isAccessTokenRefreshNeeded]) {
       _previousRefreshToken = refreshToken;
       [self refreshTokenForEndpoint:self.oAuthTokenEndpoint
                          postParams:[self.globalSettings oAuthRefreshRequestParametersWithRefreshToken:refreshToken]
                            delegate:self
                               error:error];
   } else {
       [_delegate authOnConnection:self wasSuccessfulWithAuthToken:self.authToken];
   }
}


- (BOOL) isAuthorized {
   if (self.authToken) {
       return [self.authToken isAuthorized];
   }
   return NO;
}

- (NSString *) loadRefreshToken {
   if (self.tokenStorage != nil) {
       return [self.tokenStorage loadTokenForGatewayId:self.gatewayId];
   }
   return nil;
}

- (void) logout {
   [self.accessTokenLock lock];
   self.authToken = nil;
   [self.tokenStorage deleteTokenForGatewayId:self.gatewayId];
   [self.tokenStorage deleteOAuthTokenForID:self.gatewayId];
   if (self.connectionType != ConnectionType_Service_Gateway_Local) {
       [self.tokenStorage deleteRemoteAccessToken];
   }
   [self.accessTokenLock unlock];
}

- (NSURL *) loginURL {
   return [self.globalSettings loginURLForEndpoint:self.oAuthEndpoint];
}

- (NSURL *) loginURLForState:(NSString*) state {
   return [self.globalSettings loginURLForEndpoint:self.oAuthEndpoint state:state];
}

- (NSArray *) callWithMethod:(QCRemoteMethod *)method error:(NSError *__autoreleasing *)error {
   return [self callAsBatchWithMethods:@[method] error:error];
}

- (NSArray *) callAsBatchWithMethods:(NSArray *)methods error:(NSError *__autoreleasing *)error {
   
   return [self callWithReturnClass:nil methods:methods error:error];
}


- (BOOL) callAsyncWithMethod:(QCRemoteMethod *)method delegate:(id)delegate customIdentifier:(NSString*)customIdentifier error:(NSError *__autoreleasing *)error{
   return [self callAsyncAsBatchWithMethods:@[method] delegate:delegate customIdentifier:customIdentifier error:error];
}

- (BOOL) callAsyncAsBatchWithMethods:(NSArray *)methods delegate:(id <QCConnectionDelegate>)delegate customIdentifier:(NSString*)customIdentifier error:(NSError *__autoreleasing *)error
{
   return [self callAsyncWithReturnClass:nil methods:methods delegate:delegate  customIdentifier:customIdentifier error:error];
}

- (NSArray *) callWithReturnClass:(Class)classOfT methods:(NSArray *)methods error:(NSError * __autoreleasing *)error {
   NSAssert(false, @"Abstract implementation");
   return nil;
}

- (BOOL) callAsyncWithReturnClass:(Class)classOfT methods:(NSArray *)methods delegate:(id <QCConnectionDelegate>)delegate customIdentifier:(NSString*)customIdentifier error:(NSError * __autoreleasing *)error {
   NSAssert(false, @"Abstract implementation");
   return nil;
}

/* Former ConnectionContext Methods */
- (id) callWithClass:(Class)classOfT
                url:(NSURL *)url
          authToken:(NSString *)authToken
               gwId:(NSString *)gwId
            methods:(NSArray *)methods
              error:(NSError * __autoreleasing *)error
{
   
   return [self.connHelper callRPCWithClass:classOfT url:url authToken:authToken gwID:gwId methods:methods customIdentifier:nil error:error];
   
}
   
- (BOOL) callAsyncWithClass:(Class)classOfT
                       url:(NSURL *)url
                 authToken:(NSString *)authToken
                      gwId:(NSString *)gwId
                   methods:(NSArray *)methods
          customIdentifier:(NSString*)customIdentifier
           contextDelegate:(id<QCHTTPConnectionContextDelegate>)contextDelegate
        remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
                     error:(NSError * __autoreleasing *)error
   {
       NSError *callError;
       [self.connHelper callRPCAsyncWithClass:classOfT
                                          url:url
                                    authToken:authToken
                                         gwID:gwId
                                      methods:methods
                              contextDelegate:contextDelegate
                           remoteCallDelegate:remoteCallDelegate
                             customIdentifier:customIdentifier
                                        error:&callError];
       
       if (callError) {
           if (error) {
               *error = callError;
           }
           return NO;
       }
       
       return YES;
   }
   
- (QCOAuth2Token *) tokenFromOAuthProvider:(NSURL *) url withPostParams:(NSDictionary *)postParams error:(NSError * *)error {
   NSError *localError = nil;
   NSURLRequest *req = [self.authHelper createPostRequestWithUrl:url postParams:postParams clientAuthorization:self.globalSettings.clientAuthorization error:&localError];
   if (localError != nil) {
       if (error)
       *error = localError;
       return nil;
   }
   return [self.authHelper executeAuthorizeCallWithRequest:req error:error];
}

- (void) tokenFromOAuthProvider:(NSURL *) url withPostParams:(NSDictionary *)postParams delegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError * *)error {
   NSError *localError = nil;
   NSURLRequest *req = [self.authHelper createPostRequestWithUrl:url postParams:postParams clientAuthorization:self.globalSettings.clientAuthorization error:&localError];
   if (localError != nil) {
       if (error)
       *error = localError;
       return;
   }
   [self.authHelper executeAuthorizeCallAsyncWithRequest:req delegate:delegate];
}
/* ConnectionContext End */

- (NSString *) refreshTokenWithError:(NSError **)error {
   if ([self checkIfAuthorizedWithError:error]) {
       return self.authToken.refresh_token;
   }
   return nil;
}

- (NSString *)refreshToken {
   return [self refreshTokenWithError:nil];
}

- (NSString *) accessTokenWithError:(NSError **)error {
   if ([self checkIfAuthorizedWithError:error]){
       return self.authToken.access_token;
   }
   return nil;
}

-(NSString *)accessToken {
   return [self accessTokenWithError:nil];
}

- (double) accessTokenExpireTimeWithError:(NSError **)error{
   if ([self checkIfAuthorizedWithError:error]){
       return self.authToken.expire_time;
   }
   return 0.0f;
}

- (double)accessTokenExpireTime {
   return [self accessTokenExpireTimeWithError:nil];
}

- (BOOL) checkIfAuthorizedWithError:(NSError **) error { // Below: We have changed this from Java to return a BOOL
 if (![self isAuthorized]) {
     if (error)
         *error = [NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                  userInfo:@{NSLocalizedDescriptionKey: CANNOT_GET_ACCESS_TOKEN}];
     return NO;
 }
   return YES;
}

- (BOOL)isAccessTokenRefreshNeeded {
    if (self.authToken) {
        return [self.authToken isAccessTokenRefreshNeeded];
    }
    return YES;
}

- (BOOL)refreshAccessTokenIfNeededWithError:(NSError **) error {
   NSError *localError = nil;
   BOOL valid = YES;
#ifndef TARGET_IS_EXTENSION
   [self.accessTokenLock lock];
   valid = NO;
   if ([self checkIfAuthorizedWithError:&localError] && !localError) {
       
       BOOL needNewAuth = [self isAccessTokenRefreshNeeded];

       if (needNewAuth) {
           NSError *authError = nil;
           [self authorizeWithError:&authError];
           if (!authError) {
               valid = YES;
           } else {
               if (error)
                   *error = authError;
           }
       } else {
           valid = YES;
       }
   } else {
       if (error)
           *error = localError;
   }
   
   [self.accessTokenLock unlock];
#endif
   return valid;

}

- (void)saveRemoteOAuth2Token:(QCOAuth2Token *)token {
   double expireTime = token.expire_time;
   NSString *accessToken = token.access_token;
   
   if (accessToken) {
       [self.tokenStorage storeRemoteAccessToken:accessToken expireTime:expireTime];
   }
}

- (id<QCPersistentTokenStorage>)tokenStorage {
   return _tokenStorage;
}

       
/**
* Returns the OAuth2 authorization endpoint url.
*
* @return url
*/
- (NSURL*) oAuthEndpoint {
   NSAssert(false, @"Abstract implementation");
   return nil;
}

/**
* Returns the OAuth2 token endpoint url.
*
* @return url
*/
- (NSURL *) oAuthTokenEndpoint {
   NSAssert(false, @"Abstract implementation");
   return nil;
}
       
/**
* Returns the id of the service gateway used by this connection. May be set
* to {@link #BACKEND_ID} if no service gateway is associated with it, e.g.
* for {@link BackendConnection}s. The value is used internally as a key for
* the stored OAuth2 refresh token.
*
* @see PersistentTokenStorage
*
* @return a gateway id
*/
- (NSString *) gatewayId {
   return BACKEND_ID;
}

- (QCGlobalSettings *) connectionSettings {
   return self.globalSettings;
}

- (QCOAuth2Token *) retrieveTokenForEndpoint:(NSURL *)url postParams:(NSDictionary *)postParams error:(NSError **)error {
   return [self tokenFromOAuthProvider:url
                         withPostParams:postParams error:error];
}

- (QCOAuth2Token *) refreshTokenForEndpoint:(NSURL *)url postParams:(NSDictionary *)postParams error:(NSError **)error {
   return [self tokenFromOAuthProvider:url
                                                       withPostParams:postParams
                                                                error:error];
}

- (void) refreshTokenForEndpoint:(NSURL *)url postParams:(NSDictionary *)postParams delegate:(id<QCAsyncAuthDelegate>)delegate error:(NSError **)error {
   [self tokenFromOAuthProvider:url
                                   withPostParams:postParams
                                         delegate:delegate error:error];
}

- (ConnectionType) connectionType{
   NSAssert(false, @"Abstract implementation");
   return 0;
}


#
# pragma mark delegate methods
#

- (void)callWithMethodId:(NSNumber *)methodId
     remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
       customIdentifier:(NSString*)customIdentifier
       didFailWithError:(NSError *)error{
   
   if ([remoteCallDelegate respondsToSelector:@selector(connection:withCustomIdentifier:didFailWithError:)]) {
       [remoteCallDelegate connection:self withCustomIdentifier:customIdentifier didFailWithError:error];
   } else if ([remoteCallDelegate respondsToSelector:@selector(connection:didFailWithError:)]) {
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
       [remoteCallDelegate connection:self didFailWithError:error];
   }
   
}

- (void)callWithMethodId:(NSNumber *)methodId
     remoteCallDelegate:(id <QCConnectionDelegate>)remoteCallDelegate
       customIdentifier:(NSString*)customIdentifier didFinishLoadingWithJSONResult:(id)result{

   if ([remoteCallDelegate respondsToSelector:@selector(connection:withCustomIdentifier:didFinishWithResult:)]) {
       [remoteCallDelegate connection:self withCustomIdentifier:customIdentifier didFinishWithResult:result];
   } else if ([remoteCallDelegate respondsToSelector:@selector(connection:didFinishWithResult:)]) {
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
       [remoteCallDelegate connection:self didFinishWithResult:result];
   }
}

- (void)authOnConnection:(QCAuthorizedConnection*)connection wasSuccessfulWithAuthToken:(QCOAuth2Token*)authToken{
   // have to use the old refresh if there is no new one provided
   if (authToken && authToken.refresh_token.length == 0) {
       authToken.refresh_token = _previousRefreshToken;
   }
   
   self.authToken = authToken;
   if (self.authToken.refresh_token) {
       if (self.connectionType != ConnectionType_Service_Gateway_Local) {
           [self saveRemoteOAuth2Token:authToken];
       }
       [self.tokenStorage storeOAuthToken:self.authToken forID:self.gatewayId];
       [_delegate authOnConnection:self wasSuccessfulWithAuthToken:self.authToken];
   } else {
       [_delegate authOnConnection:self didFailWithError:[NSError errorWithDomain:QCErrorDomainAuth code:NOT_AUTHORIZED
                                                                         userInfo:@{NSLocalizedDescriptionKey: @"authToken Result must not be null nor emtpy!"}]];
   }
}

- (void)authOnConnection:(QCAuthorizedConnection*)connection didFailWithError:(NSError *)error{
   [_delegate authOnConnection:self didFailWithError:error];
}

@end

