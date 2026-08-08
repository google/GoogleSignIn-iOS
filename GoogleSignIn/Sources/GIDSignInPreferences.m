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

#import <os/lock.h>

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
static os_unfair_lock gWrapperIdentifierLock = OS_UNFAIR_LOCK_INIT;

#ifndef GID_SDK_VERSION
#error "GID_SDK_VERSION is not defined: add -DGID_SDK_VERSION=x.x.x to the build invocation."
#endif

// Because macro expansions aren't performed on a token following the # preprocessor operator, we
// wrap STR_EXPAND(x) with the STR(x) to produce a quoted string representation of a macro.
// https://www.guyrutenberg.com/2008/12/20/expanding-macros-into-string-constants-in-c/
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

// Returns the sanitized form of `candidate`, or nil if it must be dropped.
// Callers must not pass nil.
static NSString * _Nullable GIDSanitizedWrapperIdentifier(NSString *candidate) {
  static NSCharacterSet *allowedSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // The range of printable ASCII characters is U+0020 through U+007E inclusive.
    allowedSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x20, 0x5F)];
  });

  // The drop check happens before truncation: if the original string contains any character
  // outside the printable ASCII range, we drop the entire value.
  if ([candidate rangeOfCharacterFromSet:[allowedSet invertedSet]].location != NSNotFound) {
    return nil;
  }

  // An empty string is also discarded.
  if (candidate.length == 0) {
    return nil;
  }

  // A surviving string longer than 100 characters is truncated to 100.
  if (candidate.length > 100) {
    // Truncating with -substringToIndex:100 is safe here precisely because the drop check has
    // already guaranteed every character is single-unit ASCII, so there is no risk of splitting
    // a surrogate pair.
    return [candidate substringToIndex:100];
  }

  return candidate;
}

@implementation GIDSignInPreferences

+ (NSString *)sdkVersion {
  return [NSString stringWithFormat:@"gid-%@", @STR(GID_SDK_VERSION)];
}

+ (NSString *)environment {
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

+ (nullable NSString *)wrapperIdentifier {
  os_unfair_lock_lock(&gWrapperIdentifierLock);
  NSString *wrapper = [gWrapperIdentifier copy];
  os_unfair_lock_unlock(&gWrapperIdentifierLock);
  return wrapper;
}

+ (void)setWrapperIdentifier:(nullable NSString *)wrapperIdentifier {
  if (wrapperIdentifier == nil) {
    os_unfair_lock_lock(&gWrapperIdentifierLock);
    gWrapperIdentifier = nil;
    os_unfair_lock_unlock(&gWrapperIdentifierLock);
    return;
  }

  NSString *sanitized = GIDSanitizedWrapperIdentifier(wrapperIdentifier);
  if (sanitized == nil) {
#if DEBUG
    NSAssert(NO, @"SDK wrapper '%@' rejected: must not be empty and must only contain printable "
                 @"ASCII characters (U+0020 to U+007E). Value ignored.", wrapperIdentifier);
#endif
    return;
  }

  os_unfair_lock_lock(&gWrapperIdentifierLock);
  NSString *current = gWrapperIdentifier;
  if (current != nil && ![current isEqualToString:sanitized]) {
    os_unfair_lock_unlock(&gWrapperIdentifierLock);
#if DEBUG
    NSAssert(NO, @"SDK wrapper already set to '%@'; ignoring '%@'. More than one "
                 @"wrapper appears to be present.", current, sanitized);
#endif
    return;
  }
  gWrapperIdentifier = [sanitized copy];
  os_unfair_lock_unlock(&gWrapperIdentifierLock);
}

+ (void)addLoggingParameters:(NSMutableDictionary<NSString *, NSString *> *)params {
  params[kSDKVersionLoggingParameter] = [self sdkVersion];
  params[kEnvironmentLoggingParameter] = [self environment];
  NSString *wrapper = [self wrapperIdentifier];
  if (wrapper != nil) {
    params[kSDKWrapperLoggingParameter] = wrapper;
  }
}

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
