//  Copyright (c) 2016 Onegini. All rights reserved.

#import <Foundation/Foundation.h>
#import "OGResourceHandlerDelegate.h"
#import "OGEnrollmentHandlerDelegate.h"
#import "OGPinValidationDelegate.h"
#import "OGChangePinDelegate.h"
#import "OGPublicCommons.h"
#import "OGDisconnectDelegate.h"
#import "OGDeregistrationDelegate.h"
#import "OGFingerprintDelegate.h"
#import "OGLogoutDelegate.h"
#import "OGCustomizationDelegate.h"
#import "OGAuthenticationDelegate.h"
#import "OGClientAuthenticationDelegate.h"
#import "OGUserProfile.h"
#import "OGMobileAuthenticationDelegate.h"
#import "OGConfigModel.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedPropertyInspection"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This is the main entry point into the SDK.
 *  The public API of the SDK consists of this client and an authorization delegate.
 *  The client must be instantiated early in the App lifecycle and thereafter only referred to by it's shared instance.
 */
@interface OGOneginiClient : NSObject

/**
 *  Registers delegate handling customizable properties within the SDK.
 */
@property (weak, nonatomic, nullable) id<OGCustomizationDelegate> customizationDelegate;

/**
* Access to the initialized and configured instance of the `OGOneginiClient`. Before calling this method You have to initialize
* SDK by calling `-[ONGClientBuilder build]`.
*
* @return instance of the configured `OGOneginiClient`.
*
* @see `ONGClientBuilder`, `-[ONGClient userClient]`
*
* @warning If the SDK is not initialized via `-[ONGClientBuilder build]` this method throws an exception.
*/
+ (OGOneginiClient *)sharedInstance;

/**
 * Developers should not try to instantiate SDK on their own. The only valid way to get `OGOneginiClient` instance is by
 * calling `-[OGOneginiClient sharedInstance]`.
 *
 * @see -sharedInstance
 */
- (instancetype)init ONG_UNAVAILABLE;
+ (instancetype)new ONG_UNAVAILABLE;

/**
 *  Main entry point into the authentication process.
 *
 *  @param profile profile to authenticate
 *  @param delegate authentication delegate
 */
- (void)authenticateUser:(OGUserProfile *)profile delegate:(id<OGAuthenticationDelegate>)delegate;

/**
 *  Main entry point into the enrollment process.
 *
 *  @param scopes array of scopes
 *  @param delegate authentication delegate
 */
- (void)registerUser:(nullable NSArray<NSString *> *)scopes delegate:(id<OGAuthenticationDelegate>)delegate;

/**
 *  Forces profiles's reauthorization.
 *
 *  @param profile profile to authenticate
 *  @param delegate authentication delegate
 */
- (void)reauthenticateUser:(OGUserProfile *)profile delegate:(id<OGAuthenticationDelegate>)delegate;

/**
 *  Performs client's authentication. Uses client's credentials to request an accessToken object, which can be used for performing anonymous resource calls.
 *
 *  @param scopes array of scopes
 *  @param delegate authentication delegate
 */
- (void)authenticateClient:(nullable NSArray<NSString *> *)scopes delegate:(id<OGClientAuthenticationDelegate>)delegate;

/**
 *  Initiates the PIN change sequence.
 *  If no refresh token is registered then the sequence is cancelled.
 *  This will invoke a call to the OGAuthorizationDelegate - (void)askForPinChange:(NSUInteger)pinSize;
 *
 *  @param delegate Object handling change pin callbacks
 */
- (void)changePinRequest:(id<OGChangePinDelegate>)delegate;

/**
 *  Determines if the user is authorized.
 *
 *  @return true, if a valid access token is available
 */
- (BOOL)isAuthorized;

/**
 *  Return currently authenticated user.
 *
 *  @return authenticated user
 */
- (nullable OGUserProfile *)authenticatedUserProfile;

/**
 *  Checks if the pin satisfies all pin policy constraints.
 *
 *  @param pin pincode to validate against pin policy constraints
 *  @param error pin policy validation error
 *  @return true if all pin policy constraints are satisfied
 */
- (BOOL)isPinValid:(NSString *)pin error:(NSError *_Nullable *_Nullable)error;

/**
 *  Handles the response of the authentication request from the browser redirect.
 *  The URL scheme and host must match the config model redirect URL.
 *
 *  @param url callback url
 */
- (void)handleAuthenticationCallback:(NSURL *)url;

/**
 *  Performs a user logout, by invalidating the access token.
 *  The refresh token and client credentials remain untouched.
 *
 *  @param delegate logout delegate
 */
- (void)logoutUserWithDelegate:(id<OGLogoutDelegate>)delegate;

/**
 *  Clears the client credentials.
 *  A new dynamic client registration has to be performed on the next authorization request.
 */
- (void)clearCredentials;

/**
 *  Clears all tokens and reset the pin attempt count.
 *
 *  @param error not nil when deleting the refresh token from the keychain fails.
 *  @return true, if the token deletion is successful.
 */
- (BOOL)clearTokens:(NSError **)error;

/**
 *  Stores the device token for the current session.
 *
 *  This should be invoked from the UIApplicationDelegate
 *  - (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
 *
 *  @param deviceToken device token to store
 */
- (void)storeDevicePushTokenInSession:(nullable NSData *)deviceToken;

