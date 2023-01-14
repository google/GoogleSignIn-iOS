// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignInResult.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/API/GIDAuthorizationFlowProcessor.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/GIDAuthorizationFlowProcessor.h"
#import "GoogleSignIn/Sources/GIDAuthorizationUtil.h"
#import "GoogleSignIn/Sources/GIDHTTPFetcher/API/GIDHTTPFetcher.h"
#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/GIDHTTPFetcher.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDKeychainHandler/API/GIDKeychainHandler.h"
#import "GoogleSignIn/Sources/GIDKeychainHandler/Implementations/GIDKeychainHandler.h"
#import "GoogleSignIn/Sources/GIDProfileDataFetcher/API/GIDProfileDataFetcher.h"
#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/GIDProfileDataFetcher.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDCallbackQueue.h"
#import "GoogleSignIn/Sources/GIDScopes.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/GIDAuthStateMigration.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignInResult_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDExternalUserAgentSession.h>
#import <AppAuth/OIDIDToken.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <AppAuth/OIDURLQueryComponent.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization+Keychain.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
#import <AppAuth/OIDAuthorizationService+IOS.h>
#elif TARGET_OS_OSX
#import <AppAuth/OIDAuthorizationService+Mac.h>
#endif

#endif

NS_ASSUME_NONNULL_BEGIN

// The EMM support version
NSString *const kEMMVersion = @"1";

// The name of the query parameter used for logging the restart of auth from EMM callback.
static NSString *const kEMMRestartAuthParameter = @"emmres";

// The URL template for the URL to revoke the token.
static NSString *const kRevokeTokenURLTemplate = @"https://%@/o/oauth2/revoke";

// Expected path for EMM callback.
static NSString *const kEMMCallbackPath = @"/emmcallback";

// The error code for Google Identity.
NSErrorDomain const kGIDSignInErrorDomain = @"com.google.GIDSignIn";

// Keychain constants for saving state in the authentication flow.
static NSString *const kGTMAppAuthKeychainName = @"auth";

// Parameters in the callback URL coming back from browser.
static NSString *const kAuthorizationCodeKeyName = @"code";
static NSString *const kOAuth2ErrorKeyName = @"error";
static NSString *const kOAuth2AccessDenied = @"access_denied";
static NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

// Error string for unavailable keychain.
static NSString *const kKeychainError = @"keychain error";

// Error string for user cancelations.
static NSString *const kUserCanceledError = @"The user canceled the sign-in flow.";

// User preference key to detect fresh install of the app.
static NSString *const kAppHasRunBeforeKey = @"GID_AppHasRunBefore";

// The delay before the new sign-in flow can be presented after the existing one is cancelled.
static const NSTimeInterval kPresentationDelayAfterCancel = 1.0;

// See b/11669751 .
static NSString *const kOpenIDRealmParameter = @"openid.realm";

// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;

// Info.plist config keys
static NSString *const kConfigClientIDKey = @"GIDClientID";
static NSString *const kConfigServerClientIDKey = @"GIDServerClientID";
static NSString *const kConfigHostedDomainKey = @"GIDHostedDomain";
static NSString *const kConfigOpenIDRealmKey = @"GIDOpenIDRealm";

// The callback queue used for authentication flow.
@interface GIDAuthFlow : GIDCallbackQueue

@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, copy, nullable) NSString *emmSupport;
@property(nonatomic, nullable) GIDProfileData *profileData;

@end

@implementation GIDAuthFlow
@end

@implementation GIDSignIn {
  // This value is used when sign-in flows are resumed via the handling of a URL. Its value is
  // set when a sign-in flow is begun via |signInWithOptions:| when the options passed don't
  // represent a sign in continuation.
  GIDSignInInternalOptions *_currentOptions;
  
  // Flag to indicate that the auth flow is restarting.
  BOOL _restarting;
  
  // The class to execute keychain operations.
  id<GIDKeychainHandler> _keychainHandler;
  
  // The class to fetch GIDProfileData object.
  id<GIDProfileDataFetcher> _profileDataFetcher;
  
  // The class to fetches data from a url end point.
  id<GIDHTTPFetcher> _httpFetcher;
  
  // The class to control the authorization flow.
  id<GIDAuthorizationFlowProcessor> _authorizationFlowProcessor;
}

