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

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@class FIRAppCheckToken;

/// A list of potential error codes returned from the Google Sign-In SDK during App Check.
typedef NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDAppCheckErrorCode) {
  /// An unexpected error was encountered.
  kGIDAppCheckUnexpectedError = 1,
  /// `GIDAppCheck` has already performed the key generation and attestation steps.
  kGIDAppCheckAlreadyPrepared = 2,
};

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheck : NSObject

/// Creates the instance of this App Check wrapper class.
///
/// If `provider` is nil, then we default to `FIRAppCheck`.
///
/// @param provider The instance performing the Firebase App Check requeests.
- (instancetype)initWithAppCheckProvider:(nullable id<GIDAppCheckProvider>)provider
    NS_DESIGNATED_INITIALIZER;

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
@property(nonatomic, readonly, getter=isPrepared) BOOL prepared;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END

