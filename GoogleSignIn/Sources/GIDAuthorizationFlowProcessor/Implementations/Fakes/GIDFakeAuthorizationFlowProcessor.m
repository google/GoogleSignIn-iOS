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

#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/Fakes/GIDFakeAuthorizationFlowProcessor.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

@implementation GIDFakeAuthorizationFlowProcessor

- (void)startWithOptions:(GIDSignInInternalOptions *)options
              emmSupport:(nullable NSString *)emmSupport
              completion:(void (^)(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                   NSError *_Nullable error))completion {
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  
  self.testBlock(^(OIDAuthorizationResponse *authorizationResponse, NSError *error) {
    completion(authorizationResponse, error);
  });
}

- (BOOL)isStarted {
  NSAssert(NO, @"Not implemented.");
  return YES;
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)url {
  NSAssert(NO, @"Not implemented.");
  return YES;
}

- (void)cancelAuthenticationFlow {
  NSAssert(NO, @"Not implemented.");
}

@end