#pragma mark - Public methods

// Handles the custom scheme URL opened by SFSafariViewController or the Device Policy App.
//
// For SFSafariViewController invoked via AppAuth, this method is used on iOS 10.
// For the Device Policy App (EMM flow) this method is used on all iOS versions.
- (BOOL)handleURL:(NSURL *)url {
  // Check if the callback path matches the expected one for a URL from Safari/Chrome/SafariVC.
  if ([url.path isEqual:kBrowserCallbackPath]) {
    if ([_authorizationFlowProcessor resumeExternalUserAgentFlowWithURL:url]) {
      return YES;
    }
    return NO;
  }
  // Check if the callback path matches the expected one for a URL from Google Device Policy app.
  if ([url.path isEqual:kEMMCallbackPath]) {
    return [self handleDevicePolicyAppURL:url];
  }
  return NO;
}

- (BOOL)hasPreviousSignIn {
  if ([_currentUser.authState isAuthorized]) {
    return YES;
  }
  OIDAuthState *authState = [_keychainHandler loadAuthState];
  return [authState isAuthorized];
}

- (void)restorePreviousSignInWithCompletion:(nullable void (^)(GIDGoogleUser *_Nullable user,
                                                               NSError *_Nullable error))completion {
  [self signInWithOptions:[GIDSignInInternalOptions silentOptionsWithCompletion:
                           ^(GIDSignInResult *signInResult, NSError *error) {
    if (signInResult) {
      completion(signInResult.user, nil);
    } else {
      completion(nil, error);
    }
  }]];
}

- (BOOL)restorePreviousSignInNoRefresh {
  if (_currentUser) {
    return YES;
  }

  // Try retrieving an authorization object from the keychain.
  OIDAuthState *authState = [_keychainHandler loadAuthState];
  if (!authState) {
    return NO;
  }

  // Restore current user without refreshing the access token.
  OIDIDToken *idToken =
      [[OIDIDToken alloc] initWithIDTokenString:authState.lastTokenResponse.idToken];
  GIDProfileData *profileData = [_profileDataFetcher fetchProfileDataWithIDToken:idToken];

  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState profileData:profileData];
  self.currentUser = user;
  return YES;
}

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                      hint:(nullable NSString *)hint
                                completion:(nullable GIDSignInCompletion)completion {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:hint
                                                  addScopesFlow:NO
                                                     completion:completion];
  [self signInWithOptions:options];
}

- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                      hint:(nullable NSString *)hint
                          additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                                completion:(nullable GIDSignInCompletion)completion {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:hint
                                                  addScopesFlow:NO
                                                         scopes:additionalScopes
                                                     completion:completion];
  [self signInWithOptions:options];
}

- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                completion:(nullable GIDSignInCompletion)completion {
  [self signInWithPresentingViewController:presentingViewController
                                      hint:nil
                                completion:completion];
}

- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable GIDSignInCompletion)completion {
  NSError *error;
  NSArray<NSString *> *allScopes =
      [GIDAuthorizationUtil resolvedScopesFromGrantedScoped:self.currentUser.grantedScopes
                                              withNewScopes:scopes
                                                      error:&error];
  if (error) {
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
    }
    return;
  }
  
  GIDConfiguration *configuration = self.currentUser.configuration;
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:self.currentUser.profile.email
                                                  addScopesFlow:YES
                                                     completion:completion];
  options.scopes = allScopes;

  [self signInWithOptions:options];
}

#elif TARGET_OS_OSX

- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                              hint:(nullable NSString *)hint
                        completion:(nullable GIDSignInCompletion)completion {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                               presentingWindow:presentingWindow
                                                      loginHint:hint
                                                  addScopesFlow:NO
                                                     completion:completion];
  [self signInWithOptions:options];
}

- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                        completion:(nullable GIDSignInCompletion)completion {
  [self signInWithPresentingWindow:presentingWindow
                              hint:nil
                        completion:completion];
}

- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                              hint:(nullable NSString *)hint
                  additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                        completion:(nullable GIDSignInCompletion)completion {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                               presentingWindow:presentingWindow
                                                      loginHint:hint
                                                  addScopesFlow:NO
                                                         scopes:additionalScopes
                                                     completion:completion];
  [self signInWithOptions:options];
}

- (void)addScopes:(NSArray<NSString *> *)scopes
 presentingWindow:(NSWindow *)presentingWindow
       completion:(nullable GIDSignInCompletion)completion {
  GIDConfiguration *configuration = self.currentUser.configuration;
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
                                               presentingWindow:presentingWindow
                                                      loginHint:self.currentUser.profile.email
                                                  addScopesFlow:YES
                                                     completion:completion];

  NSSet<NSString *> *requestedScopes = [NSSet setWithArray:scopes];
  NSMutableSet<NSString *> *grantedScopes =
      [NSMutableSet setWithArray:self.currentUser.grantedScopes];

  // Check to see if all requested scopes have already been granted.
  if ([requestedScopes isSubsetOfSet:grantedScopes]) {
    // All requested scopes have already been granted, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeScopesAlreadyGranted
                                     userInfo:nil];
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
    }
    return;
  }

  // Use the union of granted and requested scopes.
  [grantedScopes unionSet:requestedScopes];
  options.scopes = [grantedScopes allObjects];

  [self signInWithOptions:options];
}

#endif // TARGET_OS_OSX

- (void)signOut {
  // Clear the current user if there is one.
  if (_currentUser) {
    self.currentUser = nil;
  }
  // Remove all state from the keychain.
  [_keychainHandler removeAllKeychainEntries];
}

- (void)disconnectWithCompletion:(nullable GIDDisconnectCompletion)completion {
  OIDAuthState *authState = _currentUser.authState;
  if (!authState) {
    // Even the user is not signed in right now, we still need to remove any token saved in the
    // keychain.
    authState = [_keychainHandler loadAuthState];
  }
  // Either access or refresh token would work, but we won't have access token if the auth is
  // retrieved from keychain.
  NSString *token = authState.lastTokenResponse.accessToken;
  if (!token) {
    token = authState.lastTokenResponse.refreshToken;
  }
  if (!token) {
    [self signOut];
    // Nothing to do here, consider the operation successful.
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil);
      });
    }
    return;
  }
  NSString *revokeURLString = [NSString stringWithFormat:kRevokeTokenURLTemplate,
      [GIDSignInPreferences googleAuthorizationServer]];
  // Append logging parameter
  revokeURLString = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",
                     revokeURLString,
                     kSDKVersionLoggingParameter,
                     GIDVersion(),
                     kEnvironmentLoggingParameter,
                     GIDEnvironment()];
  NSURL *revokeURL = [NSURL URLWithString:revokeURLString];
  NSMutableURLRequest *revokeRequest = [NSMutableURLRequest requestWithURL:revokeURL];
  [revokeRequest setHTTPMethod:@"POST"];
  NSString *postString = [NSString stringWithFormat:@"token=%@", token];
  [revokeRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  
  [_httpFetcher fetchURLRequest:revokeRequest
                 withAuthorizer:authorization
                    withComment:@"GIDSignIn: revoke tokens"
                     completion:^(NSData *data, NSError *error) {
    // Revoking an already revoked token seems always successful, which helps us here.
    if (!error) {
      [self signOut];
    }
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(error);
      });
    }
  }];
}

#pragma mark - Custom getters and setters

+ (GIDSignIn *)sharedInstance {
  static dispatch_once_t once;
  static GIDSignIn *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] initPrivate];
  });
  return sharedInstance;
}

