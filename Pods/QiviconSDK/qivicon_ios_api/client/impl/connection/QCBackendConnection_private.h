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
//  QCBackendConnection_private.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 10.01.13.
//

#import <Foundation/Foundation.h>
#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCBackendConnection.h"
#import "QCHTTPConnectionContext.h"
#import "QCAuthorizedConnection_private.h"

/**
 * Implementation of a QIVICON backend connection. This connection is used to
 * maintain a JSON-RPC communication link to the backend. Authorization is
 * necessary to use this connection. Authorization is managed by
 * {@link OAuthConnection}.
 */
@interface QCBackendConnection (private) <QCHTTPConnectionContextDelegate>
@end
