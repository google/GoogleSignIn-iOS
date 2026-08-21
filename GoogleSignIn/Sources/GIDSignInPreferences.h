/*
 * Copyright 2021 Google LLC
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

extern NSString *const kSDKVersionLoggingParameter;
extern NSString *const kEnvironmentLoggingParameter;
extern NSString *const kSDKWrapperLoggingParameter;

@interface GIDSignInPreferences : NSObject

/// Returns the current Google Sign-In SDK version, prefixed so that `gid` version values can
/// be distinguished from other values reported under the legacy `gpsdk` logging key.
+ (NSString *)sdkVersion;

/// Returns the current Apple execution environment, such as `ios` or `macos`.
+ (NSString *)environment;

/// Returns the current SDK wrapper identifier, or `nil` if none has been accepted.
+ (nullable NSString *)wrapperIdentifier;

/// Sets the SDK wrapper identifier; a `nil` argument is ignored. See
/// `GIDSignIn.wrapperIdentifier` for the accepted format, validation, and first-write-wins
/// semantics. Thread-safe.
+ (void)setWrapperIdentifier:(nullable NSString *)wrapperIdentifier;

/// Clears any stored SDK wrapper identifier. Intended for unit tests, which must restore
/// process state between cases; production callers should not need it, and clearing defeats
/// the first-write-wins rule. Thread-safe.
+ (void)resetWrapperIdentifier;

/// Returns the standard logging parameters sent with requests to Google's servers: the SDK
/// version and execution environment, plus the wrapper identifier when one is set.
+ (NSDictionary<NSString *, NSString *> *)loggingParameters;

+ (NSString *)googleAuthorizationServer;
+ (NSString *)googleTokenServer;
+ (NSString *)googleUserInfoServer;

@end

NS_ASSUME_NONNULL_END
