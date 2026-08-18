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

/// Returns the current SDK wrapper identifier, or `nil` if none is set.
+ (nullable NSString *)wrapperIdentifier;

/// Sets the SDK wrapper identifier.
///
/// A value may be up to 100 printable ASCII characters; a longer value is truncated to its first
/// 100 characters. A value that is empty, or that contains any non-ASCII or ASCII control
/// character, is dropped entirely.
///
/// A nil argument is ignored. A value that is rejected, or that conflicts with an already-stored
/// value, is logged rather than asserted.
///
/// The first accepted write wins; later differing writes are ignored. This method is thread-safe.
///
/// @param wrapperIdentifier The identifier to report.
+ (void)setWrapperIdentifier:(nullable NSString *)wrapperIdentifier;

/// Resets the SDK wrapper identifier.
///
/// This exists solely so unit tests can restore process state between cases. Production code
/// must not call it.
+ (void)resetWrapperIdentifierForTesting;

/// Returns the standard logging parameters to send with requests to Google's servers.
///
/// The parameters are `gpsdk`, `gidenv`, and, when a wrapper identifier is set, `gidwrapper`.
+ (NSDictionary<NSString *, NSString *> *)loggingParameters;

+ (NSString *)googleAuthorizationServer;
+ (NSString *)googleTokenServer;
+ (NSString *)googleUserInfoServer;

@end

NS_ASSUME_NONNULL_END
