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

#import "QCDiscoveryParserDelegate.h"

@interface QCDiscoveryParserDelegate () {
    // Odd, why does this work for the others?
    NSMutableString *_friendlyName;
    NSMutableString *_modelName;
    NSMutableString *_serialNumber;
}
@property (strong) NSMutableString *modelName;
@property (strong) NSMutableString *serialNumber;
@property (strong) NSMutableString *friendlyName;
@property (strong) NSMutableString *modelDescription;
@property (strong) NSMutableString *deviceType;
@property (strong) NSError *error;

@property (weak) NSMutableString *currentString;
@end

@implementation QCDiscoveryParserDelegate

#pragma mark -
#pragma mark NSXMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqual:@"modelName"]) {
        self.modelName = [NSMutableString new];
        self.currentString = _modelName;
    }
    else if ([elementName isEqual:@"serialNumber"]) {
        self.serialNumber = [NSMutableString new];
        self.currentString = _serialNumber;
    }
    else if ([elementName isEqual:@"friendlyName"]) {
        self.friendlyName = [NSMutableString new];
        self.currentString = _friendlyName;
    }
    else if ([elementName isEqual:@"modelDescription"]) {
        self.modelDescription = [NSMutableString new];
        self.currentString = _modelDescription;
    }
    else if ([elementName isEqualToString:@"deviceType"]) {
        self.deviceType = [NSMutableString new];
        self.currentString = _deviceType;
    }
    else
        self.currentString = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    self.currentString = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.error = parseError;
}


@end
