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
//  QCUpnpDiscoveryService.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 07.02.13.
//


#import "QCConnection.h" // We need this because we forward-declare QCConnection in the public API
#import "QCUpnpDiscoveryService.h"
#import "QCGCDAsyncUdpSocket.h"
#import "QCLogger.h"
#import "QCDiscoveryParserDelegate.h"
#import "QCGlobalSettings.h"
#import "QCHTTPConnectionContext.h"
#import "QCHTTPClientConnectionContext.h"
#import "QCPersistentTokenStorage.h"
#import "QCUtils.h"
#import "QCCertificateManager.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>

@interface QCUpnpDiscoveryService ()
@property (weak) id <QCDiscoveryDelegate> delegate;
@property (atomic) BOOL searchDone;
@property (strong) NSError *error;
@property (strong) NSString *identifier;
@property float timeout;
@property (strong) NSDate *timeoutDate;
@property (strong) QCGCDAsyncUdpSocket *clientSocket;
@property (strong) NSLock *lookupLock;
@property (nonatomic) id <QCPersistentTokenStorage> tokenStorage;
@property (nonatomic) QCGlobalSettings * globalSettings;
@end

@implementation QCUpnpDiscoveryService {
    NSMutableArray *_connections;
}

/** default UPnP port */
static const int UPNP_PORT = 1900;

/** min timeout: 1s */
static const int MIN_TIMEOUT = 1000;

/** mac timeout: 20s */
static const int MAX_TIMEOUT = 20000;

/** default timeout: 10s */
static const int DEFAULT_TIMEOUT = 10000;

/** UPnP multicast address */
static NSString * const SSDP_MULTICAST_ADDRESS = @"239.255.255.250";

/**
 * specific type of <i>Service Gateway</i>: "upnp:rootdevice"
 */
static NSString * const SEARCH_DATA_QHB = @"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 5\r\nST: upnp:rootdevice\r\n\r\n"; // QHB1, QHB2

static NSString * const SEARCH_DATA_SPEEDPORT = @"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 5\r\nST: urn:telekom-de:device:TO_InternetGatewayDevice:2\r\n\r\n"; // SpeedportSmart

@synthesize delegate = _delegate;

dispatch_queue_t discoveryQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("qivicon.discovery.queue", 0);
    });
    return queue;
}

- (NSArray *)lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                            tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                                   error:(NSError **)error {
    return [self lookupWithGlobalSettings:globalSettings
                             tokenStorage:tokenStorage
                                  timeout:DEFAULT_TIMEOUT
                                 delegate:nil
                                    error:error];
}

