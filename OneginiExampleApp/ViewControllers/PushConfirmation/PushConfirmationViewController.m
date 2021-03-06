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

#import "PushConfirmationViewController.h"
#import "UIBarButtonItem+Extension.h"

@interface PushConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UIButton *pushConfirmButton;
@property (weak, nonatomic) IBOutlet UIButton *pushDenyButton;

@end

@implementation PushConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem keyImageBarButtonItem];
}

- (IBAction)confirmPush:(id)sender
{
    self.pushConfirmed(YES);
}

- (IBAction)denyPush:(id)sender
{
    self.pushConfirmed(NO);
}

@end
