//  Copyright © 2016 Onegini. All rights reserved.

#import <Foundation/Foundation.h>
#import "OneginiSDK.h"

@interface FingerprintController : NSObject<ONGFingerprintDelegate>

+ (instancetype)sharedInstance;
- (BOOL)isFingerprintEnrolled;
- (void)enrollForFingerprintAuthentication;
- (void)disableFingerprintAuthentication;

@end
