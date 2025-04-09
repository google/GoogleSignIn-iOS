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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/GIDAuthorizationResponseHelper.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Implementations/GIDAuthorizationResponseHandler.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/GIDAuthorizationResponseHelper.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Implementations/GIDAuthorizationResponseHandler.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDExternalUserAgentSession.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDExternalUserAgentSession.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <AppAuth/OIDAuthorizationService+IOS.h>
#endif


#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <AppAuth/OIDAuthorizationService+IOS.h>
#endif

#endif

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

// TODO: Unify error domain across sign-in and verify flow (#425).
NSErrorDomain const kGIDVerifyErrorDomain = @"com.google.GIDVerifyAccountDetail";

@implementation GIDVerifyAccountDetail {
  /// Represents the list of account details to verify.
  NSArray<GIDVerifiableAccountDetail *> *_accountDetails;
  /// Represents internal options for the verification flow.
  GIDSignInInternalOptions *_options;
  /// AppAuth configuration object.
  OIDServiceConfiguration *_appAuthConfiguration;
  /// AppAuth external user-agent session state.
  id<OIDExternalUserAgentSession> _currentAuthorizationFlow;
}

- (instancetype)initWithConfig:(GIDConfiguration *)configuration {
  self = [super init];
  if (self) {
    _configuration = configuration;

    NSString *authorizationEndpointURL = 
        [NSString stringWithFormat:kAuthorizationURLTemplate,
         [GIDSignInPreferences googleAuthorizationServer]];
    NSString *tokenEndpointURL =
        [NSString stringWithFormat:kTokenURLTemplate, [GIDSignInPreferences googleTokenServer]];
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
  self->_options = options;
  self->_accountDetails = accountDetails;
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

  NSMutableArray *scopes = [[NSMutableArray alloc] init];
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
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:authorizationResponse
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerifyAccountDetail
                                                               configuration:_configuration
                                                                       error:error];
  GIDAuthorizationResponseHelper *responseHelper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHandler];

  GIDAuthFlow *authFlow = [responseHelper fetchAuthFlowFromProcessedResponse];

  if (authFlow) {
    [self addCompletionCallback:authFlow];
  }
}

#pragma mark - Helpers

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

- (void)addCompletionCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    if (self->_options.verifyCompletion) {
      GIDVerifyCompletion completion = self->_options.verifyCompletion;
      self->_options = nil;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (handlerAuthFlow.error) {
          completion(nil, handlerAuthFlow.error);
        } else {
          OIDAuthState *authState = handlerAuthFlow.authState;
          GIDVerifiedAccountDetailResult *verifiedResult = [[GIDVerifiedAccountDetailResult alloc]
              initWithAccountDetails:self->_accountDetails
                           authState:authState];
          completion(verifiedResult, nil);
        }
      });
    }
  }];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
