//  Copyright © 2017 Onegini. All rights reserved.

#import "AlertPresenter.h"
#import <UIKit/UIKit.h>

@interface AlertPresenter ()

@property (nonatomic) UINavigationController *navigationController;

@end

@implementation AlertPresenter

+ (instancetype)createAlertPresenterWithNavigationController:(UINavigationController *)navigationController
{
    AlertPresenter *alertPresenter = [AlertPresenter new];
    alertPresenter.navigationController = navigationController;
    return alertPresenter;
}

- (void)showErrorAlert:(NSError *)error title:(NSString *)title
{
    NSString *messageWithErrorCode = @"Unknown error";
    if (error) {
       messageWithErrorCode = [NSString stringWithFormat:@"%ld\n%@", error.code, error.localizedDescription];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:messageWithErrorCode
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)showErrorAlertWithMessage:(NSString *)message title:(NSString *)title 
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

@end
