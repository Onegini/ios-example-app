//
//  OGLogoutDelegate.h
//  OneginiSDKiOS
//
//  Created by Stanisław Brzeski on 22/09/15.
//  Copyright © 2015 Onegini. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Logout delegate
 */
@protocol OGLogoutDelegate <NSObject>

/**
 *  Logout sucessful callback
 *  Access token removed from device and revoked from token server
 */
-(void)logoutSuccessful;

/**
 *  Logout failure callback
 *  Access token removed from device but not revoked from token server
 *
 *  @param error error encountered during communication with token server
 */
-(void)logoutFailureWithError:(NSError*)error;

@end