- (NSArray *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                             tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                                  timeout:(int)timeout
                                 delegate:(id<QCDiscoveryDelegate>)delegate
                                    error:(NSError *__autoreleasing *)error {
    
    return [self lookupWithGlobalSettings:globalSettings
                                tokenStorage:tokenStorage
                                   gatewayId:nil
                                     timeout:timeout
                                    delegate:delegate];
}

- (NSArray *)lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                         tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                              timeout:(int)timeout
                                error:(NSError *__autoreleasing *)error {
    
    return [self lookupWithGlobalSettings:globalSettings
                             tokenStorage:tokenStorage
                                  timeout:timeout
                                 delegate:nil
                                    error:error];    
}


/**
 * Searches for <i>Service Gateways</i>. If id is specified, only the Service Gateway
 * with that specific id is searched. Method will return immediately, if
 * this device has been found.
 *
 * @param globalSettings
 *            global settings to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param id
 *            Service Gateway id or null. If this parameter is null, the method
 *            will return on timeout.
 * @param timeout
 *            search timeout in milliseconds. Timeout must be specified
 *            between 1000 and 20000.
 * @param callback
 *            will be called for each device found
 * @return array of LocalConnection objects of all gateways found or null.
 * @throws DiscoveryException
 *             on errors
 */
- (BOOL)lookupAsyncWithGlobalSettings:(QCGlobalSettings *)globalSettings
                            tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                               gatewayId:(NSString*) identifier
                                 timeout:(int)timeout
                                delegate:(id <QCAsyncDiscoveryDelegate>)delegate {
    
    if (timeout < MIN_TIMEOUT || timeout > MAX_TIMEOUT) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"Illegal timeout! Timeout must be between %d and %d.", MIN_TIMEOUT, MAX_TIMEOUT]
                               userInfo:nil] raise];
    }
    [self cancelTimeout];
    self.searchDone = NO;
    self.globalSettings = globalSettings;
    self.timeout = (float)timeout/1000.00;
    self.timeoutDate = [NSDate dateWithTimeIntervalSinceNow:self.timeout];
    self.clientSocket = nil;
    self.tokenStorage = tokenStorage;
    _connections = nil;
    
    self.delegate = delegate;
    self.identifier = identifier;
    self.clientSocket = [[QCGCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue: discoveryQueue()];
    
    NSError *error = nil;
    [self.clientSocket bindToPort:0 error:&error];
    if (error != nil) {
        [self.clientSocket close];
        self.clientSocket = nil;
        return NO;
    }
    
    if (![self.clientSocket beginReceiving:&error])
    {
        [self.clientSocket close];
        self.clientSocket = nil;
        return NO;
    }
    
    NSData *sendDataQHB = [SEARCH_DATA_QHB dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sendDataSpeeport = [SEARCH_DATA_SPEEDPORT dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket sendData:sendDataQHB toHost:SSDP_MULTICAST_ADDRESS
                           port:UPNP_PORT
                    withTimeout:-1 tag:(long)identifier];
    
    [self.clientSocket sendData:sendDataSpeeport toHost:SSDP_MULTICAST_ADDRESS
                           port:UPNP_PORT
                    withTimeout:-1 tag:(long)identifier];
    
    [self resetTimeout];
    return YES;
}

- (void)cancelTimeout{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discoveryDidFinish) object:nil];
}

- (void)resetTimeout{
    [self cancelTimeout];
    [self performSelector:@selector(discoveryDidFinish) withObject:nil afterDelay:self.timeout];
}

- (void)discoveryDidFinish{
    [self.clientSocket close];
    self.clientSocket = nil;
    self.searchDone = YES;
    if ([self.delegate respondsToSelector:@selector(discoveryServiceFinished:)])
        [(id <QCAsyncDiscoveryDelegate>)self.delegate discoveryServiceFinished:self];
}

/**
 * Searches for <i>Service Gateways</i>. If id is specified, only the Service Gateway
 * with that specific id is searched. Method will return immediately, if
 * this device has been found.
 *
 * @param globalSettings
 *            global settings to be used for create
 *            {@link LocalServiceGatewayConnection}s
 * @param tokenStorage
 *            the {@link PersistentTokenStorage} or null
 * @param id
 *            Service Gateway id or null. If this parameter is null, the method
 *            will return on timeout.
 * @param timeout
 *            search timeout in milliseconds. Timeout must be specified
 *            between 1000 and 20000.
 * @param callback
 *            will be called for each device found
 * @return array of LocalConnection objects of all gateways found or null.
 * @throws DiscoveryException
 *             on errors
 */
- (NSArray *)lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                            tokenStorage:(id <QCPersistentTokenStorage>)tokenStorage
                               gatewayId:(NSString*) identifier
                                 timeout:(int)timeout
                                delegate:(id <QCDiscoveryDelegate>)delegate
{
    BOOL success = [self lookupAsyncWithGlobalSettings:globalSettings
                                             tokenStorage:tokenStorage
                                                gatewayId:identifier
                                                  timeout:timeout
                                                 delegate:(id <QCAsyncDiscoveryDelegate>)delegate];
    while (success && self.searchDone == NO ) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.25]];
        }
    }
    [self.clientSocket close];
    self.clientSocket = nil;
    return _connections;
}

- (QCLocalServiceGatewayConnection *) lookupWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                                  tokenStorage:(id<QCPersistentTokenStorage>)tokenStorage
                                              deviceIdentifier:(NSString *)identifier
                                                         error:(NSError *__autoreleasing *)error
{
    QCLocalServiceGatewayConnection *conn = nil;
    
    NSArray * c = [self lookupWithGlobalSettings:globalSettings
                                       tokenStorage:tokenStorage
                                          gatewayId:identifier
                                            timeout:DEFAULT_TIMEOUT
                                           delegate:nil];
    
    for (QCLocalServiceGatewayConnection *connection in c) {
        if ([connection.gwId isEqualToString:identifier]){
            conn = connection;
        }
    }
    return conn;
}

