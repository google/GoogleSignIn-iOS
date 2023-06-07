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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FIRAppCheckToken;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@protocol GIDAppCheckProvider <NSObject>

/// Get the limited use `FIRAppCheckToken`.
///
/// @param completion A block that passes back the `FIRAppCheckToken` upon success or an error in
///     the case of any failure.
- (void)limitedUseTokenWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable token,
                                                         NSError * _Nullable error))completion;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END
