//  Copyright © 2016 Onegini. All rights reserved.

#import "AppDelegate.h"
#import "WelcomeViewController.h"
#import "MobileAuthenticationController.h"
#import "AuthenticationOperation.h"

@interface AppDelegate ()

@property (nonatomic) MobileAuthenticationController *mobileAuthenticationController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupWindow];

    [self startOneginiClient];

    [self registerForPushMessages];

    return YES;
}

- (void)setupWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[WelcomeViewController new]];
    navigationController.navigationBarHidden = YES;
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
}

- (void)startOneginiClient
{
    // Before we can use SDK it needs to be build first
    [[ONGClientBuilder new] build];

    // After being build it also needs to be initialized. This includes contacting the Token Server in order to get the latest configuration and performing
    // sanity checks.
    // This step is crucial since it may report critical errors such as: Application is outdated, OS is outdated.
    // In case of such errors the user can not use the app anymore and has to update the app / OS.
    // The SDK in turn won't be able to provide any functionality to prevent user's data leakage / corruption.
    [[ONGClient sharedInstance] start:^(BOOL result, NSError *error) {

        if (error != nil) {
            // Catching two important errors that might happen during SDK initialization.
            // The user can not use this version of the App / OS anymore and has to update it.
            // To provide a nice UX you may want to limit application functionality and not to force the user to update App / OS immediately.
            if (error.code == ONGGenericErrorOutdatedApplication) {
                [self showAlertWithTitle:@"Application disabled" message:@"The application version is no longer valid, please visit the app store to update your application"];
            } else if (error.code == ONGGenericErrorOutdatedOS) {
                [self showAlertWithTitle:@"OS outdated" message:@"The operating system that you use is no longer valid, please update your OS."];
            } else if (error.code == ONGGenericErrorDeviceDeregistered) {
                [self showAlertWithTitle:@"Device deregistered" message:@"Your device has been deregistered on the server side. Please register your account again."];
            } else if (error.code == ONGGenericErrorUserDeregistered) {
                [self showAlertWithTitle:@"User deregistered" message:@"Your account has been deregistered on the server side. Please register again."];
            } else {
                NSLog(@"Error code: %d", error.code);
                // Do nothing. Here we most likely will face with network-related errors that can be ignored. Hence, you can start an app in offline mode and
                // later on connect to the internet when the user wants to login or register for example.
            }
        }
    }];
}

- (void)registerForPushMessages
{
    UIUserNotificationType supportedTypes = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:supportedTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[ONGUserClient sharedInstance] storeDevicePushTokenInSession:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[ONGUserClient sharedInstance] storeDevicePushTokenInSession:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    AuthenticationOperation *operation = [[AuthenticationOperation alloc] initWithNavigationController:(UINavigationController *)self.window.rootViewController
                                                                                          notification:userInfo];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

@end
