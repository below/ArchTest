//
//  QCFileGlobalSettingsProvider.m
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 31.10.13.
//  Copyright (c) 2013 Alexander v. Below. All rights reserved.
//

#import "QCFileGlobalSettingsProvider.h"

@interface QCFileGlobalSettingsProvider ()
@property (nonatomic, readwrite) QCGlobalSettings *remoteConnectionSettings;
@property (nonatomic, readwrite) QCGlobalSettings *localConnectionSettings;
@end

@implementation QCFileGlobalSettingsProvider
@synthesize remoteConnectionSettings, localConnectionSettings;

- (id) initWithURLForRemoteConnections:(NSURL *)urlForRemoteConnections
                urlForLocalConnections:(NSURL *)urlForLocalConnections {
    if ((self = [super init])) {
        self.remoteConnectionSettings = [self readGlobalSettingsWithUrl:urlForRemoteConnections];
        self.localConnectionSettings = [self readGlobalSettingsWithUrl:urlForLocalConnections];
    }
    return self;
}


@end