/**
 * Parses the response of the UPnP lookup. A typical response looks like
 * this:
 *
 * <pre>
 * HTTP/1.1 200 OK
 * CACHE-CONTROL: max-age=1800
 * DATE: Thu, 19 Jul 2012 08:06:11 GMT
 * EXT:
 * LOCATION: http://192.168.178.26:49152/upnpbd4.xml
 * OPT: "http://schemas.upnp.org/upnp/1/0/"; ns=01
 * 01-NLS: 823551e4-1dd2-11b2-80d3-c2b5b67a3bb9
 * SERVER: Linux/2.6.34.9-WR4.2.0.0_sen, UPnP/1.0, Portable SDK for UPnP devices/1.6.12
 * X-User-Agent: redsonic
 * ST: urn:schemas-upnp-org:device:basic:1
 * USN: uuid:8253d664-cff5-11e1-9faa-0025dc45ca9a::urn:schemas-upnp-org:device:basic:1
 * </pre>
 *
 * A typical XML document returned from the LOCATION url looks like this:
 *
 * <pre>
 * &lt;root xmlns="urn:schemas-upnp-org:device-1-0"&gt;
 *     &lt;specVersion&gt;
 *         &lt;major&gt;1&lt;/major&gt;
 *         &lt;minor&gt;0&lt;/minor&gt;
 *     &lt;/specVersion&gt;
 *     &lt;URLBase&gt;http://192.168.178.26:49152&lt;/URLBase&gt;
 *     &lt;device&gt;
 *         &lt;deviceType&gt;urn:schemas-upnp-org:device:basic:1&lt;/deviceType&gt;
 *         &lt;friendlyName&gt;qivicon.ip&lt;/friendlyName&gt;
 *         &lt;manufacturer&gt;Deutsche Telekom AG&lt;/manufacturer&gt;
 *         &lt;manufacturerURL&gt;http://www.telekom.de/&lt;/manufacturerURL&gt;
 *         &lt;modelDescription&gt;QIVICON&lt;/modelDescription&gt;
 *         &lt;modelName&gt;QIVICON&lt;/modelName&gt;
 *         &lt;modelNumber/&gt;
 *         &lt;modelURL/&gt;
 *         &lt;serialNumber&gt;3647100390&lt;/serialNumber&gt;
 *         &lt;UDN&gt;uuid:8253d664-cff5-11e1-9faa-0025dc45ca9a&lt;/UDN&gt;
 *         &lt;UPC/&gt;
 *         &lt;presentationURL&gt;http://192.168.178.26&lt;/presentationURL&gt;
 *     &lt;/device&gt;
 * &lt;/root&gt;
 * </pre>
 *
 * @param response
 *            string
 * @return LocalConnection found or null
 * @throws UpnpParseException
 *             on any error
 */

