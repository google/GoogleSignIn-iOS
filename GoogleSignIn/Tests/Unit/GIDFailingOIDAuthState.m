/*
 * Copyright 2023 Google LLC
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

#import "GIDFailingOIDAuthState.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

@implementation GIDFailingOIDAuthState

+ (instancetype)testInstance {
  OIDAuthorizationResponse *testAuthResponse = [OIDAuthorizationResponse testInstance];
  OIDTokenResponse *testTokenResponse = [OIDTokenResponse testInstance];

  return [[GIDFailingOIDAuthState alloc] initWithAuthorizationResponse:testAuthResponse
                                                         tokenResponse:testTokenResponse];
}

- (void)performActionWithFreshTokens:(OIDAuthStateAction)action
         additionalRefreshParameters:
    (nullable NSDictionary<NSString *, NSString *> *)additionalParameters {
  [self performActionWithFreshTokens:action
         additionalRefreshParameters:additionalParameters
                       dispatchQueue:dispatch_get_main_queue()];
}

// Forces the OIDAuthState to fail with the error below to simulate an error handled by EMM support
- (void)performActionWithFreshTokens:(OIDAuthStateAction)action
         additionalRefreshParameters:(NSDictionary<NSString *,NSString *> *)additionalParameters
                       dispatchQueue:(dispatch_queue_t)dispatchQueue {
  NSDictionary<NSString *, id> *userInfo = @{
    @"OIDOAuthErrorResponseErrorKey": @{@"error": @"emm_passcode_required"},
    NSUnderlyingErrorKey: [NSError errorWithDomain:@"SomeUnderlyingError" code:0 userInfo:nil]
  };
  NSError *error = [NSError errorWithDomain:@"org.openid.appauth.resourceserver"
                                       code:0
                                   userInfo:userInfo];
  action(nil, nil, error);
}

@end
