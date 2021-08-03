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
//  ConnectionContext.m
//  QIVICON_Sample
//
//  Created by Alexander v. Below on 10.01.13.
//

/** HTTP header name for the OAuth2 token. */
NSString * const HEADER_AUTHORIZATION = @"Authorization";
/** Start string of an Basic Auth string */
NSString * const BASIC = @"Basic ";
/** HTTP header name for the id of the <i>Service Gateway</i>. */
NSString * const HEADER_QIVICON_SERVICE_GATEWAY_ID = @"QIVICON-ServiceGatewayId";
/** Standard Charset: UTF-8 */
NSString * const UTF_8 = @"UTF-8";
/** The "http://" prefix */
NSString * const HTTP_PROTOCOL = @"http";
/** The "https://" prefix */
NSString * const HTTPS_PROTOCOL = @"https";
/** The "ws://" prefix */
NSString * const WS_PROTOCOL = @"ws";
/** The "wss://" prefix */
NSString * const WSS_PROTOCOL = @"wss";
/** The url used for local communication with a Service Gateway */
NSString * const RPC_URL = @"/remote/json-rpc";
/** The local OAuth2 authorization endpoint */
NSString * const OAUTH_AUTHORIZE_ENDPOINT = @"/system/oauth/authorize";
/** The local OAuth2 token endpoint */
NSString * const OAUTH_TOKEN_ENDPOINT = @"/system/oauth/token";
/** The url used for web sockets */
NSString * const WS_URL = @"/remote/events/";
/** The url used for the local system information */
NSString * const SYSTEM_INFO_ENDPOINT = @"/system/info";
/** default https port */
int const HTTPS_PORT = 443;
/** default http port */
int const HTTP_PORT = 80;
/** default web sockets port */
int const WS_PORT = 8081;
/** default secure sockets port */
int const WSS_PORT = 8444;
/** default http port for json-rpc communication (8080) */
int const HTTP_PORT2 = 8080;
