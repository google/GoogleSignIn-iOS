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

/// Returns the current Google Sign-In SDK version.
+ (NSString *)sdkVersion;

/// Returns the current Apple execution environment, such as `ios` or `macos`.
+ (NSString *)environment;

/// Returns the current SDK wrapper identifier, or `nil` if none is set.
+ (nullable NSString *)wrapperIdentifier;

/// Sets the SDK wrapper identifier.
///
/// A value may be up to 100 printable ASCII characters; a longer value is truncated to its first
/// 100 characters. A value that is empty, or that contains any non-ASCII or ASCII control
/// character, is dropped entirely and asserts in debug builds.
///
/// The first accepted write wins; later differing writes are ignored. This method is thread-safe.
///
/// @param wrapperIdentifier The identifier to report, or `nil` to reset it.
+ (void)setWrapperIdentifier:(nullable NSString *)wrapperIdentifier;

/// Adds the standard logging parameters to the supplied dictionary.
///
/// The parameters are `gpsdk`, `gidenv`, and, when a wrapper identifier is set, `gidwrapper`.
///
/// @param params The dictionary to add the logging parameters to.
+ (void)addLoggingParameters:(NSMutableDictionary<NSString *, NSString *> *)params;

+ (NSString *)googleAuthorizationServer;
+ (NSString *)googleTokenServer;
+ (NSString *)googleUserInfoServer;

@end

NS_ASSUME_NONNULL_END
