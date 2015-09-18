//
//  OneginiCordovaClient.m
//  OneginiCordovaPlugin
//
//  Created by Eduard on 13-01-15.
//
//

#import "OneginiCordovaClient.h"
#import <Cordova/NSDictionary+Extensions.h>
#import "Reachability.h"
#import "XMLReader.h"

NSString* const kReason				= @"reason";
NSString* const kRemainingAttempts	= @"remainingAttempts";
NSString* const kMethod				= @"method";
NSString* const kMaxSimilarDigits	= @"maxSimilarDigits";
NSString* const certificate         = @"MIIE5TCCA82gAwIBAgIQB28SRoFFnCjVSNaXxA4AGzANBgkqhkiG9w0BAQUFADBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290MB4XDTEyMDIxNjAwMDAwMFoXDTIwMDUzMDEwNDgzOFowczELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxGTAXBgNVBAMTEFBvc2l0aXZlU1NMIENBIDIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDo6jnjIqaqucQA0OeqZztDB71Pkuu8vgGjQK3g70QotdA6voBUF4V6a4RsNjbloyTi/igBkLzX3Q+5K05IdwVpr95XMLHo+xoD9jxbUx6hAUlocnPWMytDqTcyUg+uJ1YxMGCtyb1zLDnukNh1sCUhYHsqfwL9goUfdE+SNHNcHQCgsMDqmOK+ARRYFygiinddUCXNmmym5QzlqyjDsiCJ8AckHpXCLsDl6ez2PRIHSD3SwyNWQezT3zVLyOf2hgVSEEOajBd8i6q8eODwRTusgFX+KJPhChFo9FJXb/5IC1tdGmpnc5mCtJ5DYD7HWyoSbhruyzmuwzWdqLxdsC/DAgMBAAGjggF3MIIBczAfBgNVHSMEGDAWgBStvZh6NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUmeRAX2sUXj4F2d3TY1T8Yrj3AKwwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEQYDVR0gBAowCDAGBgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDCBswYIKwYBBQUHAQEEgaYwgaMwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LnA3YzA5BggrBgEFBQcwAoYtaHR0cDovL2NydC51c2VydHJ1c3QuY29tL0FkZFRydXN0VVROU0dDQ0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBBQUAA4IBAQCcNuNOrvGKu2yXjI9LZ9Cf2ISqnyFfNaFbxCtjDei8d12nxDf9Sy2e6B1pocCEzNFti/OBy59LdLBJKjHoN0DrH9mXoxoR1Sanbg+61b4s/bSRZNy+OxlQDXqV8wQTqbtHD4tc0azCe3chUN1bq+70ptjUSlNrTa24yOfmUlhNQ0zCoiNPDsAgOa/fT0JbHtMJ9BgJWSrZ6EoYvzL7+i1ki4fKWyvouAt+vhcSxwOCKa9Yr4WEXT0K3yNRw82vEL+AaXeRCk/luuGtm87fM04wO+mPZn+C+mv626PAcwDj1hKvTfIPWhRRH224hoFiB85ccsJP81cqcdnUl4XmGFO3";

@interface MainViewController()

@property (nonatomic, readwrite, strong) NSArray* supportedOrientations;

@end

@interface OneginiCordovaClient()

@property (nonatomic) bool initializationSuccessful;
@property (nonatomic) NSUInteger supportedOrientations;

@end

@implementation OneginiCordovaClient {
    /**
     Identifies the current state of the PIN entry process.
     */
    PINEntryModes pinEntryMode;

    /**
     This indicates if the native PIN entry view should be used.
     The value is set in the top level application config.xml
     */
    BOOL useNativePinView;

    /** Temporary storage of the first PIN for verification with the second entry */
#warning TODO apply memory protection
    NSString *verifyPin;

    NSDictionary* messages;
}

@synthesize oneginiClient, pluginInitializedCommandTxId, authorizeCommandTxId, configModel;
@synthesize fetchResourceCommandTxId, pinDialogCommandTxId, pinValidateCommandTxId, pinChangeCommandTxId;

#pragma mark -
#pragma mark overrides

- (void)dealloc {
    verifyPin = nil;
}

