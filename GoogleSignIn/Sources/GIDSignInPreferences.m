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

/// Parameters for the auth and token exchange endpoints.
NSString *const kAudienceParameter = @"audience";
NSString *const kIncludeGrantedScopesParameter = @"include_granted_scopes";
NSString *const kLoginHintParameter = @"login_hint";
NSString *const kHostedDomainParameter = @"hd";
NSString *const kSDKVersionLoggingParameter = @"gpsdk";
NSString *const kEnvironmentLoggingParameter = @"gidenv";
NSString *const kOpenIDRealmParameter = @"openid.realm";

NSString *const kBrowserCallbackPath = @"/oauth2callback";

// Parameters in the callback URL coming back from browser.
NSString *const kOAuth2ErrorKeyName = @"error";
NSString *const kOAuth2AccessDenied = @"access_denied";
NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

static NSString *const kLSOServer = @"accounts.google.com";
static NSString *const kTokenServer = @"oauth2.googleapis.com";
static NSString *const kUserInfoServer = @"www.googleapis.com";

// Supported Apple execution environments
static NSString *const kAppleEnvironmentUnknown = @"unknown";
static NSString *const kAppleEnvironmentIOS = @"ios";
static NSString *const kAppleEnvironmentIOSSimulator = @"ios-sim";
static NSString *const kAppleEnvironmentMacOS = @"macos";
static NSString *const kAppleEnvironmentMacOSIOSOnMac = @"macos-ios";
static NSString *const kAppleEnvironmentMacOSMacCatalyst = @"macos-cat";

// The URL template for the authorization endpoint.
static NSString *const kAuthorizationURLTemplate = @"https://%@/o/oauth2/v2/auth";

// The URL template for the token endpoint.
static NSString *const kTokenURLTemplate = @"https://%@/token";

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

+ (NSURL *)authorizationEndpointURL {
  NSString *authorizationEnpointURL = [NSString stringWithFormat:kAuthorizationURLTemplate,
      [self googleAuthorizationServer]];
  return [NSURL URLWithString:authorizationEnpointURL];
}

+ (NSURL *)tokenEndpointURL {
  NSString *tokenEndpointURL = [NSString stringWithFormat:kTokenURLTemplate,
      [self googleTokenServer]];
  return [NSURL URLWithString:tokenEndpointURL];
}

@end

NS_ASSUME_NONNULL_END
