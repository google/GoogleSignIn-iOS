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

// This convolved list of C macros is needed because the Xcode project generated
// by blaze build and the command itself have inconsistent escaping of the
// quotation marks in -D flags, which makes passing '"' as part of the macro
// value impossible.
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

// The name of the query parameter used for logging the SDK version.
NSString *const kSDKVersionLoggingParameter = @"gpsdk";

// The prefixed sdk version string to differentiate gid version values used with the legacy gpsdk
// logging key.
NSString* GIDVersion(void) {
  return [NSString stringWithFormat:@"gid-%s",(const char* const)STR(GID_SDK_VERSION)];
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