- (void)pluginInitialize {
#ifdef DEBUG
    NSLog(@"pluginInitialize");
    [CDVPluginResult setVerbose:YES];
#endif
    pinEntryMode = PINEntryModeUnknown;

    if ([self prepareConfiguration]) {
        self.oneginiClient = [[OGOneginiClient alloc] initWithConfig:configModel delegate:self];

        [oneginiClient setX509PEMCertificates:@[certificate]];

        if (self.configModel && self.oneginiClient)
            self.initializationSuccessful = YES;

        [self loadMessagesFromFile:@"messages.properties"];
    }
}

-(BOOL)prepareConfiguration {
    NSString *configContent = [self loadConfigurationFile];
    NSDictionary *configuration = [XMLReader dictionaryForXMLString:configContent];
    NSDictionary *widget = [configuration objectForKey:@"widget"];
    if (widget == nil) {
        return NO;
    }
    NSArray *preferences = [widget objectForKey:@"preference"];
    if (preferences == nil) {
        return NO;
    }

    NSMutableDictionary *preferencesDict = [NSMutableDictionary new];
    for (id pref in preferences) {
        if ([[pref valueForKey:@"name"] hasPrefix:@"kOG"]) {
            NSString *key = [NSString stringWithUTF8String: [[pref valueForKey:@"name"] UTF8String]];
            NSString *value = [NSString stringWithUTF8String:[[pref valueForKey:@"value"] UTF8String]];
            [preferencesDict setValue:value forKey:key];
        }
    }

    [preferencesDict setValue: @"ios" forKey: kOGAppPlatform];
    self.configModel = [[OGConfigModel alloc] initWithDictionary:preferencesDict];
    return YES;
}


- (NSString *)loadFileToString:(NSString*)path {
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil] encoding:kCFStringEncodingUTF8 error:&error];

    if (error) {
        NSLog(@"Error reading %@ file", path);
        return @"";
    }
    return fileContent;
}

-(NSString *)loadConfigurationFile {
    NSString * configPath = @"config.xml";
    return [self loadFileToString:configPath];
}

-(void)loadMessagesFromFile:(NSString*)fileName
{
    NSString *properties = [self loadFileToString:fileName];

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{.*\\}" options:NSRegularExpressionCaseInsensitive error:&error];

    properties = [regex stringByReplacingMatchesInString:properties options:0 range:NSMakeRange(0, [properties length]) withTemplate:@"%@"];
    NSMutableArray *lines = [[properties componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] mutableCopy];

    NSMutableDictionary* mutablemessages = [NSMutableDictionary dictionary];

    for (NSString* line in lines) {
        if ([line rangeOfString:@"="].location==NSNotFound)//  ![line containsString:@"="])
            continue;
        NSArray* keyValue = [line componentsSeparatedByString:@"="];
        if (keyValue.count==2)
            [mutablemessages setObject:keyValue[1] forKey:keyValue[0]];
        else if (keyValue.count==1)
            [mutablemessages setObject:@"" forKey:keyValue[0]];
        else
            NSLog(@"Error reading messages.properties file");
    }
    messages = mutablemessages;
}

- (void)handleOpenURL:(NSNotification *)notification {
    [super handleOpenURL:notification];

    [[OGOneginiClient sharedInstance] handleAuthorizationCallback:notification.object];
}

- (void)onAppTerminate {
    [oneginiClient logout:nil];
}

#pragma mark -
- (void)resetAll {
    self.pluginInitializedCommandTxId = nil;
    self.authorizeCommandTxId = nil;
    self.fetchResourceCommandTxId = nil;
    self.pinValidateCommandTxId = nil;
    self.pinChangeCommandTxId = nil;
}

- (void)authorizationErrorCallbackWIthReason:(NSString *)reason {
    [self authorizationErrorCallbackWIthReason:reason error:nil];
}

- (void)authorizationErrorCallbackWIthReason:(NSString *)reason error:(NSError *)error {
	if (authorizeCommandTxId == nil) {
		return;
	}

	NSDictionary *d = @{ kReason:reason };

	CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:d];
	[self.commandDelegate sendPluginResult:result callbackId:authorizeCommandTxId];
    [self resetAll];
}

#pragma mark -
#pragma mark Cordova entry points
- (void)clearTokens:(CDVInvokedUrlCommand *)command {
    NSError *error;
    if (![[OGOneginiClient sharedInstance] clearTokens:&error]) {
#ifdef DEBUG
        NSLog("clearTokens error %@", error);
#endif
    }
}

- (void)clearCredentials:(CDVInvokedUrlCommand *)command {
    [[OGOneginiClient sharedInstance] clearCredentials];
}

