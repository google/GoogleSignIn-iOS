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

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

@interface GIDSignInInternalOptionsTest : XCTestCase
@end

@implementation GIDSignInInternalOptionsTest

- (void)testDefaultOptions {
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions defaultOptions];
  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);
}

- (void)testSilentOptions {
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions silentOptions];
  XCTAssertFalse(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);
}

- (void)testSilentOptionsWithExtraParams {
  NSDictionary *extraParams = @{ @"key" : @"value" };
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions optionsWithExtraParams:extraParams];
  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertEqualObjects(options.extraParams, extraParams);
}

@end
