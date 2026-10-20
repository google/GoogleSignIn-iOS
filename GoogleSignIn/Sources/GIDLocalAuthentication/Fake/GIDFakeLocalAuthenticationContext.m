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

#import "GoogleSignIn/Sources/GIDLocalAuthentication/Fake/GIDFakeLocalAuthenticationContext.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDFakeLocalAuthenticationContext {
  // Every policy passed to `-canEvaluatePolicy:error:`, in call order.
  NSMutableArray<NSNumber *> *_evaluatedPolicies;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _canEvaluatePolicyResult = YES;
    _evaluatedPolicies = [NSMutableArray array];
  }
  return self;
}

- (NSArray<NSNumber *> *)evaluatedPolicies {
  return [_evaluatedPolicies copy];
}

- (BOOL)canEvaluatePolicy:(LAPolicy)policy error:(NSError * _Nullable * _Nullable)error {
  [_evaluatedPolicies addObject:@(policy)];
  if (error) {
    *error = self.canEvaluatePolicyError;
  }
  return self.canEvaluatePolicyResult;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
