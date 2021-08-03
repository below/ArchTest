//
//  QCSystemPropertiesGlobalSettingsProvider.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import "QCSystemPropertiesGlobalSettingsProvider.h"
#import "QCLogger.h"

NSString * const QIVICON_CONNECTOR_PROPERTIES_FILE = @"qivicon.connector.properties";

NSString * const QIVICON_LOCAL_CONNECTOR_PROPERTIES_FILE = @"qivicon.local.connector.properties";

@interface QCSystemPropertiesGlobalSettingsProvider ()
@property (readwrite, nonatomic) QCGlobalSettings *remoteConnectionSettings;
@property (readwrite, nonatomic) QCGlobalSettings *localConnectionSettings;;
@end

@implementation QCSystemPropertiesGlobalSettingsProvider

+ (NSString *) QIVICON_CONNECTOR_PROPERTIES_FILE {
    return QIVICON_CONNECTOR_PROPERTIES_FILE;
}

+ (NSString *) QIVICON_LOCAL_CONNECTOR_PROPERTIES_FILE {
    return QIVICON_LOCAL_CONNECTOR_PROPERTIES_FILE;
}

@synthesize remoteConnectionSettings, localConnectionSettings;
/**
 * Read the property files and initialize the {@link QCGlobalSettings} accordingly.
 */
- (id) init {
    if ((self = [super init])) {
        self.remoteConnectionSettings = [self loadGlobalSettingsFromFile:QIVICON_CONNECTOR_PROPERTIES_FILE];
        self.localConnectionSettings = [self loadGlobalSettingsFromFile:QIVICON_LOCAL_CONNECTOR_PROPERTIES_FILE];
    }
    return self;
}

- (QCGlobalSettings *) loadGlobalSettingsFromFile:(NSString *)filename {
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    
    NSURL *url = [bundle URLForResource:filename withExtension:nil];
    
    if (url == nil) {
        [[QCLogger defaultLogger] debug:@"Property file '%@' not found.", QIVICON_CONNECTOR_PROPERTIES_FILE];
    } else {
        return [self readGlobalSettingsWithUrl:url];
    }
    
    return nil;
}


@end
