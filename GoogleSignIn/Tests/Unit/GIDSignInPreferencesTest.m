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
  NSString *version = [GIDSignInPreferences sdkVersion];
  XCTAssertTrue([version hasPrefix:@"gid-"]);
}

- (void)testGIDEnvironment {
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

- (void)tearDown {
  [GIDSignInPreferences setWrapperIdentifier:nil];
  [super tearDown];
}

- (void)testWrapperIdentifier_UnsetIsNil {
  // Test that when no identifier is set, nil is returned.
  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_AcceptsSimpleValue {
  // Test that a simple lowercase alphanumeric identifier is accepted.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

- (void)testWrapperIdentifier_AcceptsHyphenatedValue {
  // Test that a value with internal hyphens is accepted.
  [GIDSignInPreferences setWrapperIdentifier:@"react-native"];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"react-native");
}

- (void)testWrapperIdentifier_AcceptsDigits {
  // Test that a value with digits is accepted.
  [GIDSignInPreferences setWrapperIdentifier:@"wrapper2"];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"wrapper2");
}

- (void)testWrapperIdentifier_AcceptsMaximumLength {
  // Test that a 32-character valid identifier is accepted and not truncated.
  NSString *maxLength = @"abcdefghijklmnopqrstuvwxyz123456"; // 32 chars
  [GIDSignInPreferences setWrapperIdentifier:maxLength];
  XCTAssertEqual([GIDSignInPreferences wrapperIdentifier].length, (NSUInteger)32);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], maxLength);
}

- (void)testWrapperIdentifier_RejectsUppercase {
  // Test that uppercase characters cause a rejection.
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"Firebase"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_RejectsWhitespace {
  // Test that leading/trailing or internal whitespace cause a rejection.
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"  firebase  "],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"fire base"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_RejectsPunctuation {
  // Test that disallowed punctuation causes a rejection.
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"my-sdk_1.2~x"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"fire!base"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_RejectsEmpty {
  // Test that an empty string is rejected.
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@""],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_RejectsOverLength {
  // Test that a 33-character identifier is rejected.
  NSString *overLength = @"abcdefghijklmnopqrstuvwxyz1234567"; // 33 chars
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:overLength],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_RejectsLeadingOrTrailingHyphen {
  // Test that leading or trailing hyphens cause a rejection.
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"-sdk"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"sdk-"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_FirstValidWriteWins {
  // Test that the first valid write is persistent and subsequent differing writes are rejected.
  [GIDSignInPreferences setWrapperIdentifier:@"first"];
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"second"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"first");
}

- (void)testWrapperIdentifier_RepeatedIdenticalWriteIsAccepted {
  // Test that writing the same valid value again does not throw or change the state.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"firebase"]);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

- (void)testWrapperIdentifier_NilResets {
  // Test that passing nil resets the store, allowing a new first-write.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences setWrapperIdentifier:@"second"];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"second");
}

- (void)testWrapperIdentifier_RejectedWriteLeavesPreviousValue {
  // Test that a rejected write does not clear or change a previously set valid value.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  XCTAssertThrowsSpecificNamed([GIDSignInPreferences setWrapperIdentifier:@"Invalid!"],
                               NSException,
                               NSInternalInconsistencyException);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

@end
