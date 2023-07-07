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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@protocol GIDAppCheckTokenFetcher;
@class FIRAppCheckToken;

/// Interface providing the API for both pre-warming `GIDSignIn` to use Firebase App Check and
/// fetching the App Check token.
NS_AVAILABLE_IOS(14)
@protocol GIDAppCheckProvider <NSObject>

/// Creates the instance of this App Check wrapper class.
///
/// @param tokenFetcher The instance performing the Firebase App Check token requests. If `provider`
///     is nil, then we default to `FIRAppCheck`.
/// @param userDefaults The instance of `NSUserDefaults` that `GIDAppCheck` will use to store its
///     preparation status. If nil, `GIDAppCheck` will use `-[NSUserDefaults standardUserDefaults]`.
- (instancetype)initWithAppCheckTokenFetcher:(nullable id<GIDAppCheckTokenFetcher>)tokenFetcher
                                userDefaults:(nullable NSUserDefaults *)userDefaults;

/// Prewarms the library for App Check by asking Firebase App Check to generate the App Attest key
/// id and perform the initial attestation process (if needed).
///
/// @param completion A `nullable` callback with the `FIRAppCheckToken` if present, or an `NSError`
///     otherwise.
- (void)prepareForAppCheckWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable token,
                                                            NSError * _Nullable error))completion;

/// Fetches the limited use Firebase token.
///
/// @param completion A `nullable` callback with the `FIRAppCheckToken` if present, or an `NSError`
///     otherwise.
- (void)getLimitedUseTokenWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable token,
                                                            NSError * _Nullable error))completion;

/// Whether or not the App Attest key ID created and the attestation object has been fetched.
- (BOOL)isPrepared;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END
