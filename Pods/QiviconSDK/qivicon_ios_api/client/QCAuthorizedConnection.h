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

#import <Foundation/Foundation.h>
#import "QCConnection.h"
#import "QCRemoteMethod.h"
#import "QCOAuth2Token.h"

extern NSString * const NOT_AUTHORIZED_MESSAGE;
extern NSString * const CANNOT_GET_ACCESS_TOKEN;

@protocol QCPersistentTokenStorage;
@protocol QCHTTPConnectionContext;
@protocol QCHTTPConnectionContextDelegate;
@class QCAuthorizedConnection;

typedef enum ConnectionType {
    ConnectionType_Service_Gateway_Remote,
    ConnectionType_Service_Gateway_Local,
    ConnectionType_Backend
} ConnectionType;

typedef enum GatewayType {
    GatewayType_Unknown,
    GatewayType_QHB1,
    GatewayType_QHB2,
    GatewayType_Embedded_QHB,
    GatewayType_Simulator,
    
} GatewayType;

@protocol QCConnectionDelegate <NSObject>
@optional
    /**
     * This method is called if an error occured on a method call
     *
     * This method won't be called if connect:withCustomIdentifier:didFailWithError: is implemented
     *
     * @param connection
     *            The used connection for the method call
     * @param error
     *            error object
     *
     */
- (void) connection:(id)connection didFailWithError:(NSError *)error __attribute__((deprecated));
/**
 * This method is called if the method call was successful and returns the result
 *
 * This method won't be called if connect:withCustomIdentifier:didFinishWithResult: is implemented
 *
 * @param connection
 *            The used connection for the method call
 * @param result
 *            The result of the method call
 *
 */
- (void) connection:(id)connection didFinishWithResult:(NSArray *)result __attribute__((deprecated));
/**
 * This method is called if an error occured on a method call
 *
 * If this method is implemented the connect:didFailWithError: won't be called
 *
 * @param connection
 *            The used connection for the method call
 * @param customIdentifier
 *            Contains the custom identifier
 * @param error
 *            error object
 *
 */
- (void) connection:(id)connection withCustomIdentifier:(NSString*)customIdentifier didFailWithError:(NSError *)error;
/**
 * This method is called if the method call was successful and returns the result
 *
 * If this method is implemented the connect:didFinishWithResult: won't be called
 *
 * @param connection
 *            The used connection for the method call
 * @param customIdentifier
 *            Contains the custom identifier
 * @param result
 *            The result of the method call
 *
 */
- (void) connection:(id)connection withCustomIdentifier:(NSString*)customIdentifier didFinishWithResult:(NSArray *)result;
@end

/**
 * Provides methods to authorize and to perform call on the underlying
 * connections.
 */
@interface QCAuthorizedConnection : QCConnection
/**
 * Initializes a connection with default connection parameters. Token
 * storage will be provided.
 *
 * @param globalSettings
 *            global settings which will be used to establish the
 *            connection
 * @param tokenStorage
 *            token storage provider to persist the refresh token
 * @return initialized Object
 *
 */

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate;

- (id)initWithGlobalSettings:(QCGlobalSettings *)globalSettings
                tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
             sessionDelegate:(id<NSURLSessionDelegate>)delegate authToken:(QCOAuth2Token *)token;
/**
  * Authorize using the refresh token stored in persistent storage.
  *
  * @throws AuthException
  *             if there is no persistent token available
  */
- (void) authorizeWithError:(NSError * __autoreleasing *)error;

- (void) authorizeWithAuthCode:(NSString *) authCode error:(NSError **)error;

- (void) authorizeWithToken:(QCOAuth2Token *) authToken error:(NSError**)error;

/**
 * Refresh the OAuth2 access token using the provided refresh token. If
 * persistent token storage is provided, the new refresh token will be
 * persisted.
 *
 * @param refreshToken
 *            OAuth2 refresh token, may be null
 * @param error
 *      Contains an error if appropriate, may be nil
 * @return new refresh token
 * @throws AuthException
 *             on authorization errors
 */
- (NSString *) refreshWithRefreshToken:(NSString *) refreshToken error:(NSError **)error;

/**
 * Checks whether this connection is already authorized.
 *
 * @return true if this connection is successful authorized
 */
- (BOOL) isAuthorized;

/**
 * Logout. The stored authorization is deleted. If persistent token storage
 * is provided, the persistent token will be deleted.
 */
- (void)logout;

/**
 * Calls a methods.
 *
 * @param method
 *            method to call
 * @param error
 *            Contains the error if the call has failed.
 * @return Call result
 * @throws Exception
 *             Thrown on argument errors.
 */
- (NSArray *) callWithMethod:(QCRemoteMethod *)method error:(NSError **)error;

/**
 * Calls one or more methods
 *
 * @param error
 *            Contains the error if the call has failed.
 * @param firstMethod
 *            methods to call
 * @return Call result
 * @throws Exception
 *             Thrown on argument errors.
 */
