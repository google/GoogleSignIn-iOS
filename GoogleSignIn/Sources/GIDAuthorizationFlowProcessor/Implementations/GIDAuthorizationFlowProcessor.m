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

#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/GIDAuthorizationFlowProcessor.h"

#import "GoogleSignIn/Sources/GIDAuthorizationUtil.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthorizationFlowProcessor ()

/// AppAuth external user-agent session state.
@property(nonatomic, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end

@implementation GIDAuthorizationFlowProcessor

# pragma mark - Public API

- (BOOL)isStarted {
  return self.currentAuthorizationFlow != nil;
}

- (void)startWithOptions:(GIDSignInInternalOptions *)options
              emmSupport:(nullable NSString *)emmSupport
              completion:(void (^)(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                   NSError *_Nullable error))completion {
  OIDAuthorizationRequest *request =
      [GIDAuthorizationUtil authorizationRequestWithOptions:options
                                                 emmSupport:emmSupport];
  
  _currentAuthorizationFlow = [OIDAuthorizationService
      presentAuthorizationRequest:request
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
         presentingViewController:options.presentingViewController
#elif TARGET_OS_OSX
                 presentingWindow:options.presentingWindow
#endif // TARGET_OS_OSX
                         callback:^(OIDAuthorizationResponse *authorizationResponse,
                                    NSError *error) {
    completion(authorizationResponse, error);
  }];
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)url {
  if ([self.currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
    self.currentAuthorizationFlow = nil;
    return YES;
  } else {
    return NO;
  }
}

- (void)cancelAuthenticationFlow {
  [self.currentAuthorizationFlow cancel];
  self.currentAuthorizationFlow = nil;
}

@end

NS_ASSUME_NONNULL_END
