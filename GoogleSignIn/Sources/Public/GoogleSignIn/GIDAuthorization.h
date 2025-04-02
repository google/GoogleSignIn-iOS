/*
 * Copyright 2025 Google LLC
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

@class GIDConfiguration;
@class GIDGoogleUser;

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthorization : NSObject

/// Initializer used to create an instance of `GIDAuthorization`.
///
/// This initializer will generate a default `GIDConfiguration` using values from your `Info.plist`.
- (instancetype)init;

/// Initializer used to create an instance of `GIDAuthorization`.
///
/// This initializer will generate a default `GIDConfiguration` using values from your `Info.plist`.
- (instancetype)initWithConfiguration:(GIDConfiguration *)configuration;

/// Checks if there is a current user or a previous sign in.
///
/// - Returns: A `BOOL` if there was a previous sign in.
- (BOOL)hasPreviousSignIn;

/// The current user managed by Google Sign-In.
///
/// - Note: The current user will be nil if there is no current user.
@property(nonatomic, readonly, nullable) GIDGoogleUser *currentUser;

@end

NS_ASSUME_NONNULL_END
