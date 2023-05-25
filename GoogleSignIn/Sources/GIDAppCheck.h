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

@interface GIDAppCheck : NSObject

///:nodoc:
- (instancetype)init NS_UNAVAILABLE;

/// Prewarms the library for App Attest by asking Firebase App Check to generate the App Attest key
/// id and perform the initial attestation process (if needed).
- (void)prepareForAppAttest;

/// Fetches the limited use Firebase token.
/// @param completion: A `nullable` callback with the `FIRAppCheckToken` if present, or an `NSError`
/// otherwise.
- (void)getLimitedUseTokenWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable token,
                                                            NSError * _Nullable error))completion;

/// The shared instance of this App Check wrapper class.
@property(class, nonatomic, strong, readonly) GIDAppCheck *sharedInstance;

/// Whether or not the App Attest key ID created and the attestation object has been fetched.
@property(nonatomic, readonly, getter=isPrepared) BOOL prepared;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END

