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

#import <Foundation/Foundation.h>

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/API/GIDAuthorizationResponseHandling.h"

NS_ASSUME_NONNULL_BEGIN

@class OIDAuthState;

/// A fake implementation of `GIDAuthorizationResponseHandling` for testing purposes.
@interface GIDAuthorizationResponseHandlingFake : NSObject <GIDAuthorizationResponseHandling>

/// The auth state to be used to fetch tokens.
@property (nonatomic, nullable) OIDAuthState *authState;

/// The error to be passed into the completion.
@property (nonatomic, nullable) NSError *error;

/// Creates an instance conforming to `GIDAuthorizationResponseHandling` with the provided
/// auth state and error.
///
/// @param authState The `OIDAuthState` instance to access tokens.
/// @param error The `NSError` to pass into the completion.
- (instancetype)initWithAuthState:(nullable OIDAuthState *)authState
                            error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
