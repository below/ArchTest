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

#import "QCErrors.h"

NSString * QCErrorDomainConnector         = @"com.qivicon.client.errors.connector";

NSString * QCErrorDomainAuth              = @"com.qivicon.client.errors.auth";

NSString * QCErrorDomainListener          = @"com.qivicon.client.errors.listener";


NSInteger NOT_AUTHORIZED                  = 1;

NSInteger LISTENER_NOT_FOUND              = 2;

NSInteger GATEWAYID_NOT_FOUND             = 3;

NSInteger AUTH_CONN_ERROR                 = 4;

NSInteger AUTH_REQUEST_FAILED             = 5;

NSInteger REFRESH_AUTH_REQUEST_FAILED     = 6;

NSInteger AUTH_REQUEST_TIME_OUT           = 7;

NSInteger GATEWAY_OFFLINE                 = 7;
