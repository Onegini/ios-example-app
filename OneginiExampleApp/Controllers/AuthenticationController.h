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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OneginiSDK.h"
#import "PinViewController.h"

@interface AuthenticationController : NSObject<ONGAuthenticationDelegate>

@property (nonatomic, copy) void (^progressStateDidChange)(BOOL);
@property (nonatomic) PinViewController *pinViewController;

+ (instancetype)authenticationControllerWithNavigationController:(UINavigationController *)navigationController
                                                tabBarController:(UITabBarController *)tabBarController
                                                      completion:(void (^)(void))completion;

@end
