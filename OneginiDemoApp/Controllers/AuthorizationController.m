//
//  AuthCoordinator.m
//  OneginiDemoApp
//
//  Created by Sergey Butenko on 5/5/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import "AuthorizationController.h"
#import "AppDelegate.h"
#import "PinViewController.h"
#import "ProfileViewController.h"
#import "WebBrowserViewController.h"

@implementation AuthorizationController

+ (AuthorizationController *)sharedInstance {
    static AuthorizationController *singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
        
    });
    
    return singleton;
}

- (void)loginWithProfile:(NSString*)profile {
    [[OGOneginiClient sharedInstance] authenticateUser:[OGUserProfile profileWithId:profile] delegate:self];;
}

- (void)registerNewProfile {
    [[OGOneginiClient sharedInstance] registerUser:@[@"read"] delegate:self];
}

- (BOOL)isRegistered {
    return [[OGOneginiClient sharedInstance] isClientRegistered];
}

#pragma mark - OGAuthenticationDelegete

- (void)authenticationSuccessForProfile:(NSString *)profile{
    ProfileViewController *viewController = [ProfileViewController new];
    [[AppDelegate sharedNavigationController] pushViewController:viewController animated:YES];
}

- (void)requestAuthenticationCode:(NSURL *)url{
    WebBrowserViewController *webBrowserViewController = [WebBrowserViewController new];
    webBrowserViewController.url = url;
    webBrowserViewController.completionBlock = ^(NSURL* completionURL){
        if ([[AppDelegate sharedNavigationController].presentedViewController isKindOfClass:WebBrowserViewController.class]){
            [[AppDelegate sharedNavigationController] dismissViewControllerAnimated:YES completion:nil];
        }
    };
    [[AppDelegate sharedNavigationController] presentViewController:webBrowserViewController animated:YES completion:nil];
}

- (void)authenticationError{
    [self handleAuthError:nil];
}

- (void)authenticationError:(NSError *)error{
    [self handleAuthError:nil];
}

- (void)authenticationErrorInvalidScope{
    [self handleAuthError:nil];
}

- (void)authenticationErrorNotAuthenticated{
    [self handleAuthError:nil];
}

- (void)authenticationErrorNotAuthorized{
    [self handleAuthError:nil];
}

- (void)authenticationErrorInvalidProfile{
    [self handleAuthError:nil];
}

- (void)authenticationErrorAuthenticationInProgress{
    [self handleAuthError:nil];
}

- (void)authenticationErrorInvalidGrant:(NSUInteger)remaining{
    if ([[AppDelegate sharedNavigationController].topViewController isKindOfClass:PinViewController.class]){
        PinViewController *pinViewController = (PinViewController*)[AppDelegate sharedNavigationController].topViewController;
        [pinViewController reset];
        [pinViewController showError:[NSString stringWithFormat:@"Wrong Pin. Remaining attempts: %ld",remaining]];
    }
}

- (void)authenticationErrorClientRegistrationFailed:(NSError *)error{
    [self handleAuthError:nil];
}

- (void)authenticationErrorInvalidState{
    [self handleAuthError:nil];
}

- (void)authenticationErrorNoAuthenticationGrant{
    [self handleAuthError:nil];
}

- (void)authenticationErrorInvalidRequest{
    [self handleAuthError:nil];
}

- (void)authenticationErrorNoAccessToken{
    [self handleAuthError:nil];
}

-(void)authenticationErrorInvalidAppPlatformOrVersion{
    [self handleAuthError:@"Unsupported App version, please upgrade."];
}

-(void)authenticationErrorInvalidGrantType{
    [self handleAuthError:nil];
}

-(void)authenticationErrorTooManyPinFailures{
    [self handleAuthError:@"Too many Pin failures. User has been disconnected."];
}

-(void)authenticationErrorUnsupportedOS{
    [self handleAuthError:@"Unsupported iOS version, please upgrade."];
}

-(void)askForNewPin:(NSUInteger)pinSize profile:(NSString *)profile confirmationDelegate:(id<OGNewPinConfirmationDelegate>)delegate{
    PinViewController *viewController = [PinViewController new];
    viewController.pinLength = pinSize;
    viewController.mode = PINRegistrationMode;
    viewController.profile = [OGUserProfile profileWithId:profile];
    viewController.pinEntered = ^(NSString * pin) {
        [delegate confirmNewPin:pin validation:self];
    };
    [[AppDelegate sharedNavigationController] pushViewController:viewController animated:YES];
}

-(void)askForCurrentPinForProfile:(NSString *)profile pinConfirmationDelegate:(id<OGPinConfirmationDelegate>)delegate{
    PinViewController *viewController = [PinViewController new];
    viewController.pinLength = 5;
    viewController.mode = PINCheckMode;
    viewController.profile = [OGUserProfile profileWithId:profile];
    viewController.pinEntered = ^(NSString *pin) {
        [delegate confirmPin:pin];
    };
    [[AppDelegate sharedNavigationController] pushViewController:viewController animated:YES];
}

#pragma mark - OGPinValidationDelegate

- (void)pinBlackListed {
    [self handlePinPolicyValidationError:@"Pin is blacklisted!"];
}

- (void)pinShouldNotBeASequence {
    [self handlePinPolicyValidationError:@"Pin should not be a sequence!"];
}

- (void)pinShouldNotUseSimilarDigits:(NSUInteger)count {
    [self handlePinPolicyValidationError:[NSString stringWithFormat:@"Maximum number of similar digits are: %ld",count]];
}

- (void)pinTooShort {
    [self handlePinPolicyValidationError:@"Pin is too short!"];
}

- (void)pinEntryError:(NSError *)error {
    [self handlePinPolicyValidationError:@"Pin is not valid!"];
}

#pragma mark - 

- (void)handleAuthError:(NSString *)error {
    [[AppDelegate sharedNavigationController] popToRootViewControllerAnimated:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Authorization Error" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action){}];
    [alert addAction:okButton];
    [[AppDelegate sharedNavigationController] presentViewController:alert animated:YES completion:nil];
}

- (void)handlePinPolicyValidationError:(NSString *)error {
    if ([[AppDelegate sharedNavigationController].topViewController isKindOfClass:PinViewController.class]){
        PinViewController *pinViewController = (PinViewController*)[AppDelegate sharedNavigationController].topViewController;
        pinViewController.mode = PINRegistrationMode;
        [pinViewController reset];
        [pinViewController showError:error];
    }
}


@end