- (void)awaitPluginInitialization:(CDVInvokedUrlCommand *)command {
    self.pluginInitializedCommandTxId = command.callbackId;
    if (![self isConnected]){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{kReason:@"connectivityProblem"}];
        [self.commandDelegate sendPluginResult:result callbackId:self.pluginInitializedCommandTxId];
    }
}

- (void)initPinCallbackSession:(CDVInvokedUrlCommand *)command {
	self.pinDialogCommandTxId = command.callbackId;

	CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	pluginResult.keepCallback = @(1);
	[self.commandDelegate sendPluginResult:pluginResult callbackId:pinDialogCommandTxId];

    if (self.pluginInitializedCommandTxId)
    {
        if(self.initializationSuccessful)
            [self sendSuccessCallback:pluginInitializedCommandTxId];
        else
            [self sendErrorCallback:pluginInitializedCommandTxId];
    }
}

- (void)inAppBrowserControlSession:(CDVInvokedUrlCommand *)command
{
    self.inAppBrowserCommandTxId = command.callbackId;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    pluginResult.keepCallback = @(1);
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.inAppBrowserCommandTxId];

    if (self.pluginInitializedCommandTxId)
    {
        if(self.initializationSuccessful)
            [self sendSuccessCallback:self.inAppBrowserCommandTxId];
        else
            [self sendErrorCallback:self.inAppBrowserCommandTxId];
    }
}

- (void)isRegistered:(CDVInvokedUrlCommand *)command
{
    if (oneginiClient.isClientRegistered)
        [self sendSuccessCallback:command.callbackId];
    else
        [self sendErrorCallback:command.callbackId];
}

- (bool)isConnected
{
    Reachability* currentReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [currentReachability currentReachabilityStatus];

    if (networkStatus == ReachableViaWiFi||networkStatus == ReachableViaWWAN)
        return YES;
    else
        return NO;
}

- (void)authorize:(CDVInvokedUrlCommand *)command {
	[self resetAll];

	self.authorizeCommandTxId = command.callbackId;

    if ([self isConnected])
        [oneginiClient authorize:command.arguments];
    else
        [self authorizationErrorCallbackWIthReason:@"connectivityProblem"];
}

- (void)isAuthorized:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[oneginiClient isAuthorized]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)confirmNewPin:(CDVInvokedUrlCommand *)command {
    self.pinValidateCommandTxId = nil;
    self.pinChangeCommandTxId = nil;
	if (command.arguments.count != 1) {
		CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 1 argument but received %lu", (unsigned long)command.arguments.count]];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
		return;
	}

	NSString *pin = command.arguments.firstObject;

	[oneginiClient confirmNewPin:pin validation:self];
}

