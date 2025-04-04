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

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/GIDAuthorizationFlow.h"
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

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration {
  return [self initWithKeychainStore:keychainStore
                       configuration:configuration
        authorizationFlowCoordinator:nil];
}

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration
         authorizationFlowCoordinator:(nullable id<GIDAuthorizationFlowCoordinator>)authFlow {
  self = [super init];
  if (self) {
    _keychainStore = keychainStore;
    NSBundle *mainBundle = [NSBundle mainBundle];
    GIDConfiguration *defaultConfiguration = [GIDConfiguration configurationFromBundle:mainBundle];
    _currentConfiguration = configuration ?: defaultConfiguration;
    _authFlow = authFlow;
    
    NSString *authorizationEnpointURL = [NSString stringWithFormat:kAuthorizationURLTemplate,
                                         [GIDSignInPreferences googleAuthorizationServer]];
    NSString *tokenEndpointURL = [NSString stringWithFormat:kTokenURLTemplate,
                                  [GIDSignInPreferences googleTokenServer]];
    _appAuthConfiguration = [[OIDServiceConfiguration alloc]
                              initWithAuthorizationEndpoint:[NSURL URLWithString:authorizationEnpointURL]
                                              tokenEndpoint:[NSURL URLWithString:tokenEndpointURL]];
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
  if (!options.interactive && self.currentUser) {
    [self.currentUser refreshTokensIfNeededWithCompletion:^(GIDGoogleUser *unused, NSError *error) {
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

#pragma mark - Authorization Flow

- (void)authenticateWithOptions:(GIDSignInInternalOptions *)options {
  // If this is an interactive flow, we're not going to try to restore any saved auth state.
  if (options.interactive) {
    [self authenticateInteractivelyWithOptions:options];
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

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options {
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX

  [self authorizationRequestWithOptions:options
                             completion:^(OIDAuthorizationRequest * _Nullable request,
                                          NSError * _Nullable error) {
    self->_authFlow.currentUserAgentSession =
      [OIDAuthorizationService presentAuthorizationRequest:request
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                  presentingViewController:options.presentingViewController
#elif TARGET_OS_OSX
                                          presentingWindow:options.presentingWindow
#endif // TARGET_OS_OSX
                                                  callback:
                                                    ^(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                                      NSError *_Nullable error) {
        [self->_authFlow processAuthorizationResponse:authorizationResponse
                                                error:error
                                           emmSupport:emmSupport];
    }];
  }];
}

#pragma mark - Authorization Request

- (void)authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
                             completion:
(void (^)(OIDAuthorizationRequest *_Nullable request, NSError *_Nullable error))completion {
  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
      [self additionalParametersFromOptions:options];
  OIDAuthorizationRequest *request = [self authorizationRequestWithOptions:options
                                                      additionalParameters:additionalParameters];
  // TODO: Add app check steps as well
  completion(request, nil);
}

- (OIDAuthorizationRequest *)
authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
           additionalParameters:(NSDictionary<NSString *, NSString *> *)additionalParameters {
  OIDAuthorizationRequest *request;
  if (options.nonce) {
    request = [[OIDAuthorizationRequest alloc] initWithConfiguration:_appAuthConfiguration
                                                            clientId:options.configuration.clientID
                                                              scopes:options.scopes
                                                         redirectURL:[self redirectURLWithOptions:options]
                                                        responseType:OIDResponseTypeCode
                                                               nonce:options.nonce
                                                additionalParameters:additionalParameters];
  } else {
    request = [[OIDAuthorizationRequest alloc] initWithConfiguration:_appAuthConfiguration
                                                            clientId:options.configuration.clientID
                                                              scopes:options.scopes
                                                         redirectURL:[self redirectURLWithOptions:options]
                                                        responseType:OIDResponseTypeCode
                                                additionalParameters:additionalParameters];
  }
  return request;
}

- (NSMutableDictionary<NSString *, NSString *> *)
    additionalParametersFromOptions:(GIDSignInInternalOptions *)options {
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX

  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
      [[NSMutableDictionary alloc] init];
  additionalParameters[kIncludeGrantedScopesParameter] = @"true";
  if (options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = options.configuration.serverClientID;
  }
  if (options.loginHint) {
    additionalParameters[kLoginHintParameter] = options.loginHint;
  }
  if (options.configuration.hostedDomain) {
    additionalParameters[kHostedDomainParameter] = options.configuration.hostedDomain;
  }

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:options.extraParams
                                   emmSupport:emmSupport
                       isPasscodeInfoRequired:NO]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:options.extraParams];
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  return additionalParameters;
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

#pragma mark - Utilities

+ (BOOL)isOperatingSystemAtLeast9 {
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  return [processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
      [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
}

- (NSURL *)redirectURLWithOptions:(GIDSignInInternalOptions *)options {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
  NSURL *redirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@",
                                             [schemes clientIdentifierScheme],
                                             kBrowserCallbackPath]];
  return redirectURL;
}

@end
