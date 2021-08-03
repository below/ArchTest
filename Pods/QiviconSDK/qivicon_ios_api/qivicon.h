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

#import "QCConnectionFactory.h"
#import "QCGlobalSettings.h"
#import "QCServiceGatewayConnection.h"
#import "QCConnection.h"
#import "QCLocalServiceGatewayConnection.h"
#import "QCBackendConnection.h"
#import "QCAuthorizedConnection.h"
#import "QCPersistentTokenStorage.h"
#import "QCRemoteMethod.h"
#import "QCServiceGatewayEventConnection.h"
#import "QCServiceGatewayEventListener.h"
#import "QCOAuth2Token.h"
#import "QCResultElement.h"
#import "QCServiceGatewayEvent.h"
#import "QCErrors.h"
#import "QCSystemPropertiesGlobalSettingsProvider.h"
#import "QCUtils.h"
