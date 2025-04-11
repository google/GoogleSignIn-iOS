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

#import "GIDTokenFetchOperation.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#endif

@implementation GIDTokenFetchOperation

- (instancetype)initWithAuthState:(nullable OIDAuthState *)authState
                          options:(nullable GIDSignInInternalOptions *)options
                       emmSupport:(nullable NSString *)emmSupport
                            error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _authState = authState;
    _options = options;
    _emmSupport = emmSupport;
    _error = error;
  }
}

- (void)main {
  // Do nothing if we have an auth flow error or a restored access token that isn't near expiration.
  if (self.error ||
      (self.authState.lastTokenResponse.accessToken &&
        [self.authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
        kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }
  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
    [[NSMutableDictionary alloc] init];
  if (self.options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = self.options.configuration.serverClientID;
  }
  if (self.options.configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = self.options.configuration.openIDRealm;
  }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSDictionary<NSString *, NSObject *> *params =
      self.authState.lastAuthorizationResponse.additionalParameters;
  NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:@{}
                                   emmSupport:self.emmSupport
                       isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  OIDTokenRequest *tokenRequest;
  if (!self.authState.lastTokenResponse.accessToken &&
      self.authState.lastAuthorizationResponse.authorizationCode) {
    tokenRequest = [self.authState.lastAuthorizationResponse
        tokenExchangeRequestWithAdditionalParameters:additionalParameters];
  } else {
    [additionalParameters
        addEntriesFromDictionary:self.authState.lastTokenResponse.request.additionalParameters];
    tokenRequest = [self.authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  }

  [OIDAuthorizationService performTokenRequest:tokenRequest
                 originalAuthorizationResponse:self.authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    [self.authState updateWithTokenResponse:tokenResponse error:error];
    self.error = error;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    if (self.emmSupport) {
      [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *error) {
        self.error = error;
      }];
    }
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  }];
}

@end
