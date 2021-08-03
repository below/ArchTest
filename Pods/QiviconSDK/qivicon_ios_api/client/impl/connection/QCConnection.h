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
#import "QCGlobalSettings.h"

@protocol QCHTTPConnectionContext;

/**
 * Abstract base class for all connections.
 * <p>
 * All connections must provide two constructors. The default constructor must
 * create the connection with default connection parameters. The alternative
 * constructor uses {@link QCGlobalSettings} as the only argument, providing the
 * connection parameters within this class.
 *
 */
@interface QCConnection :NSObject

@property(nonatomic, readonly, strong) NSOperationQueue * _Nonnull queue;

/**
 * Do not call this method. Call initWithConnectionContext: instead 
 */
- (id _Null_unspecified) init __attribute__((unavailable("Call initWithConnectionContext:")));

/**
 * Initializes a connection with default connection parameters.
 *
 * @param globalSettings
 *            globalSettings which will be used to establish the connection
 */

- (id _Nonnull)initWithGlobalSettings:(QCGlobalSettings * _Nonnull)globalSettings
             sessionDelegate:(id<NSURLSessionDelegate> _Nullable)delegate;
/**
 * The NSURLSession used for this connection
 *
 * @return NSURLSessoin
 */
@property (readonly, nonnull) NSURLSession *session;

/**
 * Get the global settings for all subclasses to avoid declaring a protected
 * member.
 *
 * @return global settings
 */
@property (readonly) QCGlobalSettings * _Nonnull globalSettings;

@end