- (void)confirmCurrentPin:(CDVInvokedUrlCommand *)command {
    if (![self isConnected]){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{kReason:@"connectivityProblem"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }

    if (command.arguments.count != 1) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 1 argument but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *pin = command.arguments.firstObject;

    [oneginiClient confirmCurrentPin:pin];
    [self sendSuccessCallback:command.callbackId];
}

- (void)changePin:(CDVInvokedUrlCommand *)command {
    if (![self isConnected]){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{kReason:@"connectivityProblem"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    self.pinChangeCommandTxId = command.callbackId;
    self.pinValidateCommandTxId = nil;

    [oneginiClient changePinRequest:self];
}

- (void)cancelPinChange:(CDVInvokedUrlCommand *)command {
    self.pinChangeCommandTxId = nil;
    self.pinValidateCommandTxId = nil;
    // TODO add cancel PIN change method to public API of OGOneginiClient in order to invalidate the state.
}

- (void)confirmCurrentPinForChangeRequest:(CDVInvokedUrlCommand *)command {
    self.pinValidateCommandTxId = nil;

    if (command.arguments.count != 1) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 1 argument but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *pin = command.arguments.firstObject;
    [oneginiClient confirmCurrentPinForChangeRequest:pin];
}

- (void)confirmNewPinForChangeRequest:(CDVInvokedUrlCommand *)command {
    self.pinValidateCommandTxId = nil;

    if (command.arguments.count != 1) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 1 argument but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    // Register the transaction id for validation callbacks.
    self.pinValidateCommandTxId = command.callbackId;
    NSString *pin = command.arguments.firstObject;

    [oneginiClient confirmNewPinForChangeRequest:pin validation:self];
}

- (void)validatePin:(CDVInvokedUrlCommand *)command {
    if (command.arguments.count != 1) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 1 argument but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *pin = command.arguments.firstObject;
    NSError *error;
    BOOL result = [oneginiClient isPinValid:pin error:&error];

    CDVPluginResult *pluginResult;
    if (result) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    if (![error.domain isEqualToString:@"com.onegini.PinValidation"]) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    self.pinValidateCommandTxId = command.callbackId;
    // TODO move error codes into OGPublicCommons public API
    switch (error.code) {
        case 0: {
            [self pinShouldNotBeASequence];
            break;
        }
        case 1: {
            NSNumber *n = error.userInfo[@"kMaxSimilarDigits"];
            [self pinShouldNotUseSimilarDigits:n.integerValue];
            break;
        }
        case 2: {
            [self pinTooShort];
            break;
        }
        case 3: {
            [self pinBlackListed];
            break;
        }
        default: {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
}

- (void)fetchResource:(CDVInvokedUrlCommand *)command {
    if (![self isConnected]){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{kReason:@"connectivityProblem"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    if (command.arguments.count != 5) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 5 arguments but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *path = [command.arguments objectAtIndex:0];
    NSArray *scopes = [command.arguments objectAtIndex:1];
    NSString *requestMethodString = [command.arguments objectAtIndex:2];
    NSString *paramsEncodingString = [command.arguments objectAtIndex:3];
    NSDictionary *params = [command.arguments objectAtIndex:4];

    HTTPRequestMethod requestMethod = [self requestMethodForString:requestMethodString];
    HTTPClientParameterEncoding parameterEncoding = [self parameterEncodingForString:paramsEncodingString];

    self.fetchResourceCommandTxId = command.callbackId;

    [oneginiClient fetchResource:path scopes:scopes requestMethod:requestMethod params:params paramsEncoding:parameterEncoding delegate:self];
}

- (void)fetchAnonymousResource:(CDVInvokedUrlCommand *)command {
    if (![self isConnected]){
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{kReason:@"connectivityProblem"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    if (command.arguments.count != 5) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"expected 5 arguments but received %lu", (unsigned long)command.arguments.count]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *path = [command.arguments objectAtIndex:0];
    NSArray *scopes = [command.arguments objectAtIndex:1];
    NSString *requestMethodString = [command.arguments objectAtIndex:2];
    NSString *paramsEncodingString = [command.arguments objectAtIndex:3];
    NSDictionary *params = [command.arguments objectAtIndex:4];

    HTTPRequestMethod requestMethod = [self requestMethodForString:requestMethodString];
    HTTPClientParameterEncoding parameterEncoding = [self parameterEncodingForString:paramsEncodingString];

    self.fetchResourceCommandTxId = command.callbackId;

    [oneginiClient fetchAnonymousResource:path scopes:scopes requestMethod:requestMethod params:params paramsEncoding:parameterEncoding delegate:self];
}

- (void)logout:(CDVInvokedUrlCommand *)command {
    @try {
        [self.oneginiClient logout:nil];
    }
    @finally {
        [self sendSuccessCallback:command.callbackId];
        [self resetAll];
    }
}

- (void)disconnect:(CDVInvokedUrlCommand *)command {
    self.disconnectCommandTxId = command.callbackId;
    [self.oneginiClient disconnectWithDelegate:self];
}

- (void)sendSuccessCallback:(NSString *)callbackId {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)sendErrorCallback:(NSString *)callbackId {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

#pragma mark -
#pragma mark OGAuthorizationDelegate

- (void)requestAuthorization:(NSURL *)url {
    if (configModel.useEmbeddedWebView) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{ kMethod:@"requestAuthorization", @"url":url.absoluteString}];
        result.keepCallback = @(1);

        [self.commandDelegate sendPluginResult:result callbackId:authorizeCommandTxId];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)authorizationSuccess {
    if (authorizeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"authorizationSuccess");
#endif
        [self resetAll];
        return;
    }

    [self closePinView];
    pinEntryMode = PINEntryModeUnknown;

    @try {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"authorizationSuccess"];
        result.keepCallback = @(0);
        [self.commandDelegate sendPluginResult:result callbackId:authorizeCommandTxId];
    }
    @finally {
        [self resetAll];
    }
}

- (void)authorizationError {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"connectivityProblem"];
}

- (void)authorizationErrorClientRegistrationFailed:(NSError *)error {
    [self authorizationErrorCallbackWIthReason:@"authorizationErrorClientRegistrationFailed" error:error];
}

- (void)askForCurrentPin {
    if (pinDialogCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"askForCurrentPin: pinCommandTxId is nil");
#endif
        return;
    }

    if (useNativePinView) {
        pinEntryMode = PINCheckMode;
        [self showPinEntryViewInMode:PINCheckMode];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{ kMethod:@"askForCurrentPin"}];
        result.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:result callbackId:pinDialogCommandTxId];
    }
}

- (void)askForNewPin:(NSUInteger)pinSize {
    if (pinDialogCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"askForNewPin: pinCommandTxId is nil");
#endif
        return;
    }

    if (useNativePinView) {
        pinEntryMode = PINRegistrationMode;
        [self showPinEntryViewInMode:PINRegistrationMode];

    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{ kMethod:@"askForNewPin" }];
        result.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:result callbackId:pinDialogCommandTxId];
    }
}

