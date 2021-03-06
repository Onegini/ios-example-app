//
// Copyright (c) 2016 Onegini. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MobileAuthenticationOperation.h"
#import "PinViewController.h"
#import "PushConfirmationViewController.h"
#import "PinErrorMapper.h"
#import "ZFModalTransitionAnimator.h"
#import "ProfileModel.h"
#import "AlertPresenter.h"
#import "ExperimentalCustomAuthenticatiorViewController.h"

@interface MobileAuthenticationOperation ()

@property (nonatomic) PinViewController *pinViewController;
@property (nonatomic) UIViewController *preservedViewController;
@property (nonatomic) UITabBarController *tabBarController;

@property (nonatomic) BOOL preparedForPresentation;

@end

@implementation MobileAuthenticationOperation

#pragma mark - Init

- (instancetype)initWithPendingMobileAuthRequest:(ONGPendingMobileAuthRequest *)pendingMobileAuthRequest
                                      userClient:(ONGUserClient *)userClient
                            navigationController:(UINavigationController *)navigationController
                                tabBarController:(UITabBarController *)tabBarController
{
    self = [super init];
    if (self) {
        _pendingMobileAuthRequest = pendingMobileAuthRequest;
        _userClient = userClient;
        _navigationController = navigationController;
        _tabBarController = tabBarController;
    }
    return self;
}

- (instancetype)initWithOTPRequest:(NSString *)otpRequest
                        userClient:(ONGUserClient *)userClient
                  tabBarController:(UITabBarController *)tabBarController
              navigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self) {
        _otpRequest = otpRequest;
        _userClient = userClient;
        _navigationController = navigationController;
        _tabBarController = tabBarController;
    }
    return self;
}

#pragma mark - Execution

- (void)executionStarted
{
    // This method is going to be invoked from the background queue, so we need move execution to the main.
    // Result of calling the SDK from the background thread is undefined.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.pinViewController = [[PinViewController alloc] init];
        if (self.otpRequest) {
            [self.userClient handleOTPMobileAuthRequest:self.otpRequest delegate:self];
        } else {
            [self.userClient handlePendingPushMobileAuthRequest:self.pendingMobileAuthRequest delegate:self];
        }
    });
}

- (void)executionFinished
{
    if (self.preservedViewController) {
        [self.tabBarController presentViewController:self.preservedViewController animated:YES completion:nil];
    }
}

/// There might be an active alert (or any other controller) presented on the top of the screen. We need to preserve it somehow.
/// You also might want to add a new transparent UIWindow on top and present your confirmation completely independently from the
/// current UI state.
- (void)performSafeConfirmationPresentation:(void (^)(void))presentation
{
    if (self.preparedForPresentation) {
        presentation();
    } else {
        self.preparedForPresentation = YES;

        if (self.tabBarController.presentedViewController) {
            self.preservedViewController = self.tabBarController.presentedViewController;
            [self.tabBarController dismissViewControllerAnimated:YES completion:presentation];
        } else {
            presentation();
        }
    }
}

#pragma mark - ONGMobileAuthenticationRequestDelegate