#pragma mark - Private methods

- (id)initPrivate {
  id<GIDKeychainHandler> keychainHandler = [[GIDKeychainHandler alloc] init];
  id<GIDHTTPFetcher> httpFetcher = [[GIDHTTPFetcher alloc] init];
  id<GIDAuthorizationFlowProcessor> authorizationFlowProcessor =
      [[GIDAuthorizationFlowProcessor alloc] init];
  id<GIDProfileDataFetcher> profileDataFetcher = [[GIDProfileDataFetcher alloc] init];
  return [self initWithKeychainHandler:keychainHandler
                           httpFetcher:httpFetcher
                    profileDataFetcher:profileDataFetcher
            authorizationFlowProcessor:authorizationFlowProcessor];
}

- (instancetype)initWithKeychainHandler:(id<GIDKeychainHandler>)keychainHandler
                            httpFetcher:(id<GIDHTTPFetcher>)httpFetcher
                     profileDataFetcher:(id<GIDProfileDataFetcher>)profileDataFetcher
             authorizationFlowProcessor:
    (id<GIDAuthorizationFlowProcessor>)authorizationFlowProcessor {
  self = [super init];
  if (self) {
    // Get the bundle of the current executable.
    NSBundle *bundle = NSBundle.mainBundle;

    // If we have a bundle, try to set the active configuration from the bundle's Info.plist.
    if (bundle) {
      _configuration = [GIDSignIn configurationFromBundle:bundle];
    }
    
    // Check to see if the 3P app is being run for the first time after a fresh install.
    BOOL isFreshInstall = [self isFreshInstall];

    // If this is a fresh install, ensure that any pre-existing keychain data is purged.
    if (isFreshInstall) {
      [_keychainHandler removeAllKeychainEntries];
    }

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    // Perform migration of auth state from old (before 5.0) versions of the SDK if needed.
    NSURL *tokenEndpointURL = [GIDSignInPreferences tokenEndpointURL];
    [GIDAuthStateMigration migrateIfNeededWithTokenURL:tokenEndpointURL
                                          callbackPath:kBrowserCallbackPath
                                          keychainName:kGTMAppAuthKeychainName
                                        isFreshInstall:isFreshInstall];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    
    _keychainHandler = keychainHandler;
    _httpFetcher = httpFetcher;
    _authorizationFlowProcessor = authorizationFlowProcessor;
    _profileDataFetcher = profileDataFetcher;
  }
  return self;
}