- (void)askNewPinForChangeRequest:(NSUInteger)pinSize {
    if (pinDialogCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"askNewPinForChangeRequest: pinCommandTxId is nil");
#endif
        return;
    }
    if (useNativePinView) {
        pinEntryMode = PINChangeNewPinMode;
        [self.pinViewController reset];
        self.pinViewController.mode = pinEntryMode;
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{ kMethod:@"askNewPinForChangeRequest" }];
        result.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:result callbackId:pinDialogCommandTxId];
    }
}

- (void)askCurrentPinForChangeRequest {
    if (pinDialogCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"askCurrentPinForChangeRequest: pinCommandTxId is nil");
#endif
        return;
    }
    if (useNativePinView) {
        pinEntryMode = PINChangeCheckMode;
        [self showPinEntryViewInMode:PINChangeCheckMode];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{ kMethod:@"askCurrentPinForChangeRequest" }];
        result.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:result callbackId:pinDialogCommandTxId];
    }
}

- (void)authorizationErrorInvalidGrant:(NSUInteger)remaining {
    if (authorizeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"authorizationErrorInvalidGrant: remaining attempts %d", remaining);
#endif
        return;
    }

    if (self.pinViewController == nil) {
        @try {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"authorizationErrorInvalidGrant", kRemainingAttempts:@(remaining)}];
            result.keepCallback = @(0);
            [self.commandDelegate sendPluginResult:result callbackId:authorizeCommandTxId];
        }
        @finally {
            [self resetAll];
        }
    } else {
        [self.pinViewController invalidPinWithReason:[NSString stringWithFormat:[messages objectForKey:@"AUTHORIZATION_ERROR_PIN_INVALID"],@(remaining)]];
    }
}

- (void)authorizationErrorTooManyPinFailures {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorTooManyPinFailures"];
}

- (void)authorizationErrorNotAuthenticated {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorNotAuthenticated"];
}

- (void)authorizationErrorInvalidScope {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorInvalidScope"];
}

- (void)authorizationErrorInvalidState {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorInvalidState"];
}

- (void)authorizationErrorNoAccessToken {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorNoAccessToken"];
}

- (void)authorizationErrorNotAuthorized {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorNotAuthorized"];
}

- (void)authorizationErrorInvalidRequest {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorInvalidRequest"];
}

- (void)authorizationErrorInvalidGrantType {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorInvalidGrantType"];
}

- (void)authorizationErrorNoAuthorizationGrant {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"authorizationErrorNoAuthorizationGrant"];
}

-(void)authorizationErrorInvalidAppPlatformOrVersion
{
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"unsupportedAppVersion"];
}

- (void)askForPushAuthenticationConfirmation:(NSString *)message notificationType:(NSString *)notificationType confirm:(PushAuthenticationConfirmation)confirm {
    // Not implemented, should be made optional in the SDK
}

- (void)askForPushAuthenticationWithPinConfirmation:(NSString *)message notificationType:(NSString *)notificationType
                                            pinSize:(NSUInteger)pinSize	maxAttempts:(NSUInteger)maxAttempts retryAttempt:(NSUInteger)retryAttempt
                                            confirm:(PushAuthenticationWithPinConfirmation)confirm {
    // Not implemented, should be made optional in the SDK
}

// @optional
- (void)authorizationError:(NSError *)error {
    [self closePinView];

    [self authorizationErrorCallbackWIthReason:@"connectivityProblem"];
}

#pragma mark - OGDisconnectDelegate

-(void)disconnectSuccessful{
    [self sendSuccessCallback:self.disconnectCommandTxId];
    [self resetAll];
}

