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

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>
#endif

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDVerifyAccountDetail {
  /// AppAuth configuration object.
  OIDServiceConfiguration *_appAuthConfiguration;
}

- (instancetype)initWithConfig:(GIDConfiguration *)configuration {
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

- (instancetype)init {
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
  NSString *redirectURI =
      [NSString stringWithFormat:@"%@:%@", [schemes clientIdentifierScheme], kBrowserCallbackPath];
  NSURL *redirectURL = [NSURL URLWithString:redirectURI];

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

  // TODO(#405): Use request variable to present request and process response.
  __unused OIDAuthorizationRequest *request =
      [[OIDAuthorizationRequest alloc] initWithConfiguration:_appAuthConfiguration
                                                    clientId:options.configuration.clientID
                                                      scopes:scopes
                                                 redirectURL:redirectURL
                                                responseType:OIDResponseTypeCode
                                        additionalParameters:additionalParameters];
}

#pragma mark - Helpers

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
