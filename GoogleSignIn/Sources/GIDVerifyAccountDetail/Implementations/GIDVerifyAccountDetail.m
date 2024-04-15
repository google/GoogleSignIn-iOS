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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiedAccountDetailResult.h"

#if TARGET_OS_IOS

@implementation GIDVerifyAccountDetail

- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion {
  // TODO(#383): Implement this method.
}

- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion {
  // TODO(#383): Implement this method.
}

- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
            additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion {
  // TODO(#383): Implement this method.
}

@end

#endif // TARGET_OS_IOS