// Does sanity check for parameters and then authenticates if necessary.
- (void)signInWithOptions:(GIDSignInInternalOptions *)options {
  // Options for continuation are not the options we want to cache. The purpose of caching the
  // options in the first place is to provide continuation flows with a starting place from which to
  // derive suitable options for the continuation!
  if (!options.continuation) {
    _currentOptions = options;
  }

  if (options.interactive) {
    // Ensure that a configuration has been provided.
    if (!_configuration) {
      // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
      [NSException raise:NSInvalidArgumentException
                  format:@"No active configuration.  Make sure GIDClientID is set in Info.plist."];
      return;
    }

    // Explicitly throw exception for missing client ID here. This must come before
    // scheme check because schemes rely on reverse client IDs.
    [self assertValidParameters];
    [self assertValidPresentingViewController];

    // If the application does not support the required URL schemes tell the developer so.
    GIDSignInCallbackSchemes *schemes =
        [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
    NSArray<NSString *> *unsupportedSchemes = [schemes unsupportedSchemes];
    if (unsupportedSchemes.count != 0) {
      // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
      [NSException raise:NSInvalidArgumentException
                  format:@"Your app is missing support for the following URL schemes: %@",
                         [unsupportedSchemes componentsJoinedByString:@", "]];
    }
  }

  // If this is a non-interactive flow, use cached authentication if possible.
  if (!options.interactive && _currentUser) {
    [_currentUser refreshTokensIfNeededWithCompletion:^(GIDGoogleUser *unused, NSError *error) {
      if (error) {
        [self authenticateWithOptions:options];
      } else {
        if (options.completion) {
          self->_currentOptions = nil;
          dispatch_async(dispatch_get_main_queue(), ^{
            GIDSignInResult *signInResult =
                [[GIDSignInResult alloc] initWithGoogleUser:self->_currentUser serverAuthCode:nil];
            options.completion(signInResult, nil);
          });
        }
      }
    }];
  } else {
    [self authenticateWithOptions:options];
  }
}

#pragma mark - Authentication flow

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options {
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX
  
  [_authorizationFlowProcessor startWithOptions:options
                                     emmSupport:(NSString *)emmSupport
                                     completion:^(OIDAuthorizationResponse *authorizationResponse,
                                                  NSError *error) {
    [self processAuthorizationResponse:authorizationResponse
                                 error:error
                            emmSupport:emmSupport];
  }];
}

- (void)processAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                               error:(NSError *)error
                          emmSupport:(NSString *)emmSupport{
  if (_restarting) {
    // The auth flow is restarting, so the work here would be performed in the next round.
    _restarting = NO;
    return;
  }

  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];
  authFlow.emmSupport = emmSupport;

  if (authorizationResponse) {
    if (authorizationResponse.authorizationCode.length) {
      authFlow.authState = [[OIDAuthState alloc]
          initWithAuthorizationResponse:authorizationResponse];
      // perform auth code exchange
      [self maybeFetchToken:authFlow];
    } else {
      // There was a failure, convert to appropriate error code.
      NSString *errorString;
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      if (authFlow.emmSupport) {
        [authFlow wait];
        BOOL isEMMError = [[GIDEMMErrorHandler sharedInstance]
            handleErrorFromResponse:params
                         completion:^{
                           [authFlow next];
                         }];
        if (isEMMError) {
          errorCode = kGIDSignInErrorCodeEMM;
        }
      }
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      errorString = (NSString *)params[kOAuth2ErrorKeyName];
      if ([errorString isEqualToString:kOAuth2AccessDenied]) {
        errorCode = kGIDSignInErrorCodeCanceled;
      }

      authFlow.error = [self errorWithString:errorString code:errorCode];
    }
  } else {
    NSString *errorString = [error localizedDescription];
    GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
    if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow) {
      // The user has canceled the flow at the iOS modal dialog.
      errorString = kUserCanceledError;
      errorCode = kGIDSignInErrorCodeCanceled;
    }
    authFlow.error = [self errorWithString:errorString code:errorCode];
  }

  [self addDecodeIdTokenCallback:authFlow];
  [self addSaveAuthCallback:authFlow];
  [self addCompletionCallback:authFlow];
}

// Perform authentication with the provided options.
- (void)authenticateWithOptions:(GIDSignInInternalOptions *)options {
  // If this is an interactive flow, we're not going to try to restore any saved auth state.
  if (options.interactive) {
    [self authenticateInteractivelyWithOptions:options];
    return;
  }

  // Try retrieving an authorization object from the keychain.
  OIDAuthState *authState = [_keychainHandler loadAuthState];

  if (![authState isAuthorized]) {
    // No valid auth in keychain, per documentation/spec, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                     userInfo:nil];
    if (options.completion) {
      _currentOptions = nil;
      dispatch_async(dispatch_get_main_queue(), ^{
        options.completion(nil, error);
      });
    }
    return;
  }

  // Complete the auth flow using saved auth in keychain.
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];
  authFlow.authState = authState;
  [self maybeFetchToken:authFlow];
  [self addDecodeIdTokenCallback:authFlow];
  [self addSaveAuthCallback:authFlow];
  [self addCompletionCallback:authFlow];
}

