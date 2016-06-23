//
//  OGClientAuthenticationController.m
//  OneginiDemoApp
//
//  Created by Stanisław Brzeski on 19/06/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import "ClientAuthenticationController.h"
#import "AppDelegate.h"

@implementation ClientAuthenticationController

+ (ClientAuthenticationController *)sharedInstance {
    static ClientAuthenticationController *singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
        
    });
    
    return singleton;
}


-(void)authenticateClient{
    [[OGOneginiClient sharedInstance] authenticateClient:@[@"read"] delegate:self];
}

-(void)authenticationSuccess{
    [[AppDelegate sharedNavigationController] popToRootViewControllerAnimated:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Client authentication successful" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action){}];
    [alert addAction:okButton];
    [[AppDelegate sharedNavigationController] presentViewController:alert animated:YES completion:nil];
}

-(void)authenticationErrorUnsupportedOS{
    [self handleAuthError:nil];
}

-(void)authenticationError{
    [self handleAuthError:nil];
}

-(void)authenticationErrorNoAuthenticationGrant{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidGrantType{
    [self handleAuthError:nil];
}

-(void)authenticationErrorNotAuthorized{
    [self handleAuthError:nil];
}

-(void)authenticationErrorAuthenticationInProgress{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidState{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidScope{
    [self handleAuthError:nil];
}

-(void)authenticationErrorNotAuthenticated{
    [self handleAuthError:nil];
}

-(void)authenticationErrorClientRegistrationFailed:(NSError *)error{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidRequest{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidAppPlatformOrVersion{
    [self handleAuthError:nil];
}

- (void)handleAuthError:(NSString *)error {
    [[AppDelegate sharedNavigationController] popToRootViewControllerAnimated:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Client authentication error" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action){}];
    [alert addAction:okButton];
    [[AppDelegate sharedNavigationController] presentViewController:alert animated:YES completion:nil];
}

@end