- (void)userClient:(ONGUserClient *)userClient didReceiveConfirmationChallenge:(void (^)(BOOL confirmRequest))confirmation forRequest:(ONGMobileAuthRequest *)request
{
    PushConfirmationViewController *pushVC = [PushConfirmationViewController new];
    pushVC.pushMessage.text = request.message;
    pushVC.pushTitle.text = [NSString stringWithFormat:@"Confirm push for user: %@", [[ProfileModel sharedInstance] profileNameForUserProfile:request.userProfile]];
    pushVC.pushConfirmed = ^(BOOL confirmed) {
        [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
        confirmation(confirmed);
    };

    [self performSafeConfirmationPresentation:^{
        [self.tabBarController presentViewController:pushVC animated:YES completion:nil];
    }];
}

/**
 * SDK sends a challenge in order to authenticate the user. In case the user has entered an invalid pin or the SDK wasn't able to
 * connect to the server this method will be invoked again. You may want to inspect the `challenge.error` property to understand the reason of the error.
 * In addition to the error property the `challenge` also maintains `previousFailureCount`, `maxFailureCount` and `remainingFailureCount` these
 * reflect the number of PIN attemps left. The user gets deregistered once the number of attempts is exceeded.
 *
 * Note: during errors that are not related to the PIN validation such as network errors the attempts counter remains untouched.
 */
- (void)userClient:(ONGUserClient *)userClient didReceivePinChallenge:(ONGPinChallenge *)challenge forRequest:(ONGMobileAuthRequest *)request
{
    [self.pinViewController reset];
    self.pinViewController.mode = PINCheckMode;
    self.pinViewController.pinLength = 5;
    self.pinViewController.customTitle = [NSString stringWithFormat:@"Push with pin for user: %@", [[ProfileModel sharedInstance] profileNameForUserProfile:challenge.userProfile]];

    self.pinViewController.pinEntered = ^(NSString *pin, BOOL cancelled) {
        if (pin) {
            [challenge.sender respondWithPin:pin challenge:challenge];
        } else if (cancelled) {
            [challenge.sender cancelChallenge:challenge];
        }
    };

    [self performSafeConfirmationPresentation:^{
        // It is up to the developer to decide when and how to show PIN entry view controller.
        // For simplicity of the example app we're checking the top-most view controller.
        if (![self.tabBarController.presentedViewController isEqual:self.pinViewController]) {
            [self.tabBarController presentViewController:self.pinViewController animated:YES completion:nil];
        }

        if (challenge.error) {
            // Please read comments for the PinErrorMapper to understand the intent of this class and how errors can be handled.
            NSString *description = [PinErrorMapper descriptionForError:challenge.error ofPinChallenge:challenge];
            [self.pinViewController showError:description];
        }
    }];
}

/**
 * In contract with -userClient:didReceivePinChallenge:forRequest: is not going to be called again in case or error - SDK fallbacks to the PIN instead.
 * This also doesn't affect on the PIN attempts count. Thats why we can skip any error handling for the fingerpint challenge.
 */
- (void)userClient:(ONGUserClient *)userClient didReceiveFingerprintChallenge:(ONGFingerprintChallenge *)challenge forRequest:(ONGMobileAuthRequest *)request
{
    PushConfirmationViewController *pushVC = [PushConfirmationViewController new];
    pushVC.pushMessage.text = request.message;
    pushVC.pushTitle.text = [NSString stringWithFormat:@"Confirm push with fingerprint for user: %@", [[ProfileModel sharedInstance] profileNameForUserProfile:request.userProfile]];
    pushVC.pushConfirmed = ^(BOOL confirmed) {
        [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
        if (confirmed) {
            [challenge.sender respondWithDefaultPromptForChallenge:challenge];
        } else {
            [challenge.sender cancelChallenge:challenge];
        }
    };

    [self performSafeConfirmationPresentation:^{
        [self.tabBarController presentViewController:pushVC animated:YES completion:nil];
    }];
}

- (void)userClient:(ONGUserClient *)userClient didReceiveCustomAuthFinishAuthenticationChallenge:(ONGCustomAuthFinishAuthenticationChallenge *)challenge forRequest:(ONGMobileAuthRequest *)request
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Mobile Auth"
                                                                   message:[NSString stringWithFormat:@"Confirm push with %@ for %@", challenge.authenticator.name, [[ProfileModel sharedInstance] profileNameForUserProfile:request.userProfile]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __block UITextField *alertTextField;
    if ([challenge.authenticator.identifier isEqualToString:@"PASSWORD_CA_ID"]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.accessibilityIdentifier = @"CustomAuthenticatorAlertTextField";
            alertTextField = textField;
        }];
    }
    
    UIAlertAction *authenticateButton = [UIAlertAction actionWithTitle:@"Authenticate"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   if ([challenge.authenticator.identifier isEqualToString:@"PASSWORD_CA_ID"]) {
                                                                       [challenge.sender respondWithData:alertTextField.text challenge:challenge];
                                                                   } else if ([challenge.authenticator.identifier isEqualToString:@"EXPERIMENTAL_CA_ID"]) {
                                                                       [self showExperimentalCA:challenge];
                                                                   }
                                                               }];
    
    UIAlertAction *pinFallbackButton = [UIAlertAction actionWithTitle:@"Fallback to PIN"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [challenge.sender respondWithPinFallbackForChallenge:challenge];
                                                              }];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [challenge.sender cancelChallenge:challenge underlyingError:nil];
                                                         }];
    
    [alert addAction:authenticateButton];
    [alert addAction:pinFallbackButton];
    [alert addAction:cancelButton];
    [self.tabBarController presentViewController:alert animated:YES completion:nil];
}

