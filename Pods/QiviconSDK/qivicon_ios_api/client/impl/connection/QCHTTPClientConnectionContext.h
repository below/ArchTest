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
//  QCHTTPClientConnectionContext.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 19.03.13.
//

#import "QCHTTPConnectionContext.h"
#import "QCAuthHelper.h"
#import "QCAsyncAuthDelegateProtocol.h"

@interface QCHTTPClientConnectionContext : NSObject <QCHTTPConnectionContext>

- (id)init __attribute__((unavailable("Call initWithGlobalSettings: instead")));

@end
