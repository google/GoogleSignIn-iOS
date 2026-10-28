/*
 * Copyright 2026 Google LLC
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

#import "GoogleSignIn/Sources/GIDLocalAuthentication/API/GIDLocalAuthenticationContext.h"

NS_ASSUME_NONNULL_BEGIN

/// An in-memory `GIDLocalAuthenticationContext` for tests.
@interface GIDFakeLocalAuthenticationContext : NSObject <GIDLocalAuthenticationContext>

/// The value `-canEvaluatePolicy:error:` returns. Defaults to YES.
@property(nonatomic) BOOL canEvaluatePolicyResult;

/// The error `-canEvaluatePolicy:error:` reports, if any. Defaults to nil.
@property(nonatomic, nullable) NSError *canEvaluatePolicyError;

/// Every policy passed to `-canEvaluatePolicy:error:`, in call order, boxed as `NSNumber`.
@property(nonatomic, readonly) NSArray<NSNumber *> *evaluatedPolicies;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
