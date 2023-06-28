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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/GIDAppCheck/API/GIDAppCheckProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class FIRAppCheckToken;

/// A list of potential error codes returned from the Google Sign-In SDK during App Check.
typedef NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDAppCheckErrorCode) {
  /// An unexpected error was encountered.
  kGIDAppCheckUnexpectedError = 1,
  /// `GIDAppCheck` has already performed the key generation and attestation steps.
  kGIDAppCheckAlreadyPrepared = 2,
};

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheck : NSObject <GIDAppCheckProvider>

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
