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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Fake/GIDAuthorizationResponseHandlingFake.h"

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/API/GIDAuthorizationResponseHandling.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDTokenResponse.h>
#endif

@implementation GIDAuthorizationResponseHandlingFake

- (instancetype)initWithAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse 
                                   emmSupport:(NSString *)emmSupport
                                     flowName:(enum GIDFlowName)flowName
                                configuration:(GIDConfiguration *)configuration
                                        error:(NSError *)error {
  self = [super init];
  if (self) {
    NSAssert(false, @"This class is only to be used in testing. Do not use.");
  }
  return self;
}

- (instancetype)initWithAuthState:(nullable OIDAuthState *)authState
                            error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _authState = authState;
    _error = error;
  }
  return self;
}

- (GIDAuthFlow *)generateAuthFlowFromAuthorizationResponse {
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:self.authState
                                                           error:self.error
                                                      emmSupport:nil
                                                     profileData:nil];
  return authFlow;
}

- (void)maybeFetchToken:(GIDAuthFlow *)authFlow {
  if (authFlow.error ||
      (_authState.lastTokenResponse.accessToken &&
       [_authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
       kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }

  authFlow.authState = self.authState;
  authFlow.error = self.error;
}

@end

