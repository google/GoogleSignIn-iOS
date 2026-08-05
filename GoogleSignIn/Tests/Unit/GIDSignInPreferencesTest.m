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

- (void)testGIDVersion {
  NSString *version = GIDVersion();
  XCTAssertTrue([version hasPrefix:@"gid-"]);
}

- (void)testGIDEnvironment {
  NSString *environment = GIDEnvironment();

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

- (void)tearDown {
  GIDSetWrapperIdentifier(nil);
  [super tearDown];
}

- (void)testWrapperIdentifier_UnsetReturnsNil {
  // Test that when no identifier is set (or it is explicitly cleared), nil is returned.
  GIDSetWrapperIdentifier(nil);
  XCTAssertNil(GIDWrapperIdentifier());
}

- (void)testWrapperIdentifier_RoundTripsSimpleValue {
  // Test that a simple alphanumeric identifier is correctly stored and retrieved.
  GIDSetWrapperIdentifier(@"firebase");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"firebase");
}

- (void)testWrapperIdentifier_Lowercases {
  // Test that identifiers are automatically lowercased when stored.
  GIDSetWrapperIdentifier(@"FireBase");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"firebase");
}

- (void)testWrapperIdentifier_StripsDisallowedCharacters {
  // Test that spaces and disallowed punctuation are removed from the identifier.
  GIDSetWrapperIdentifier(@"fire base!/&=?");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"firebase");
}

- (void)testWrapperIdentifier_KeepsAllowedPunctuation {
  // Test that allowed characters (A-Za-z0-9-._~) are preserved.
  GIDSetWrapperIdentifier(@"my-sdk_1.2~x");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"my-sdk_1.2~x");
}

- (void)testWrapperIdentifier_TrimsWhitespace {
  // Test that leading and trailing whitespace is trimmed from the identifier.
  GIDSetWrapperIdentifier(@"  firebase  ");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"firebase");
}

- (void)testWrapperIdentifier_EmptyOrWhitespaceBecomesNil {
  // Test that empty or whitespace-only strings result in a nil identifier.
  GIDSetWrapperIdentifier(@"   ");
  XCTAssertNil(GIDWrapperIdentifier());

  // Test that a string consisting only of invalid characters results in a nil identifier.
  GIDSetWrapperIdentifier(@"!!!");
  XCTAssertNil(GIDWrapperIdentifier());
}

- (void)testWrapperIdentifier_CapsAtThirtyTwoCharacters {
  // Test that the identifier is truncated to a maximum of 32 characters.
  NSString *longString = @"abcdefghijklmnopqrstuvwxyz1234567890"; // 36 characters
  GIDSetWrapperIdentifier(longString);
  NSString *result = GIDWrapperIdentifier();
  XCTAssertEqual(result.length, (NSUInteger)32);
  XCTAssertEqualObjects(result, [longString.lowercaseString substringToIndex:32]);
}

- (void)testWrapperIdentifier_LastWriteWins {
  // Test that subsequent writes overwrite the previous identifier.
  GIDSetWrapperIdentifier(@"first");
  GIDSetWrapperIdentifier(@"second");
  XCTAssertEqualObjects(GIDWrapperIdentifier(), @"second");

  // Test that setting it to nil clears the identifier.
  GIDSetWrapperIdentifier(nil);
  XCTAssertNil(GIDWrapperIdentifier());
}

@end
