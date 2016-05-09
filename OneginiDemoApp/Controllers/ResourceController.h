//
//  APIClient.h
//  OneginiDemoApp
//
//  Created by Sergey Butenko on 5/5/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OneginiSDK.h"

@class Profile;

@interface ResourceController : NSObject <OGResourceHandlerDelegate>

+ (instancetype)sharedInstance;

- (void)getProfile:(void(^)(Profile *profile, NSError *error))completion;

@end
