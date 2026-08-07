// Copyright 2022 Google LLC
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

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

@interface GIDSignInPreferencesTest : XCTestCase
@end

@implementation GIDSignInPreferencesTest

- (void)testSDKVersion {
  NSString *version = [GIDSignInPreferences sdkVersion];
  XCTAssertTrue([version hasPrefix:@"gid-"]);
}

- (void)testEnvironment {
  NSString *environment = [GIDSignInPreferences environment];

  NSString *expectedEnvironment;
#if TARGET_OS_MACCATALYST
  expectedEnvironment = @"macos-cat";
#elif TARGET_OS_IOS
#if TARGET_OS_SIMULATOR
  expectedEnvironment = @"ios-sim";
#else
  expectedEnvironment = @"ios";
#endif // TARGET_OS_SIMULATOR
#elif TARGET_OS_OSX
  expectedEnvironment = @"macos";
#endif // TARGET_OS_MACCATALYST
  XCTAssertEqualObjects(environment, expectedEnvironment);
}

- (void)testLoggingParameters {
  NSDictionary<NSString *, NSString *> *params = [GIDSignInPreferences loggingParameters];

  XCTAssertEqual(params.count, (NSUInteger)2);
  XCTAssertEqualObjects(params[kSDKVersionLoggingParameter],
                        [GIDSignInPreferences sdkVersion]);
  XCTAssertEqualObjects(params[kEnvironmentLoggingParameter],
                        [GIDSignInPreferences environment]);
}

@end
