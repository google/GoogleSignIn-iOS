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

- (void)tearDown {
  [GIDSignInPreferences resetWrapperIdentifierForTesting];
  [super tearDown];
}

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

// Test that logging parameters include the wrapper identifier when set.
- (void)testLoggingParameters_includesWrapperWhenSet {
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  NSDictionary<NSString *, NSString *> *params = [GIDSignInPreferences loggingParameters];

  XCTAssertEqual(params.count, (NSUInteger)3);
  XCTAssertEqualObjects(params[kSDKWrapperLoggingParameter], @"firebase");
  XCTAssertEqualObjects(params[kSDKVersionLoggingParameter],
                        [GIDSignInPreferences sdkVersion]);
  XCTAssertEqualObjects(params[kEnvironmentLoggingParameter],
                        [GIDSignInPreferences environment]);
}

- (void)testWrapperIdentifier_UnsetIsNil {
  // Test that when no identifier is set, nil is returned.
  [GIDSignInPreferences resetWrapperIdentifierForTesting];
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
  // Test that a 100-character valid identifier is accepted and not truncated.
  NSString *maxLength = [@"a" stringByPaddingToLength:100 withString:@"a" startingAtIndex:0];
  [GIDSignInPreferences setWrapperIdentifier:maxLength];
  XCTAssertEqual([GIDSignInPreferences wrapperIdentifier].length, (NSUInteger)100);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], maxLength);
}

- (void)testWrapperIdentifier_AcceptsMixedCaseSpacesAndPunctuation {
  // Test that mixed case, spaces and punctuation are accepted.
  NSString *value = @"React Native SDK (v2.0)";
  [GIDSignInPreferences setWrapperIdentifier:value];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], value);
}

- (void)testWrapperIdentifier_DropsEmptyString {
  // Test that an empty string is dropped.
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@""]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_FirstValidWriteWins {
  // Test that the first valid write is persistent and subsequent differing writes are rejected.
  [GIDSignInPreferences setWrapperIdentifier:@"first"];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"second"]);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"first");
}

- (void)testWrapperIdentifier_RepeatedIdenticalWriteIsAccepted {
  // Test that writing the same valid value again does not throw or change the state.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"firebase"]);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

- (void)testWrapperIdentifier_NilIsIgnored {
  // Test that passing nil is ignored and does not reset the store.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  [GIDSignInPreferences setWrapperIdentifier:nil];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");

  [GIDSignInPreferences setWrapperIdentifier:@"second"];
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

- (void)testWrapperIdentifier_DroppedWriteLeavesPreviousValue {
  // Test that a dropped write does not clear or change a previously set valid value.
  [GIDSignInPreferences setWrapperIdentifier:@"firebase"];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"firebasé"]);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], @"firebase");
}

- (void)testWrapperIdentifier_TruncatesOverLongValue {
  // Test that a legal string longer than 100 characters is truncated to its first 100 characters.
  NSString *overLong = [@"a" stringByPaddingToLength:150 withString:@"a" startingAtIndex:0];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:overLong]);
  XCTAssertEqual([GIDSignInPreferences wrapperIdentifier].length, (NSUInteger)100);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], [overLong substringToIndex:100]);
}

- (void)testWrapperIdentifier_DropsNonASCII {
  // Test that a value containing a non-ASCII character is ignored and leaves the store nil.
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"firebasé"]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_DropsControlCharacters {
  // Test that values containing ASCII control characters are ignored and leave the store nil.
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"fire\nbase"]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences resetWrapperIdentifierForTesting];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:@"fire\tbase"]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);

  [GIDSignInPreferences resetWrapperIdentifierForTesting];
  NSString *del = [NSString stringWithFormat:@"fire%Cbase", (unichar)0x7F];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:del]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_DropsWhenDisallowedCharacterIsPastTruncationPoint {
  // Test that the drop check deliberately runs on the untruncated string so a payload hidden
  // past the truncation point cannot survive.
  NSString *prefix = [@"a" stringByPaddingToLength:120 withString:@"a" startingAtIndex:0];
  NSString *overLong = [prefix stringByReplacingCharactersInRange:NSMakeRange(110, 1)
                                                       withString:@"é"];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:overLong]);
  XCTAssertNil([GIDSignInPreferences wrapperIdentifier]);
}

- (void)testWrapperIdentifier_WriteOnceComparesSanitizedValue {
  // Test that the write-once check compares the sanitized value, allowing a repeated
  // write of a value that truncates to the same result.
  NSString *overLong = [@"a" stringByPaddingToLength:150 withString:@"a" startingAtIndex:0];
  [GIDSignInPreferences setWrapperIdentifier:overLong];
  XCTAssertNoThrow([GIDSignInPreferences setWrapperIdentifier:overLong]);
  XCTAssertEqualObjects([GIDSignInPreferences wrapperIdentifier], [overLong substringToIndex:100]);
}

@end
