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

#if TARGET_OS_IOS

@implementation GIDVerifyAccountDetail

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
  NSBundle *bundle = NSBundle.mainBundle;
  if (bundle) {
    _configuration = [GIDConfiguration configurationFromBundle:bundle];
  }

  GIDSignInInternalOptions *options =
  [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
                                   presentingViewController:presentingViewController
                                                  loginHint:hint
                                              addScopesFlow:YES
                                     accountDetailsToVerify:accountDetails
                                           verifyCompletion:completion];

  [self verifyAccountDetailsInteractivelyWithOptions:options];
}

- (void)verifyAccountDetailsInteractivelyWithOptions:(GIDSignInInternalOptions *)options {
  // TODO(#397): Sanity checks and start the incremental authorization flow.
}

@end

#endif // TARGET_OS_IOS
