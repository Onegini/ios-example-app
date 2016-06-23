//
//  OGProfile.h
//  OneginiSDKiOS
//
//  Created by Stanisław Brzeski on 23/03/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OGProfile : NSObject <NSCoding>

@property (nonatomic, strong) NSString *profileId;

+(OGProfile*)profileWithId:(NSString*)profileId;

@end