- (NSArray *) callWithError:(NSError **)error methods:(QCRemoteMethod *) firstMethod, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Calls one or more methods
 *
 * @param error
 *            Contains the error if the call has failed.
 * @param methods
 *            methods to call
 * @return Call result
 * @throws Exception
 *             Thrown on argument errors.
 */
- (NSArray *) callAsBatchWithMethods:(NSArray *)methods error:(NSError *__autoreleasing *)error;

/**
 * Calls one or more methods asynchronously
 *
 * @param error
 *            Contains the error if the call has failed.
 * @param delegate
 *            Delegate to the call. The delegate is called on the MainThread
 * @param methods
 *            methods to call
 * @param customIdentifier
 *            Optional custom identifer. The identifier will be returned in the response.
 * @return YES if sent sucessfully
 * @throws Exception
 *             Thrown on argument errors.
 */
- (BOOL) callAsyncAsBatchWithMethods:(NSArray *)methods delegate:(id<QCConnectionDelegate>)delegate customIdentifier:(NSString*)customIdentifier error:(NSError *__autoreleasing *)error;

/**
 * Calls one or more methods asynchronously
 *
 * @param error
 *            Contains the error if the call has failed.
 * @param delegate
 *            Delegate to the call. The delegate is called on the MainThread
 * @param method
 *            method to call
 * @param customIdentifier
 *            Optional custom identifer. The identifier will be returned in the response.
 * @return YES if sent sucessfully
 * @throws Exception
 *             Thrown on argument errors.
 */
- (BOOL) callAsyncWithMethod:(QCRemoteMethod *)method delegate:(id<QCConnectionDelegate>)delegate customIdentifier:(NSString*)customIdentifier error:(NSError *__autoreleasing *)error;

/**
 * Calls a method with some parameters. The result is mapped into the
 * generic type T .
 *
 * @param classOfT
 *            class for result
 * @param methods
 *            Array of methods to call
 * @param error
 *            Contains the error if the call has failed.
 * @return Call result
 * @throws Exception
 *             Thrown on argument errors.
 */
- (NSArray *) callWithReturnClass:(Class)classOfT methods:(NSArray *)methods error:(NSError * __autoreleasing *)error;

/**
 * Get the token storage provided to allow subclasses to use it.
 *
 * @return token storage provider or null if not set
 */
- (id<QCPersistentTokenStorage>)tokenStorage;

/**
 * Returns the connection's OAuth2 access token.
 *
 * @return OAuth2 access token
 *
 * @param error
 *            Contains the error if the call has failed.
 * @return either session id or OAuth2 access token
 *
 */
- (NSString *) accessTokenWithError:(NSError * __autoreleasing *)error;

@property (readonly) NSString *accessToken;

/**
 * Returns the connection's OAuth2 refresh token.
 *
 * @return current OAuth2 refresh token
 * @throws AuthException
 *             if connection is not authorized
 */
- (NSString *) refreshTokenWithError:(NSError * __autoreleasing *)error;

@property (readonly) NSString *refreshToken;

/**
 * Returns the connection's OAuth2 access token expire timestamp.
 *
 * @return OAuth2 access token expire timestamp
 *
 * @param error
 *            Contains the error if the call has failed.
 */

- (double) accessTokenExpireTimeWithError:(NSError **)error;

@property (readonly) double accessTokenExpireTime;

/**
 * Get the specific type of the connection.
 *
 * @see ConnectionType
 * @return Specific type of the implemented connection
 */
- (ConnectionType) connectionType;

/**
 * Get the OAuth2 login url. Use this url to display the OAuth2 provider's
 * login page to retrieve the authorization code. This code can than be used
 * with {@link #authorizeWithError:} to create an OAuth2 access token.
 * <p>
 * Use this method only, do not use
 * {@link QCGlobalSettings#loginURLForEndpoint:} directly.
 *
 * @since 2.0
 *
 * @return url
 */
- (NSURL *) loginURL;

/**
 * Get the OAuth2 login url. Use this url to display the OAuth2 provider's
 * login page to retrieve the authorization code. This code can than be used
 * with {@link #authorizeWithError:} to create an OAuth2 access token.
 * <p>
 * The state parameter will not be used by the client api. It is appended to
 * the url and should be returned unmodified after successful login.
 * <p>
 * Use this method only, do not use
 * {@link QCGlobalSettings#loginURLForEndpoint:state:} directly.
 *
 * @since 2.0
 *
 * @param state
 *            state parameter, may be null
 * @return OAuth2 login url
 */
- (NSURL *) loginURLForState:(NSString *) state;

/**
 * Get the connection specific {@link QCGlobalSettings} that are different
 * whether this is a local or a remote connection.
 *
 * @return {@link QCGlobalSettings}
 */
- (QCGlobalSettings *) connectionSettings;

@end
