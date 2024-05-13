/*
 * Copyright 2024 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiedAccountDetailResult.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDCallbackQueue.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>
#import <AppAuth/OIDExternalUserAgentSession.h>
#endif

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

// The URL template for the authorization endpoint.
static NSString *const kAuthorizationURLTemplate = @"https://%@/o/oauth2/v2/auth";

// The URL template for the token endpoint.
static NSString *const kTokenURLTemplate = @"https://%@/token";

// Expected path in the URL scheme to be handled.
static NSString *const kBrowserCallbackPath = @"/oauth2callback";

// The error code for Google Identity.
NSErrorDomain const kGIDVerifyErrorDomain = @"com.google.GIDVerify";

// Error string for user cancelations.
static NSString *const kUserCanceledError = @"The user canceled the verification flow.";

// Parameters in the callback URL coming back from browser.
static NSString *const kOAuth2ErrorKeyName = @"error";
static NSString *const kOAuth2AccessDenied = @"access_denied";

// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;

// The callback queue used for authentication flow.
@interface GIDVerifyAuthFlow : GIDCallbackQueue

@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, nullable) GIDProfileData *profileData;

@end

@implementation GIDVerifyAuthFlow
@end

@implementation GIDVerifyAccountDetail {
  // AppAuth configuration object.
  OIDServiceConfiguration *_appAuthConfiguration;
  // AppAuth external user-agent session state.
  id<OIDExternalUserAgentSession> _currentAuthorizationFlow;
}

- (nullable instancetype)initWithConfig:(GIDConfiguration *)configuration {
  self = [super init];
  if (self) {
    _configuration = configuration;

    NSString *authorizationEndpointURL = [NSString stringWithFormat:kAuthorizationURLTemplate,
                                          [GIDSignInPreferences googleAuthorizationServer]];
    NSString *tokenEndpointURL = [NSString stringWithFormat:kTokenURLTemplate,
                                  [GIDSignInPreferences googleTokenServer]];
    _appAuthConfiguration = [[OIDServiceConfiguration alloc]
        initWithAuthorizationEndpoint:[NSURL URLWithString:authorizationEndpointURL]
                        tokenEndpoint:[NSURL URLWithString:tokenEndpointURL]];
  }
  return self;
}

- (nullable instancetype)init {
  GIDConfiguration *configuration;
  NSBundle *bundle = NSBundle.mainBundle;
  if (bundle) {
    configuration = [GIDConfiguration configurationFromBundle:bundle];
  }

  if (!configuration) {
    return nil;
  }

  return [self initWithConfig:configuration];
}

#pragma mark - Public methods

- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion {
  [self verifyAccountDetails:accountDetails
    presentingViewController:presentingViewController
                        hint:nil
                  completion:completion];
}

- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion {
  GIDSignInInternalOptions *options =
  [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                   presentingViewController:presentingViewController
                                                  loginHint:hint
                                              addScopesFlow:YES
                                     accountDetailsToVerify:accountDetails
                                           verifyCompletion:completion];

  [self verifyAccountDetailsInteractivelyWithOptions:options];
}

#pragma mark - Authentication flow

- (void)verifyAccountDetailsInteractivelyWithOptions:(GIDSignInInternalOptions *)options {
  if (!options.interactive) {
    return;
  }

  // Ensure that a configuration is set.
  if (!_configuration) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"No active configuration. Make sure GIDClientID is set in Info.plist."];
    return;
  }

  [self assertValidCurrentUser];

  // Explicitly throw exception for missing client ID here. This must come before
  // scheme check because schemes rely on reverse client IDs.
  [self assertValidParameters:options];

  [self assertValidPresentingViewController:options];

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
  NSURL *redirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@",
                                             [schemes clientIdentifierScheme],
                                             kBrowserCallbackPath]];

  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = options.configuration.serverClientID;
  }
  if (options.loginHint) {
    additionalParameters[kLoginHintParameter] = options.loginHint;
  }
  if (options.configuration.hostedDomain) {
    additionalParameters[kHostedDomainParameter] = options.configuration.hostedDomain;
  }

  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  NSMutableArray *scopes;
  for (GIDVerifiableAccountDetail *detail in options.accountDetailsToVerify) {
    NSString *scopeString = [detail scope];
    if (scopeString) {
      [scopes addObject:scopeString];
    }
  }

  OIDAuthorizationRequest *request =
      [[OIDAuthorizationRequest alloc] initWithConfiguration:_appAuthConfiguration
                                                    clientId:options.configuration.clientID
                                                      scopes:scopes
                                                 redirectURL:redirectURL
                                                responseType:OIDResponseTypeCode
                                        additionalParameters:additionalParameters];

   _currentAuthorizationFlow = [OIDAuthorizationService
       presentAuthorizationRequest:request
          presentingViewController:options.presentingViewController
                          callback:^(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                     NSError *_Nullable error) {
     [self processAuthorizationResponse:authorizationResponse
                                  error:error];
  }];
}

- (void)processAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                               error:(NSError *)error {
  GIDVerifyAuthFlow *authFlow = [[GIDVerifyAuthFlow alloc] init];

  if (authorizationResponse) {
    if (authorizationResponse.authorizationCode.length) {
      authFlow.authState =
          [[OIDAuthState alloc] initWithAuthorizationResponse:authorizationResponse];
      // perform auth code exchange
      [self maybeFetchToken:authFlow];
    } else {
      // There was a failure, convert to appropriate error code.
      NSString *errorString;
      GIDVerifyErrorCode errorCode = kGIDVerifyErrorCodeUnknown;
      NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;

      errorString = (NSString *)params[kOAuth2ErrorKeyName];
      if ([errorString isEqualToString:kOAuth2AccessDenied]) {
        errorCode = kGIDVerifyErrorCodeCanceled;
      }

      authFlow.error = [self errorWithString:errorString code:errorCode];
    }
  } else {
    NSString *errorString = [error localizedDescription];
    GIDVerifyErrorCode errorCode = kGIDVerifyErrorCodeUnknown;
    if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow) {
      errorString = kUserCanceledError;
      errorCode = kGIDVerifyErrorCodeCanceled;
    }
    authFlow.error = [self errorWithString:errorString code:errorCode];
  }

  // TODO: Add completion callback method (#413).
}

// Fetches the access token if necessary as part of the auth flow.
- (void)maybeFetchToken:(GIDVerifyAuthFlow *)authFlow {
  OIDAuthState *authState = authFlow.authState;
  // Do nothing if we have an auth flow error or a restored access token that isn't near expiration.
  if (authFlow.error ||
      (authState.lastTokenResponse.accessToken &&
       [authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
       kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }
  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (_configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = _configuration.serverClientID;
  }
  if (_configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = _configuration.openIDRealm;
  }
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

    [authFlow next];
  }];
}

#pragma mark - Helpers

- (NSError *)errorWithString:(NSString *)errorString code:(GIDVerifyErrorCode)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  return [NSError errorWithDomain:kGIDVerifyErrorDomain
                             code:code
                         userInfo:errorDict];
}

// Assert that a current user exists.
- (void)assertValidCurrentUser {
  if (!GIDSignIn.sharedInstance.currentUser) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"|currentUser| must be set to verify."];
  }
}

// Asserts the parameters being valid.
- (void)assertValidParameters:(GIDSignInInternalOptions *)options {
  if (![options.configuration.clientID length]) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"You must specify |clientID| in |GIDConfiguration|"];
  }
}

// Assert that the presenting view controller has been set.
- (void)assertValidPresentingViewController:(GIDSignInInternalOptions *)options {
  if (!options.presentingViewController) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"|presentingViewController| must be set."];
  }
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
