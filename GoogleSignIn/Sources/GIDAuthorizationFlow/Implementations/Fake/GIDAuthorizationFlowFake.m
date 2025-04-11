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

#import "GIDAuthorizationFlowFake.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignInResult.h"
#import "GoogleSignIn/Sources/GIDSignInResult_Private.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDConfiguration_Private.h"

@implementation GIDAuthorizationFlowFake

- (instancetype)initWithSignInOptions:(GIDSignInInternalOptions *)options
                            authState:(OIDAuthState *)authState
                          profileData:(nullable GIDProfileData *)profileData
                           googleUser:(nullable GIDGoogleUser *)googleUser
             externalUserAgentSession:(nullable id<OIDExternalUserAgentSession>)userAgentSession
                           emmSupport:(nullable NSString *)emmSupport
                                error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _options = options;
    _authState = authState;
    _profileData = profileData;
    _googleUser = googleUser;
    _currentUserAgentSession = userAgentSession;
    _error = error;
    _emmSupport = emmSupport;
  }
  return self;
}
- (void)authorize {
  // TODO: Implement
}

- (void)authorizeInteractively {
  GIDSignInResult *result = [[GIDSignInResult alloc] initWithGoogleUser:self.googleUser
                                                         serverAuthCode:@"abcd"];
  self.options.completion(result, self.error);
}

@end