/**
 *  Enrolls the currently authenticated user for fingerprint authentication. The OGFingerprintDelegate
 *  askCurrentPinForFingerprintAuthentication method must be implemented. The PIN provided by the user must be passed to
 *  the confirmCurrentPinForFingerprintAuthorization method to complete the flow.
 *
 *  Fingerprint authentication must be available for current user and device.
 *  @see -(bool)isFingerprintAuthenticationAvailable
 *
 *  @param delegate delegate handling fingerprint enrollment callbacks
 */
- (void)enrollForFingerprintAuthenticationWithDelegate:(id<OGFingerprintDelegate>)delegate;

/**
 *  Disables fingerprint authentication for the currently authenticated user.
 */
- (void)disableFingerprintAuthentication;

/**
 *  Determines if device is enrolled for fingerprint authentication.
 *
 *  @param delegate
 */
- (BOOL)isEnrolledForFingerprintAuthentication;

/**
 *  Determines if fingerprint authentication is possible by checking if device possess Touch ID sensor, at least one fingerprint is registered and if fingerprint is enabled for client configuration provided by token server. Device cannot be jailbroken and have to be running iOS 9 or greater.
 */
- (BOOL)isFingerprintAuthenticationAvailable;

/**
 *  Fetches a user specific resource.
 *
 *  @param path part of URL appended to base URL provided in Onegini client configuration.
 *  @param requestMethod HTTP request method, can be one of @"GET", @"POST", @"PUT" and @"DELETE".
 *  @param params additional request parameters. Parameters are appended to URL or provided within a body depending on the request method.
 *  @param paramsEncoding encoding used for params, possible values are OGJSONParameterEncoding, OGFormURLParameterEncoding or OGPropertyListParameterEncoding
 *  @param headers additional headers added to HTTP request. Onegini SDK takes responsibility of managing `Authorization`and `User-Agent` headers.
 *  @param delegate object responsible for handling resource callbacks. Onegini client invokes the delegate callback with the response payload.
 *  @return requestId unique request ID.
 */
- (NSString *)fetchResource:(NSString *)path
              requestMethod:(NSString *)requestMethod
                     params:(nullable NSDictionary<NSString *, NSString *> *)params
             paramsEncoding:(OGHTTPClientParameterEncoding)paramsEncoding
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                   delegate:(id<OGResourceHandlerDelegate>)delegate;

/**
 *  Enrolls the currently connected device for mobile push authentication.
 *
 *  The device push token must be stored in the session before invoking this method.
 *  @see storeDevicePushTokenInSession:
 *
 *  @param delegate delegate handling mobile enrollment callbacks
 */
- (void)enrollUserForMobileAuthenticationWithDelegate:(id<OGEnrollmentHandlerDelegate>)delegate;

/**
 *  Fetches a resource anonymously using a client access token.
 *
 *  @param path part of URL appended to base URL provided in Onegini client configuration.
 *  @param requestMethod HTTP request method, can be one of @"GET", @"POST", @"PUT" and @"DELETE".
 *  @param params additional request parameters. Parameters are appended to URL or provided within a body depending on the request method.
 *  @param paramsEncoding encoding used for params, possible values are OGJSONParameterEncoding, OGFormURLParameterEncoding or OGPropertyListParameterEncoding
 *  @param headers additional headers added to HTTP request. Onegini SDK takes responsibility of managing `Authorization`and `User-Agent` headers.
 *  @param delegate object responsible for handling resource callbacks. Onegini client invokes the delegate callback with the response payload.
 *  @return requestId unique request ID.
 */
- (NSString *)fetchAnonymousResource:(NSString *)path
                       requestMethod:(NSString *)requestMethod
                              params:(nullable NSDictionary<NSString *, NSString *> *)params
                      paramsEncoding:(OGHTTPClientParameterEncoding)paramsEncoding
                             headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                            delegate:(id<OGResourceHandlerDelegate>)delegate;

/**
 *  When a push notification is received by the application, the notificaton must be forwarded to the client.
 *  The client will then fetch the actual encrypted payload and invoke the delegate with the embedded message.
 *
 *  This should be invoked from the UIApplicationDelegate
 *  - (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
 *
 *  @see UIApplication
 *
 *  @param userInfo userInfo of received push notification
 *  @param delegate delegate responsinble for handling push messages
 *  @return true, if the notification is processed by the client
 */
- (BOOL)handlePushNotification:(NSDictionary *)userInfo delegate:(id<OGMobileAuthenticationDelegate>)delegate;

/**
 *  List of enrolled users stored locally
 *
 *  @return Enrolled users
 */
- (NSSet<OGUserProfile *> *)userProfiles;

/**
 *  Delete user locally and revoke it from token server
 *
 *  @param userProfile user to disconnect
 *  @param delegate delegate
 */
- (void)deregisterUser:(OGUserProfile *)userProfile delegate:(id<OGDeregistrationDelegate>)delegate;

/**
 * Returns a string with access token for the currently authenticated user, or nil if no user is currently
 * authenticated.
 *
 * <strong>Warning</strong>: Do not use this method if you want to fetch resources from your resource gateway: use the resource methods
 * instead.
 *
 * @return String with access token or nil
 */
- (nullable NSString *)accessToken;

@end

NS_ASSUME_NONNULL_END

#pragma clang diagnostic pop
#pragma clang diagnostic pop