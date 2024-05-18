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

#import "GoogleSignIn/Sources/GIDAuthorizationResponseHelper.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"


@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#endif

// Error string for user cancelations.
static NSString *const kUserCanceledSignInError = @"The user canceled the sign-in flow.";
static NSString *const kUserCanceledVerifyError = @"The user canceled the verification flow.";


static NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;

@implementation GIDAuthorizationResponseHelper {
  OIDAuthorizationResponse *_authorizationResponse;
  NSString *_emmSupport;
  GIDFlowName _flowName;
}

- (instancetype)
    initWithAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                       emmSupport:(NSString *)emmSupport
                         flowName:(GIDFlowName)flowName
                    configuration:(GIDConfiguration *)configuration {
  self = [super init];
  if (self) {
    _authorizationResponse = authorizationResponse;
    _emmSupport = emmSupport;
    _flowName = flowName;
    _configuration = configuration;
  }
}

- (GIDAuthFlow *)processWithError:(NSError *)error {
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];
  authFlow.emmSupport = _emmSupport;

  if (_authorizationResponse) {
    if (_authorizationResponse.authorizationCode.length) {
      authFlow.authState =
          [[OIDAuthState alloc] initWithAuthorizationResponse:_authorizationResponse];
      [self maybeFetchToken:authFlow];
    } else {
      [self authorizationCodeErrorWithAuthFlow:authFlow];
    }
  } else {
    [self authorizationResponseErrorWithAuthFlow:authFlow
                                           error:error];
  }
  return authFlow;
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
  if (_configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = _configuration.serverClientID;
  }
  if (_configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = _configuration.openIDRealm;
  }

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  if (_flowName == SignIn) {
    NSDictionary<NSString *, NSObject *> *params =
        authState.lastAuthorizationResponse.additionalParameters;
    NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
    [additionalParameters addEntriesFromDictionary:
        [GIDEMMSupport parametersWithParameters:@{}
                                     emmSupport:authFlow.emmSupport
                         isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
  }
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

- (void)authorizationCodeErrorWithAuthFlow:(GIDAuthFlow *)authFlow {
  // There was a failure, convert to appropriate error code.
  NSDictionary<NSString *, NSObject *> *params = _authorizationResponse.additionalParameters;
  NSString *errorString = (NSString *)params[kOAuth2ErrorKeyName];

  switch (_flowName) {
    case SignIn: {
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
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

      if ([errorString isEqualToString:kOAuth2AccessDenied]) {
        errorCode = kGIDSignInErrorCodeCanceled;
      }

      authFlow.error = [self errorWithString:errorString code:errorCode];
    }
      break;
    case Verify: {
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      GIDVerifyErrorCode errorCode = kGIDVerifyErrorCodeUnknown;
      if ([errorString isEqualToString:kOAuth2AccessDenied]) {
        errorCode = kGIDVerifyErrorCodeCanceled;
      }

      authFlow.error = [self errorWithString:errorString code:errorCode];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      break;
    }
  }
}

- (void)authorizationResponseErrorWithAuthFlow:(GIDAuthFlow *)authFlow
                                         error:(NSError *)error {
  NSString *errorString = [error localizedDescription];
  switch (_flowName) {
    case SignIn: {
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow) {
        // The user has canceled the flow at the iOS modal dialog.
        errorString = kUserCanceledSignInError;
        errorCode = kGIDSignInErrorCodeCanceled;
      }
      authFlow.error = [self errorWithString:errorString code:errorCode];
      break;
    }
    case Verify: {
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      GIDVerifyErrorCode errorCode = kGIDVerifyErrorCodeUnknown;
      if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow) {
        errorString = kUserCanceledVerifyError;
        errorCode = kGIDVerifyErrorCodeCanceled;
      }

      authFlow.error = [self errorWithString:errorString code:errorCode];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      break;
    }
  }
}

- (NSError *)errorWithString:(nullable NSString *)errorString code:(NSInteger)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  switch (_flowName) {
    case SignIn:
      return [NSError errorWithDomain:kGIDSignInErrorDomain
                                 code:code
                             userInfo:errorDict];
      break;
    case Verify:
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      return [NSError errorWithDomain:kGIDVerifyErrorDomain
                                 code:code
                             userInfo:errorDict];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      break;
  }
}

@end