-(void)disconnectFailureWithError:(NSError *)error{
    [self sendSuccessCallback:self.disconnectCommandTxId];
    [self resetAll];
}

#pragma mark -
#pragma mark OGResourceHandlerDelegate

- (void)resourceSuccess:(id)response {
    CDVPluginResult *result;

    [self closePinView];

    if ([response isKindOfClass:[NSData class]]) {
        NSData *data = response;
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:response];
    }

    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];

}

- (void)resourceError {

    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"resourceCallError" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

- (void)resourceBadRequest {
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"resourceBadRequest" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

- (void)scopeError {
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"scopeError" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

- (void)unauthorizedClient {
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"unauthorizedClient" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

- (void)resourceErrorAuthenticationFailed {
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"resourceErrorAuthenticationFailed" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

-(void)invalidGrantType
{
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"invalidGrant" }];
    [self.commandDelegate sendPluginResult:result callbackId:fetchResourceCommandTxId];
}

#pragma mark -
#pragma mark OGPinValidationHandler

/*
 PIN validation errors should not reset the transaction cause these errors allow for re entering the PIN
 */

#warning TODO use correct validation messages
- (void)pinBlackListed {
    if (self.pinViewController != nil) {
        [self retryPinEntryAfterValidationFailure];
        [self.pinViewController invalidPinWithReason:[messages objectForKey:@"PIN_BLACK_LISTED"]];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsDictionary:@{ kReason:@"pinBlackListed" }];

        [self.commandDelegate sendPluginResult:result callbackId:pinValidateCommandTxId];
    }
}

- (void)pinShouldNotBeASequence {
    if (self.pinViewController != nil) {
        [self retryPinEntryAfterValidationFailure];
        [self.pinViewController invalidPinWithReason:[messages objectForKey:@"PIN_SHOULD_NOT_BE_A_SEQUENCE"]];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsDictionary:@{ kReason:@"pinShouldNotBeASequence" }];
        [self.commandDelegate sendPluginResult:result callbackId:pinValidateCommandTxId];
    }
}

- (void)pinShouldNotUseSimilarDigits:(NSUInteger)count {
    if (self.pinViewController != nil) {
        [self retryPinEntryAfterValidationFailure];
        [self.pinViewController invalidPinWithReason:[NSString stringWithFormat:[messages objectForKey:@"PIN_SHOULD_NOT_USE_SIMILAR_DIGITS"], @(count)]];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsDictionary:@{ kReason:@"pinShouldNotUseSimilarDigits", kMaxSimilarDigits:@(count) }];
        [self.commandDelegate sendPluginResult:result callbackId:pinValidateCommandTxId];
    }
}

- (void)pinTooShort {
    if (self.pinViewController != nil) {
        [self retryPinEntryAfterValidationFailure];
        [self.pinViewController invalidPinWithReason:[messages objectForKey:@"PIN_TOO_SHORT"]];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsDictionary:@{ kReason:@"pinTooShort" }];
        [self.commandDelegate sendPluginResult:result callbackId:pinValidateCommandTxId];
    }
}

// @optional
- (void)pinEntryError:(NSError *)error {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                            messageAsDictionary:@{ kReason:@"pinEntryError"}];
    [self.commandDelegate sendPluginResult:result callbackId:pinValidateCommandTxId];
}

#pragma mark -
#pragma mark OGChangePinDelegate

- (void)pinChangeError:(NSError *)error {
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"pinChangeError: pinCommandTxId is nil, invocation is out of context");
#endif
        return;
    }
    if (self.pinViewController){
        [self closePinView];
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"connectivityProblem"} ];
    [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
    pinChangeCommandTxId = nil;
}

- (void)invalidCurrentPin {
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"invalidCurrentPin: pinCommandTxId is nil");
#endif
        return;
    }
    if (self.pinViewController){
        [self.pinViewController invalidPinWithReason:@"Invalid pin"];
    }
    else{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"invalidCurrentPin"} ];
        [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
        pinChangeCommandTxId = nil;
    }
}

