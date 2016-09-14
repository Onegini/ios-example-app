//
//  TextViewController.h
//  OneginiExampleApp
//
//  Created by Dima Vorona on 9/14/16.
//  Copyright © 2016 Onegini. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextViewController : UIViewController

@property (nonatomic, copy) NSString *text;

@property (nonatomic) void (^completion)(TextViewController *sender);

@end
