/*
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthorization.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/API/GIDAuthorizationFlowCoordinator.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/GIDAuthorizationFlow.h"
#import "GoogleSignIn/Sources/GIDAuthorization_Private.h"
#import "GoogleSignIn/Sources/GIDConfiguration_Private.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDSignInResult_Private.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

// TODO: Put these constants in a constants file/class
static NSString *const kGSIServiceName = @"gsi_auth";
/// The EMM support version
static NSString *const kEMMVersion = @"1";

// Parameters for the auth and token exchange endpoints.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";
static NSString *const kIncludeGrantedScopesParameter = @"include_granted_scopes";
static NSString *const kLoginHintParameter = @"login_hint";
static NSString *const kHostedDomainParameter = @"hd";

/// Expected path in the URL scheme to be handled.
static NSString *const kBrowserCallbackPath = @"/oauth2callback";
/// The URL template for the authorization endpoint.
static NSString *const kAuthorizationURLTemplate = @"https://%@/o/oauth2/v2/auth";
/// The URL template for the token endpoint.
static NSString *const kTokenURLTemplate = @"https://%@/token";

@interface GIDAuthorization ()

@property(nonatomic, readonly) OIDServiceConfiguration *appAuthConfiguration;

@end

@implementation GIDAuthorization

#pragma mark - Initialization

- (instancetype)init {
  NSBundle *mainBundle = [NSBundle mainBundle];
  GIDConfiguration *defaultConfiguration = [GIDConfiguration configurationFromBundle:mainBundle];
  return [self initWithConfiguration:defaultConfiguration];
}

- (instancetype)initWithConfiguration:(GIDConfiguration *)configuration {
  GTMKeychainStore *keychainStore = [[GTMKeychainStore alloc] initWithItemName:kGSIServiceName];
  return [self initWithKeychainStore:keychainStore configuration:configuration];
}

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore {
  return [self initWithKeychainStore:keychainStore configuration:nil];
}

- (instancetype)initWithKeychainStore:(nullable GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration {
  return [self initWithKeychainStore:keychainStore
                       configuration:configuration
        authorizationFlowCoordinator:nil];
}

- (instancetype)initWithKeychainStore:(nullable GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration
         authorizationFlowCoordinator:(nullable id<GIDAuthorizationFlowCoordinator>)authFlow {
  self = [super init];
  if (self) {
    GTMKeychainStore *defaultStore = [[GTMKeychainStore alloc] initWithItemName:kGSIServiceName];
    GTMKeychainStore *store = keychainStore ?: defaultStore;
    _keychainStore = store;
    NSBundle *mainBundle = [NSBundle mainBundle];
    GIDConfiguration *defaultConfiguration = [GIDConfiguration configurationFromBundle:mainBundle];
    _currentConfiguration = configuration ?: defaultConfiguration;
    _authFlow = authFlow;
    // FIXME: This should be cleaner; i.e., the options has a configuration too...
    _authFlow.configuration = _currentConfiguration;
    _currentOptions = _authFlow.options;
    
    NSString *authorizationEnpointURL = [NSString stringWithFormat:kAuthorizationURLTemplate,
                                         [GIDSignInPreferences googleAuthorizationServer]];
    NSString *tokenEndpointURL = [NSString stringWithFormat:kTokenURLTemplate,
                                  [GIDSignInPreferences googleTokenServer]];
    NSURL *authEndpoint = [NSURL URLWithString:authorizationEnpointURL];
    NSURL *tokenEndpoint = [NSURL URLWithString:tokenEndpointURL];
    _appAuthConfiguration =
      [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authEndpoint
                                                       tokenEndpoint:tokenEndpoint];
    _authFlow.serviceConfiguration = _appAuthConfiguration;
  }
  return self;
}

#pragma mark - Restoring Previous Sign Ins

- (BOOL)hasPreviousSignIn {
  if (self.currentUser) {
    return self.currentUser.authState.isAuthorized;
  }
  OIDAuthState *authState = [self loadAuthState];
  return authState.isAuthorized;
}

#pragma mark - Load Previous Authorization State

- (nullable OIDAuthState *)loadAuthState {
  GTMAuthSession *authSession = [self.keychainStore retrieveAuthSessionWithError:nil];
  return authSession.authState;
}

#pragma mark - Signing In

// FIXME: Do not pass options here; put this on `GIDAuthorizationFlow`
// But perhaps `options` are needed because the presenting vc could change
- (void)signInWithOptions:(GIDSignInInternalOptions *)options {
  // Options for continuation are not the options we want to cache. The purpose of caching the
  // options in the first place is to provide continuation flows with a starting place from which to
  // derive suitable options for the continuation!
  if (!options.continuation) {
    self.currentOptions = options;
  }
  
  if (options.interactive) {
    // Ensure that a configuration has been provided.
    if (!self.currentConfiguration) {
      // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
      [NSException raise:NSInvalidArgumentException
                  format:@"No active configuration. Make sure GIDClientID is set in Info.plist."];
      return;
    }
    
    // Explicitly throw exception for missing client ID here. This must come before
    // scheme check because schemes rely on reverse client IDs.
    [self assertValidParameters];
    
    [self assertValidPresentingController];
    
    id<GIDBundle> bundle = self.authFlow.options.bundle;
    NSString *clientID = self.currentOptions.configuration.clientID;
    
    // If the application does not support the required URL schemes tell the developer so.
    GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:clientID bundle:bundle];
    NSArray<NSString *> *unsupportedSchemes = [schemes unsupportedSchemes];
    if (unsupportedSchemes.count != 0) {
      // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
      [NSException raise:NSInvalidArgumentException
                  format:@"Your app is missing support for the following URL schemes: %@",
       [unsupportedSchemes componentsJoinedByString:@", "]];
    }
  }
  
  // If this is a non-interactive flow, use cached authentication if possible.
  if (!options.interactive && self.currentUser) {
    [self.currentUser refreshTokensIfNeededWithCompletion:^(GIDGoogleUser *unused, NSError *error) {
      if (error) {
        [self authenticateWithOptions:options];
      } else {
        if (options.completion) {
          self->_currentOptions = nil;
          dispatch_async(dispatch_get_main_queue(), ^{
            GIDSignInResult *signInResult =
              [[GIDSignInResult alloc] initWithGoogleUser:[self currentUser] serverAuthCode:nil];
            options.completion(signInResult, nil);
          });
        }
      }
    }];
  } else {
    [self authenticateWithOptions:options];
  }
}

#pragma mark - Authorization Flow

// FIXME: Do not pass options here
- (void)authenticateWithOptions:(GIDSignInInternalOptions *)options {
  // If this is an interactive flow, we're not going to try to restore any saved auth state.
  if (options.interactive) {
    [self.authFlow authorizeInteractively];
    return;
  }

  // Try retrieving an authorization object from the keychain.
  OIDAuthState *authState = [self loadAuthState];

  if (![authState isAuthorized]) {
    // No valid auth in keychain, per documentation/spec, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                     userInfo:nil];
    if (options.completion) {
      self.currentOptions = nil;
      dispatch_async(dispatch_get_main_queue(), ^{
        options.completion(nil, error);
      });
    }
    return;
  }

  self.authFlow = [[GIDAuthorizationFlow alloc] initWithSignInOptions:self.currentOptions
                                                            authState:authState
                                                          profileData:nil
                                                           googleUser:self.currentUser
                                             externalUserAgentSession:nil
                                                           emmSupport:nil
                                                                error:nil];
  // TODO: Implement the interactive version with operations as well
  [self.authFlow authorize];
}

#pragma mark - Validity Assertions

- (void)assertValidParameters {
  if (![_currentOptions.configuration.clientID length]) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"You must specify `clientID` in `GIDConfiguration`"];
  }
}

- (void)assertValidPresentingController {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  if (!self.currentOptions.presentingViewController)
#elif TARGET_OS_OSX
  if (!self.currentOptions.presentingWindow)
#endif // TARGET_OS_OSX
  {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"`presentingViewController` must be set."];
  }
}

#pragma mark - Current User

- (nullable GIDGoogleUser *)currentUser {
  return self.authFlow.googleUser;
}

@end