- (void)invalidCurrentPin:(NSUInteger)remaining {
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"invalidCurrentPin: pinCommandTxId is nil");
#endif
        return;
    }
    if (self.pinViewController){
        [self.pinViewController invalidPinWithReason: [NSString stringWithFormat:[messages objectForKey:@"AUTHORIZATION_ERROR_PIN_INVALID"],@(remaining)]];
    }
    else{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"invalidCurrentPin", kRemainingAttempts:@(remaining)} ];
        [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
        pinChangeCommandTxId = nil;
    }
}
- (void)pinChangeErrorTooManyPinFailures
{
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"invalidCurrentPin: pinCommandTxId is nil");
#endif
        return;
    }
    [self closePinView];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"pinChangeErrorTooManyAttempts"} ];
    [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
    pinChangeCommandTxId = nil;
}

- (void)pinChanged {
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"pinChanged: pinCommandTxId is nil");
#endif
        return;
    }

    [self closePinView];
    pinEntryMode = PINEntryModeUnknown;

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK	messageAsString:@"pinChanged"];
    [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
    pinChangeCommandTxId = nil;
}

- (void)pinChangeError {
    if (pinChangeCommandTxId == nil) {
#ifdef DEBUG
        NSLog(@"pinChangeError: pinCommandTxId is nil");
#endif
        return;
    }
    if (self.pinViewController){
        [self.pinViewController invalidPinWithReason:[messages objectForKey:@"AUTHORIZATION_ERROR_PIN_CHANGE_FAILED"]];
    }
    else{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{ kReason:@"pinChangeError"} ];
        [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
        pinChangeCommandTxId = nil;
    }
}

#pragma mark -
#pragma mark Util
- (HTTPRequestMethod)requestMethodForString:(NSString *)requestMethodString {
    if ([requestMethodString isEqualToString:@"GET"]) {
        return GET;
    } else	if ([requestMethodString isEqualToString:@"PUT"]) {
        return PUT;
    } else	if ([requestMethodString isEqualToString:@"DELETE"]) {
        return DELETE;
    } else	if ([requestMethodString isEqualToString:@"POST"]) {
        return POST;
    } else {
        return GET;
    }
}

- (HTTPClientParameterEncoding)parameterEncodingForString:(NSString *)paramsEncodingString {
    if ([paramsEncodingString isEqualToString:@"FORM"]) {
        return FormURLParameterEncoding;
    } else if ([paramsEncodingString isEqualToString:@"JSON"]) {
        return JSONParameterEncoding;
    } else if ([paramsEncodingString isEqualToString:@"PROPERTY"]) {
        return PropertyListParameterEncoding;
    } else {
        return JSONParameterEncoding;
    }
}

- (void)setupScreenOrientation:(CDVInvokedUrlCommand *)command{

    if([[UIDevice currentDevice].model rangeOfString:@"iPhone"].location == NSNotFound){
        ((MainViewController*)self.viewController).supportedOrientations = [NSArray arrayWithObjects:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft], [NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight], nil];
        self.supportedOrientations = UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
    }
    else{
        ((MainViewController*)self.viewController).supportedOrientations = [NSArray arrayWithObjects:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait], [NSNumber numberWithInteger:UIInterfaceOrientationPortraitUpsideDown], nil];
        self.supportedOrientations = UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown;
    }
}

#pragma mark -
#pragma mark Custom PIN entry

-(UIViewController*)getTopViewController{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}
/**
 Load the custom configuration and overlay the current view with the custom PIN entry view
 */

- (void)showPinEntryViewInMode:(PINEntryModes)mode {
    if ([[self getTopViewController] isKindOfClass:[PinEntryContainerViewController class]]){
        return;
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480){
        self.pinViewController = [[PinEntryContainerViewController alloc] initWithNibName:@"PinEntryContainerViewController-4s" bundle:nil];
    } else {
        self.pinViewController = [[PinEntryContainerViewController alloc] initWithNibName:@"PinEntryContainerViewController" bundle:nil];
    }


    self.pinViewController.delegate = self;
    self.pinViewController.supportedOrientations = self.supportedOrientations;
    self.pinViewController.mode = mode;
    self.pinViewController.messages = messages;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{kMethod:@"closeInAppBrowser"}];
    pluginResult.keepCallback = @(1);
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.inAppBrowserCommandTxId];

    if (self.pluginInitializedCommandTxId)
    {
        if(self.initializationSuccessful)
            [self sendSuccessCallback:self.inAppBrowserCommandTxId];
        else
            [self sendErrorCallback:self.inAppBrowserCommandTxId];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[self getTopViewController] presentViewController:self.pinViewController animated:YES completion:^{
            self.pinViewController.messages = messages;
        }];
    });
}

/**
 Close the custom PIN entry view
 */