- (void)userClient:(ONGUserClient *)userClient didHandleMobileAuthRequest:(ONGMobileAuthRequest *)request info:(ONGCustomInfo * _Nullable)customAuthInfo
{
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];

    // Once the SDK reported that the `request` has been handled we need to finish our operation and free-up the queue.
    [self finish];
}

- (void)userClient:(ONGUserClient *)userClient didFailToHandleMobileAuthRequest:(ONGMobileAuthRequest *)request error:(NSError *)error
{
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
    
    if (error.code == ONGGenericErrorUserDeregistered) {
        // In case the user is deregistered on the server side the SDK will return the ONGGenericErrorUserDeregistered error. There are a few reasons why this can
        // happen (e.g. the user has entered too many failed PIN attempts). The app needs to handle this situation by deleting any locally stored data for the
        // deregistered user.
        [[ProfileModel sharedInstance] deleteProfileNameForUserProfile:request.userProfile];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else if (error.code == ONGGenericErrorDeviceDeregistered) {
        // In case the entire device registration has been removed from the Token Server the SDK will return the ONGGenericErrorDeviceDeregistered error. In this
        // case the application needs to remove any locally stored data that is associated with any user. It is probably best to reset the app in the state as if
        // the user is starting up the app for the first time.
        [[ProfileModel sharedInstance] deleteProfileNames];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else if (error.code == ONGMobileAuthRequestErrorNotFound) {
        // For some reason the mobile authentication request cannot be found on the Token Server anymore. This can happen if a push notification
        // was delivered with a huge delay and a mobile authentication request was already removed from the Token Server because it expired.
    } else if (error.code == ONGGenericErrorActionCancelled) {
        // If a challenge has been cancelled then the ONGGenericErrorActionCancelled error is returned. You can use this error to determine whether a mobile
        // authentication request was cancelled. You can also ignore it if you are not interested in this.
    }
    
    [self showError:error];
    // Once SDK reported that the `request` has been handled we need to finish our operation and free-up queue.
    [self finish];
}

- (void)showError:(NSError *)error
{
    AlertPresenter *errorPresenter = [AlertPresenter createAlertPresenterWithTabBarController:self.tabBarController];
    [errorPresenter showErrorAlert:error title:@"Mobile Auth Error"];
}

- (void)showExperimentalCA:(ONGCustomAuthFinishAuthenticationChallenge *)challenge
{
    ExperimentalCustomAuthenticatiorViewController *experimentalCustomAuthenticatiorViewController = [[ExperimentalCustomAuthenticatiorViewController alloc] init];
    experimentalCustomAuthenticatiorViewController.viewTitle = @"Authentication";
    __weak MobileAuthenticationOperation *weakSelf = self;
    experimentalCustomAuthenticatiorViewController.customAuthAction = ^(NSString *data, BOOL cancelled) {
        [weakSelf.tabBarController dismissViewControllerAnimated:YES completion:nil];
        if (data) {
            [challenge.sender respondWithData:data challenge:challenge];
        } else if (cancelled) {
            [challenge.sender cancelChallenge:challenge underlyingError:nil];
        }
    };
    
    [self performSafeConfirmationPresentation:^{
        [self.tabBarController presentViewController:experimentalCustomAuthenticatiorViewController animated:YES completion:nil];
    }];
}

@end
