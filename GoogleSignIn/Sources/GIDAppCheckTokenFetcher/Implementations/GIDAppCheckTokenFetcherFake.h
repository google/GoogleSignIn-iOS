// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/GIDAppCheckTokenFetcher/API/GIDAppCheckTokenFetcher.h"

@class FIRAppCheckToken;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const kGIDAppCheckTokenFetcherTokenError;

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheckTokenFetcherFake : NSObject <GIDAppCheckTokenFetcher>

/// Creates an instance with the provided app check token and error.
///
/// This protocol is mainly used for testing purposes so that the token fetching from Firebase App
/// Check can be faked.
/// @param token The `FIRAppCheckToken` to pass into the completion called from
/// `limitedUseTokenWithCompletion:`.
/// @param error The `NSError` to pass into the completion called from
/// `limitedUseTokenWithCompletion:`.
- (instancetype)initWithAppCheckToken:(nullable FIRAppCheckToken *)token
                                error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