- (void)closePinView {
    if (self.pinViewController != nil) {
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
        self.pinViewController = nil;
    }

    pinEntryMode = PINEntryModeUnknown;
}

/**
 After a PIN validation error occurs the PIN entry must be reset to the state where the user can enter the first PIN again.
 */
- (void)retryPinEntryAfterValidationFailure {
    if (pinEntryMode == PINRegistrationVerififyMode) {
        pinEntryMode = PINRegistrationMode;
    } else if (pinEntryMode == PINChangeNewPinVerifyMode) {
        pinEntryMode = PINChangeNewPinMode;
    }
}

-(bool)isPinValid:(NSString*)pin
{
    NSError* error;
    if(![oneginiClient isPinValid:verifyPin error:&error])
    {
        switch (error.code) {
            case 0: {
                [self pinShouldNotBeASequence];
                break;
            }
            case 1: {
                NSNumber *n = error.userInfo[@"kMaxSimilarDigits"];
                [self pinShouldNotUseSimilarDigits:n.integerValue];
                break;
            }
            case 2: {
                [self pinTooShort];
                break;
            }
            case 3: {
                [self pinBlackListed];
                break;
            }
            default: {
                break;
            }
        }
        return NO;
    }
    else
        return YES;

}

#pragma mark -
#pragma mark PinEntryContainerViewControllerDelegate
- (void)pinEntered:(PinEntryContainerViewController *)controller pin:(NSString *)pin {

    switch (pinEntryMode) {
        case PINCheckMode: {
            [oneginiClient confirmCurrentPin:pin];
            break;
        }
        case PINRegistrationMode: {
            verifyPin = [pin copy];

            if(![self isPinValid:verifyPin])
            {
                [self.pinViewController reset];
            }
            else
            {
                // Switch to registration mode so the user can enter the second verification PIN
                pinEntryMode = PINRegistrationVerififyMode;
                self.pinViewController.mode = PINRegistrationVerififyMode;
                [self.pinViewController reset];
            }
            break;
        }
        case PINRegistrationVerififyMode: {
            if (![verifyPin isEqualToString:pin]) {
                // Perform a retry of the PIN entry
                verifyPin = nil;
                pinEntryMode = PINRegistrationMode;
                self.pinViewController.mode = PINRegistrationMode;
                [self.pinViewController invalidPinWithReason:[messages objectForKey:@"PIN_CODES_DIFFERS"]];
            } else {
                // The user entered the second verification PIN, check if they are equal and confirm the PIN
                verifyPin = nil;
                [oneginiClient confirmNewPin:pin validation:self];
            }

            break;
        }
        case PINChangeCheckMode: {
            [oneginiClient confirmCurrentPinForChangeRequest:pin];
            break;
        }
        case PINChangeNewPinMode: {
            verifyPin = [pin copy];
            if(![self isPinValid:verifyPin])
            {
                [self.pinViewController reset];
            }
            else
            {
                pinEntryMode = PINChangeNewPinVerifyMode;

                self.pinViewController.mode = PINChangeNewPinVerifyMode;
                [self.pinViewController reset];
            }
            break;
        }
        case PINChangeNewPinVerifyMode: {
            if (![verifyPin isEqualToString:pin]) {
                // Perform a retry of the PIN entry
                verifyPin = nil;
                pinEntryMode = PINChangeNewPinMode;
                self.pinViewController.mode = PINChangeNewPinMode;
                [self.pinViewController invalidPinWithReason:[messages objectForKey:@"PIN_CODES_DIFFERS"]];
            } else {
                // The user entered the second verification PIN, check if they are equal and confirm the PIN
                verifyPin = nil;
                [oneginiClient confirmNewPinForChangeRequest:pin validation:self];
            }

        }		default: {
#ifdef DEBUG
            NSLog(@"pinEntered: unknown state");
#endif
        }
    }
}

-(void)pinForgotten:(PinEntryContainerViewController *)controller
{
    [self closePinView];

    NSDictionary *d = @{ kReason:@"authorizationErrorPinForgotten" };
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:d];
    if (authorizeCommandTxId != nil) {
        [self.commandDelegate sendPluginResult:result callbackId:authorizeCommandTxId];
        authorizeCommandTxId = nil;
    } else if (pinChangeCommandTxId != nil) {
        [self.commandDelegate sendPluginResult:result callbackId:pinChangeCommandTxId];
        pinChangeCommandTxId = nil;
    }
}

@end
