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

// Returns the current Google Sign-In SDK version.
+ (NSString *)sdkVersion;

// Returns the current Apple execution environment (e.g. ios, macos).
+ (NSString *)environment;

// Returns the current identifier, or nil if none is set.
+ (nullable NSString *)wrapperIdentifier;

// Sets the SDK wrapper identifier. Values may be up to 100 printable ASCII characters; longer
// values are truncated to 100; a value containing any non-ASCII or control character, or an empty
// string, is dropped entirely (and asserts in debug builds); the first accepted write wins and
// later differing writes are ignored; nil resets; the method is thread-safe.
+ (void)setWrapperIdentifier:(nullable NSString *)wrapperIdentifier;

// Populates the standard logging parameters (gpsdk, gidenv, and gidwrapper when set) on the
// supplied dictionary.
+ (void)addLoggingParameters:(NSMutableDictionary<NSString *, NSString *> *)params;

+ (NSString *)googleAuthorizationServer;
+ (NSString *)googleTokenServer;
+ (NSString *)googleUserInfoServer;

@end

NS_ASSUME_NONNULL_END
