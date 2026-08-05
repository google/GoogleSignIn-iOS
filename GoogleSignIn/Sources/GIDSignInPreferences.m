// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kLSOServer = @"accounts.google.com";
static NSString *const kTokenServer = @"oauth2.googleapis.com";
static NSString *const kUserInfoServer = @"www.googleapis.com";

// The name of the query parameter used for logging the SDK version.
NSString *const kSDKVersionLoggingParameter = @"gpsdk";

// The name of the query parameter used for logging the Apple execution environment.
NSString *const kEnvironmentLoggingParameter = @"gidenv";

// The name of the query parameter used to log the embedding SDK / wrapper.
NSString *const kSDKWrapperLoggingParameter = @"gidwrapper";

// Supported Apple execution environments
static NSString *const kAppleEnvironmentUnknown = @"unknown";
static NSString *const kAppleEnvironmentIOS = @"ios";
static NSString *const kAppleEnvironmentIOSSimulator = @"ios-sim";
static NSString *const kAppleEnvironmentMacOS = @"macos";
static NSString *const kAppleEnvironmentMacOSIOSOnMac = @"macos-ios";
static NSString *const kAppleEnvironmentMacOSMacCatalyst = @"macos-cat";

static NSString *gWrapperIdentifier = nil;

static NSObject* GIDWrapperLock(void) {
  static NSObject *lock;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lock = [[NSObject alloc] init];
  });
  return lock;
}

#ifndef GID_SDK_VERSION
#error "GID_SDK_VERSION is not defined: add -DGID_SDK_VERSION=x.x.x to the build invocation."
#endif

// Because macro expansions aren't performed on a token following the # preprocessor operator, we
// wrap STR_EXPAND(x) with the STR(x) to produce a quoted string representation of a macro.
// https://www.guyrutenberg.com/2008/12/20/expanding-macros-into-string-constants-in-c/
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

// The prefixed sdk version string to differentiate gid version values used with the legacy gpsdk
// logging key.
NSString* GIDVersion(void) {
  return [NSString stringWithFormat:@"gid-%@", @STR(GID_SDK_VERSION)];
}

// Get the current Apple execution environment.
NSString* GIDEnvironment(void) {
  NSString *appleEnvironment = kAppleEnvironmentUnknown;

#if TARGET_OS_MACCATALYST
  appleEnvironment = kAppleEnvironmentMacOSMacCatalyst;
#elif TARGET_OS_IOS
#if TARGET_OS_SIMULATOR
  appleEnvironment = kAppleEnvironmentIOSSimulator;
#else // TARGET_OS_SIMULATOR
#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
  if (@available(iOS 14.0, *)) {
    if ([NSProcessInfo.processInfo respondsToSelector:@selector(isiOSAppOnMac)]) {
      appleEnvironment = NSProcessInfo.processInfo.iOSAppOnMac ? kAppleEnvironmentMacOSIOSOnMac :
          kAppleEnvironmentIOS;
    } else {
      appleEnvironment = kAppleEnvironmentIOS;
    }
  }
#else // defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
  appleEnvironment = kAppleEnvironmentIOS;
#endif // defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
#endif // TARGET_OS_SIMULATOR
#elif TARGET_OS_OSX
  appleEnvironment = kAppleEnvironmentMacOS;
#endif // TARGET_OS_MACCATALYST

  return appleEnvironment;
}

static NSString * _Nullable GIDSanitizeWrapperIdentifier(NSString * _Nullable raw) {
  if (!raw) {
    return nil;
  }

  // Trim leading/trailing whitespace and newlines.
  NSString *sanitized = [raw stringByTrimmingCharactersInSet:
      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (sanitized.length == 0) {
    return nil;
  }

  // Lowercase (locale-independent).
  sanitized = [sanitized lowercaseString];

  // Keep only characters in the allowlist [A-Za-z0-9-._~]; drop everything else.
  NSCharacterSet *allowed =
      [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789-._~"];
  sanitized = [[sanitized componentsSeparatedByCharactersInSet:[allowed invertedSet]]
      componentsJoinedByString:@""];

  if (sanitized.length == 0) {
    return nil;
  }

  // If length > 32, take substringToIndex:32.
  // Safe because the allowlist is ASCII, so each character is exactly one UTF-16 unit.
  if (sanitized.length > 32) {
    sanitized = [sanitized substringToIndex:32];
  }

  return sanitized;
}

NSString* GIDWrapperIdentifier(void) {
  @synchronized(GIDWrapperLock()) {
    return [gWrapperIdentifier copy];
  }
}

void GIDSetWrapperIdentifier(NSString * _Nullable wrapper) {
  NSString *sanitized = GIDSanitizeWrapperIdentifier(wrapper);
  @synchronized(GIDWrapperLock()) {
    gWrapperIdentifier = [sanitized copy];
  }
}

@implementation GIDSignInPreferences

+ (NSString *)googleAuthorizationServer {
  return kLSOServer;
}

+ (NSString *)googleTokenServer {
  return kTokenServer;
}

+ (NSString *)googleUserInfoServer {
  return kUserInfoServer;
}

@end

NS_ASSUME_NONNULL_END
