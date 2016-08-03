//  Copyright © 2016 Onegini. All rights reserved.

#import "FingerprintController.h"
#import "PinViewController.h"
#import "AppDelegate.h"

@interface FingerprintController ()

@property (nonatomic) PinViewController *pinViewController;

@end

@implementation FingerprintController

+ (instancetype)sharedInstance
{
    static FingerprintController *singleton;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)enrollForFingerprintAuthentication
{
    [[ONGUserClient sharedInstance] enrollForFingerprintAuthenticationWithDelegate:self];
}

- (BOOL)isFingerprintEnrolled
{
    return [[ONGUserClient sharedInstance] isEnrolledForFingerprintAuthentication];
}

- (void)disableFingerprintAuthentication
{
    [[ONGUserClient sharedInstance] disableFingerprintAuthentication];
}

- (void)unwindNavigationStack
{
    if ([AppDelegate sharedNavigationController].presentedViewController) {
        [[AppDelegate sharedNavigationController] dismissViewControllerAnimated:YES completion:^{
            [[AppDelegate sharedNavigationController] popToRootViewControllerAnimated:YES];
        }];
    }
}

- (void)dismissNavigationPresentedViewController:(void (^)(void))completion
{
    if ([AppDelegate sharedNavigationController].presentedViewController) {
        [[AppDelegate sharedNavigationController] dismissViewControllerAnimated:YES completion:completion];
    } else if (completion != nil) {
        completion();
    }
}

// MARK: - OGFingerprintDelegate

- (void)askCurrentPinForFingerprintEnrollmentForUser:(ONGUserProfile *)userProfile pinConfirmation:(id<ONGPinChallengeSender>)pinConfirmation
{
    PinViewController *viewController = [PinViewController new];
    self.pinViewController = viewController;
    viewController.pinLength = 5;
    viewController.mode = PINCheckMode;
    viewController.profile = userProfile;
    viewController.pinEntered = ^(NSString *pin) {
        [pinConfirmation respondWithPin:pin challenge:pinConfirmation];
    };
    [[AppDelegate sharedNavigationController] presentViewController:viewController animated:YES completion:nil];
}

- (void)fingerprintAuthenticationEnrollmentSuccessful
{
    [self dismissNavigationPresentedViewController:nil];
}

- (void)fingerprintAuthenticationEnrollmentFailure
{
    [self dismissNavigationPresentedViewController:nil];
    [self handleError:nil];
}

- (void)fingerprintAuthenticationEnrollmentFailureNotAuthenticated
{
    [self dismissNavigationPresentedViewController:nil];
}

- (void)fingerprintAuthenticationEnrollmentErrorInvalidPin:(NSUInteger)attemptCount
{
    [self dismissNavigationPresentedViewController:^{
        [self.pinViewController reset];
        [[AppDelegate sharedNavigationController] presentViewController:self.pinViewController animated:YES completion:nil];
    }];
}

- (void)fingerprintAuthenticationEnrollmentErrorUserDeregistered
{
    [self unwindNavigationStack];
}

- (void)fingerprintAuthenticationEnrollmentErrorDeviceDeregistered
{
    [self unwindNavigationStack];
}

- (void)handleError:(NSString *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fingerprint enrollment error" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [[AppDelegate sharedNavigationController] presentViewController:alert animated:YES completion:nil];
}

@end
