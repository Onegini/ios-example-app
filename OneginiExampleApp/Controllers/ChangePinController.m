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

#import "ChangePinController.h"
#import "PinViewController.h"

@interface ChangePinController ()

@property (nonatomic) PinViewController *pinViewController;
@property (nonatomic) UINavigationController *navigationController;
@property (nonatomic) void (^completion)();

@end

@implementation ChangePinController

+ (instancetype)changePinControllerWithNavigationController:(UINavigationController *)navigationController
                                                 completion:(void (^)())completion
{
    ChangePinController *changePinController = [ChangePinController new];
    changePinController.navigationController = navigationController;
    changePinController.pinViewController = [PinViewController new];
    changePinController.completion = completion;
    return changePinController;
}

- (void)userClient:(ONGUserClient *)userClient didReceivePinChallenge:(ONGPinChallenge *)challenge
{
    [self.pinViewController reset];
    self.pinViewController.mode = PINCheckMode;
    self.pinViewController.profile = challenge.userProfile;
    self.pinViewController.pinLength = 5;
    self.pinViewController.pinEntered = ^(NSString *pin) {
        [challenge.sender respondWithPin:pin challenge:challenge];
    };
    if ([self.navigationController.topViewController isKindOfClass:PinViewController.class]) {
        [self.pinViewController showError:[NSString stringWithFormat:@"Invalid pin. You have still %@ attempts left.", @(challenge.remainingFailureCount)]];
    } else {
        [self.navigationController pushViewController:self.pinViewController animated:YES];
    }
}

- (void)userClient:(ONGUserClient *)userClient didReceiveCreatePinChallenge:(ONGCreatePinChallenge *)challenge
{
    [self.pinViewController reset];
    self.pinViewController.mode = PINRegistrationMode;
    self.pinViewController.pinEntered = ^(NSString *pin) {
        [challenge.sender respondWithCreatedPin:pin challenge:challenge];
    };
    if (challenge.error) {
        [self.pinViewController showError:challenge.error.localizedDescription];
    }
}

- (void)userClient:(ONGUserClient *)userClient didChangePinForUser:(ONGUserProfile *)userProfile
{
    [self.navigationController popViewControllerAnimated:YES];
    self.completion();
}

- (void)userClient:(ONGUserClient *)userClient didFailToChangePinForUser:(ONGUserProfile *)userProfile error:(NSError *)error
{
    [self pinChangeError:error];
    self.completion();
}

- (void)pinChangeError:(NSError *)error
{
    [self.navigationController popViewControllerAnimated:YES];
    [self showError:error];
}

- (void)showError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change pin error"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

@end