// Fetches the access token if necessary as part of the auth flow.
- (void)maybeFetchToken:(GIDAuthFlow *)authFlow {
  OIDAuthState *authState = authFlow.authState;
  // Do nothing if we have an auth flow error or a restored access token that isn't near expiration.
  if (authFlow.error ||
      (authState.lastTokenResponse.accessToken &&
        [authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
        kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }
  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (_currentOptions.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = _currentOptions.configuration.serverClientID;
  }
  if (_currentOptions.configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = _currentOptions.configuration.openIDRealm;
  }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSDictionary<NSString *, NSObject *> *params =
      authState.lastAuthorizationResponse.additionalParameters;
  NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:@{}
                                   emmSupport:authFlow.emmSupport
                       isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  OIDTokenRequest *tokenRequest;
  if (!authState.lastTokenResponse.accessToken &&
      authState.lastAuthorizationResponse.authorizationCode) {
    tokenRequest = [authState.lastAuthorizationResponse
        tokenExchangeRequestWithAdditionalParameters:additionalParameters];
  } else {
    [additionalParameters
        addEntriesFromDictionary:authState.lastTokenResponse.request.additionalParameters];
    tokenRequest = [authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  }

  [authFlow wait];
  [OIDAuthorizationService
      performTokenRequest:tokenRequest
                 callback:^(OIDTokenResponse *_Nullable tokenResponse,
                            NSError *_Nullable error) {
    [authState updateWithTokenResponse:tokenResponse error:error];
    authFlow.error = error;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    if (authFlow.emmSupport) {
      [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *error) {
        authFlow.error = error;
        [authFlow next];
      }];
    } else {
      [authFlow next];
    }
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    [authFlow next];
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  }];
}

// Adds a callback to the auth flow to save the auth object to |self| and the keychain as well.
- (void)addSaveAuthCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (authState && !handlerAuthFlow.error) {
      if (![self->_keychainHandler saveAuthState:authState]) {
        handlerAuthFlow.error = [self errorWithString:kKeychainError
                                                 code:kGIDSignInErrorCodeKeychain];
        return;
      }

      if (self->_currentOptions.addScopesFlow) {
        [self->_currentUser updateWithTokenResponse:authState.lastTokenResponse
                              authorizationResponse:authState.lastAuthorizationResponse
                                        profileData:handlerAuthFlow.profileData];
      } else {
        GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                           profileData:handlerAuthFlow.profileData];
        self.currentUser = user;
      }
    }
  }];
}

// Adds a callback to the auth flow to extract user data from the ID token where available and
// make a userinfo request if necessary.
- (void)addDecodeIdTokenCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (!authState || handlerAuthFlow.error) {
      return;
    }
    
    [handlerAuthFlow wait];
    
    [self->_profileDataFetcher
        fetchProfileDataWithAuthState:(OIDAuthState *)authState
                           completion:^(GIDProfileData *_Nullable profileData,
                                        NSError *_Nullable error) {
      if (error) {
        handlerAuthFlow.error = error;
      } else {
        handlerAuthFlow.profileData = profileData;
      }
      [handlerAuthFlow next];
    }];
  }];
}

// Adds a callback to the auth flow to complete the flow by calling the sign-in callback.
- (void)addCompletionCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    if (self->_currentOptions.completion) {
      GIDSignInCompletion completion = self->_currentOptions.completion;
      self->_currentOptions = nil;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (handlerAuthFlow.error) {
          completion(nil, handlerAuthFlow.error);
        } else {
          OIDAuthState *authState = handlerAuthFlow.authState;
          NSString *_Nullable serverAuthCode =
              [authState.lastTokenResponse.additionalParameters[@"server_code"] copy];
          GIDSignInResult *signInResult =
              [[GIDSignInResult alloc] initWithGoogleUser:self->_currentUser
                                           serverAuthCode:serverAuthCode];
          completion(signInResult, nil);
        }
      });
    }
  }];
}

