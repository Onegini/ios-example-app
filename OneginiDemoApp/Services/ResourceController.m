//
//  APIClient.m
//  OneginiDemoApp
//
//  Created by Sergey Butenko on 5/5/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import "ResourceController.h"
#import "OneginiSDK.h"
#import "Profile.h"

@interface ResourceController () <OGResourceHandlerDelegate>

@property (nonatomic, copy) ProfileCompletionBlock callback;
@property (nonatomic, strong) NSURL *baseURL;

@end

// Create dependencies here for demo purpose only. It shoud be set from the outside
@implementation ResourceController

+(instancetype)sharedInstance{
    static ResourceController *singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *configurationFilename = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"OGConfigurationFile"];
        NSString *configurationFilePath = [[NSBundle mainBundle] pathForResource:configurationFilename ofType:nil];
        NSMutableDictionary *config = [[NSDictionary dictionaryWithContentsOfFile:configurationFilePath] mutableCopy];
        self.baseURL = [[NSURL alloc] initWithString:config[@"kOGResourceGatewayURL"]];
    }
    return self;
}

- (void)getProfile:(ProfileCompletionBlock)completion {
    NSURL *url = [self.baseURL URLByAppendingPathComponent:@"api/persons"];

    self.callback = completion;
    [[OGOneginiClient sharedInstance] fetchResource:url.absoluteString scopes:nil requestMethod:GET params:nil delegate:self];
}

- (void)handleResponse:(NSData *)response {
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:response options:0 error:NULL];
    
    Profile *profile = [Profile profileFromJSON:json];
    if (self.callback) {
        self.callback(profile, nil);
        self.callback = nil;
    }
}

- (void)handleError:(NSError *)error {
    if (self.callback) {
        self.callback(nil, error);
        self.callback = nil;
    }
}

#pragma mark - OGResourceHandlerDelegate

- (void)resourceError {
    [self handleError:nil];
}

- (void)resourceBadRequest {
    [self handleError:nil];
}

- (void)resourceErrorAuthenticationFailed {
    [self handleError:nil];
}

- (void)scopeError {
    [self handleError:nil];
}

- (void)unauthorizedClient {
    [self handleError:nil];
}

- (void)resourceSuccess:(id)response {
    [self handleResponse:response];
}

- (void)resourceSuccess:(id)response
                headers:(NSDictionary *)headers {
    [self handleResponse:response];
}

- (void)invalidGrantType {
    [self handleError:nil];
}

@end