- (QCLocalServiceGatewayConnection *) parseUPnPResultWithGlobalSettings:(QCGlobalSettings *)globalSettings
                                                                  response:(NSString *)response /* throws UpnpParseException */ {
    QCLocalServiceGatewayConnection * conn = nil;
    
    NSScanner *responseScanner = [NSScanner scannerWithString:response];
    // get the device url
    NSString *url = nil;
    NSString *locationMarker = @"LOCATION: ";
    [responseScanner scanUpToString:locationMarker intoString:nil];
    [responseScanner scanString:locationMarker intoString:nil];
    [responseScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                    intoString:&url];
    NSURL *u = [NSURL URLWithString:url];
    
    NSString *ipAddr = u.host;
    // Here is the IPv6 check. In order to access it locally, the addres should be enclosed in right brackets:[].
    ipAddr = [ipAddr stringByFormattingForIPv6];
    if ([ipAddr isValidIPv6Address]) {
        ipAddr = [NSString stringWithFormat:@"[%@]", ipAddr];
    }
    
    [[QCLogger defaultLogger] debug:@"%@", url];
    
    if (ipAddr == nil && [u isFileURL]) { // This is for Unit Testing only!
        ipAddr = @"127.0.0.1";
    }
    
    // parse the XML document, modelName must contain "QIVICON"
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:u];
    QCDiscoveryParserDelegate *parserDelegate = [QCDiscoveryParserDelegate new];
    parser.delegate = parserDelegate;
    [parser parse];
    
    if (parserDelegate.error != nil) {
        [[QCLogger defaultLogger] error:@"%@", parserDelegate.error];
        return nil;
    }
    
    BOOL isWlanDevice = [self isWLANDevice:parserDelegate];
    
    if ([self isValidGatewayModel:parserDelegate.modelDescription] && !isWlanDevice) {
        NSString *sn = parserDelegate.serialNumber;
        NSString *name = parserDelegate.friendlyName;
        
        [[QCLogger defaultLogger] info:@"Service Gateway %@ found with address %@ and serial number %@", name, ipAddr, sn];
        
        if (sn && [sn isKindOfClass:[NSString class]] && sn.length >0) {
            if ([name isEqualToString:@"Speedport Smart 3"] || [name isEqualToString:@"Speedport Pro"]) {
                struct hostent *hostentry;
                hostentry = gethostbyname("qivicon.ip");
                
                if (hostentry) {
                    char * ipbuf;
                    ipbuf = inet_ntoa(*((struct in_addr *)hostentry->h_addr_list[0]));
                    NSString *ipAddress = [NSString stringWithCString:ipbuf encoding:NSUTF8StringEncoding];
                    
                    if (ipAddress && ipAddress.length > 0) {
                        ipAddr = ipAddress;
                    } else {
                        return nil;
                    }
                } else {
                    return nil;
                }
            }
            
            conn = [[QCLocalServiceGatewayConnection alloc] initWithGlobalSettings:globalSettings
                                                                      tokenStorage:self.tokenStorage
                                                                              GWID:sn
                                                                           address:ipAddr
                                                                              name:name];
        }
    }
    
    return conn;
}

/**
 * Checks whether this is a validService Gateway or not.
 *
 * @param modelDescription
 *            model description from descriction
 * @return true, if it is a valid Service Gateway
 */
- (BOOL) isValidGatewayModel:(NSString *) modelDescription {
    
    if (modelDescription && modelDescription.length >0 &&
        ([modelDescription.uppercaseString rangeOfString:@"QIVICON"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"3102"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"3101"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"SPEEDPORT SMART"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"SPEEDPORT PRO"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"SPEEDPORT PRO PLUS"].location != NSNotFound ||
         [modelDescription.uppercaseString rangeOfString:@"SPEEDPORT PRO PLUS GAMING EDITION"].location != NSNotFound)) {
        return YES;
    }

    return NO;
}

- (BOOL)isWLANDevice:(QCDiscoveryParserDelegate *)device {
    NSRange wlanRange = [device.deviceType.lowercaseString rangeOfString:@"WLANAccessPointDevice".lowercaseString];
    return wlanRange.location != NSNotFound;
}

#pragma mark -
#pragma mark Connection Delegate Methods

- (void)udpSocket:(QCGCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext {
    
    dispatch_async(discoveryQueue(), ^{
        [self resetTimeout];
        
        if ([sock isClosed]) {
            [self discoveryDidFinish];
            return;
        }
        
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (response) {
            QCLocalServiceGatewayConnection *c = [self parseUPnPResultWithGlobalSettings:self.globalSettings
                                                                                   response:response];
            // check, the parse may have failed!
            if (c != nil) {
                if (_connections == nil) {
                    _connections = [NSMutableArray new];
                }
                
                BOOL alreadyAdded = NO;
                for (NSUInteger index = 0; index < _connections.count; index++) {
                    QCLocalServiceGatewayConnection *conn = _connections[index];
                    if ([conn.gwId isEqualToString:c.gwId]) {
                        alreadyAdded = YES;
                    }
                }
                
                if (!alreadyAdded) {
                    @synchronized (_connections) {
                        [_connections addObject:c];
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(service:foundDeviceWithConnection:)]) {
                    [self.delegate service:self foundDeviceWithConnection:c];
                }
                
                if (self.identifier.length > 0 && [c.gwId isEqual:self.identifier]) {
                    // leave loop immediately
                    [self cancelTimeout];
                    [self discoveryDidFinish];
                    return;
                }
            }
            
            [self resetTimeout];
        }
    });
}

@end