// Parse incoming URL from the Google Device Policy app.
- (BOOL)handleDevicePolicyAppURL:(NSURL *)url {
  OIDURLQueryComponent *queryComponent = [[OIDURLQueryComponent alloc] initWithURL:url];
  NSDictionary<NSString *, NSObject<NSCopying> *> *params = queryComponent.dictionaryValue;
  NSObject<NSCopying> *actionParam = params[@"action"];
  NSString *actionString =
      [actionParam isKindOfClass:[NSString class]] ? (NSString *)actionParam : nil;
  if (![@"restart_auth" isEqualToString:actionString]) {
    return NO;
  }
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  if (!_currentOptions.presentingViewController) {
    return NO;
  }
#elif TARGET_OS_OSX
  if (!_currentOptions.presentingWindow) {
    return NO;
  }
#endif // TARGET_OS_OSX
  if (!_authorizationFlowProcessor.isStarted) {
    return NO;
  }
  _restarting = YES;
  [_authorizationFlowProcessor cancelAuthenticationFlow];
  _restarting = NO;
  NSDictionary<NSString *, NSString *> *extraParameters = @{ kEMMRestartAuthParameter : @"1" };
  // In iOS 13 the presentation of ASWebAuthenticationSession needs an anchor window,
  // so we need to wait until the previous presentation is completely gone to ensure the right
  // anchor window is used here.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                 (int64_t)(kPresentationDelayAfterCancel * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [self signInWithOptions:[self->_currentOptions optionsWithExtraParameters:extraParameters
                                                              forContinuation:YES]];
  });
  return YES;
}

#pragma mark - Helpers

- (NSError *)errorWithString:(NSString *)errorString code:(GIDSignInErrorCode)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  return [NSError errorWithDomain:kGIDSignInErrorDomain
                             code:code
                         userInfo:errorDict];
}

+ (BOOL)isOperatingSystemAtLeast9 {
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  return [processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
      [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
}

// Asserts the parameters being valid.
- (void)assertValidParameters {
  if (![_currentOptions.configuration.clientID length]) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"You must specify |clientID| in |GIDConfiguration|"];
  }
}

// Assert that the presenting view controller has been set.
- (void)assertValidPresentingViewController {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  if (!_currentOptions.presentingViewController)
#elif TARGET_OS_OSX
  if (!_currentOptions.presentingWindow)
#endif // TARGET_OS_OSX
  {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"|presentingViewController| must be set."];
  }
}

// Checks whether or not this is the first time the app runs.
- (BOOL)isFreshInstall {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults boolForKey:kAppHasRunBeforeKey]) {
    return NO;
  }
  [defaults setBool:YES forKey:kAppHasRunBeforeKey];
  return YES;
}

// Try to retrieve a configuration value from an |NSBundle|'s Info.plist for a given key.
+ (nullable NSString *)configValueFromBundle:(NSBundle *)bundle forKey:(NSString *)key {
  NSString *value;
  id configValue = [bundle objectForInfoDictionaryKey:key];
  if ([configValue isKindOfClass:[NSString class]]) {
    value = configValue;
  }
  return value;
}

// Try to generate a |GIDConfiguration| from an |NSBundle|'s Info.plist.
+ (nullable GIDConfiguration *)configurationFromBundle:(NSBundle *)bundle {
  GIDConfiguration *configuration;

  // Retrieve any valid config parameters from the bundle's Info.plist.
  NSString *clientID = [GIDSignIn configValueFromBundle:bundle forKey:kConfigClientIDKey];
  NSString *serverClientID = [GIDSignIn configValueFromBundle:bundle
                                                       forKey:kConfigServerClientIDKey];
  NSString *hostedDomain = [GIDSignIn configValueFromBundle:bundle forKey:kConfigHostedDomainKey];
  NSString *openIDRealm = [GIDSignIn configValueFromBundle:bundle forKey:kConfigOpenIDRealmKey];
    
  // If we have at least a client ID, try to construct a configuration.
  if (clientID) {
    configuration = [[GIDConfiguration alloc] initWithClientID:clientID
                                                 serverClientID:serverClientID
                                                   hostedDomain:hostedDomain
                                                    openIDRealm:openIDRealm];
  }
  
  return configuration;
}

@end

NS_ASSUME_NONNULL_END
