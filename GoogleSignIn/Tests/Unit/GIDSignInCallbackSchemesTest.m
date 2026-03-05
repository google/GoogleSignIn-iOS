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

#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"

static NSString *const kClientId = @"FakeClientID";

@interface GIDSignInCallbackSchemesTest : XCTestCase
@end

@implementation GIDSignInCallbackSchemesTest {
  GIDFakeMainBundle *_fakeMainBundle;
}

- (void)setUp {
  _fakeMainBundle = [[GIDFakeMainBundle alloc] init];
  [_fakeMainBundle startFakingWithClientID:kClientId];
}

- (void)tearDown {
  [_fakeMainBundle stopFaking];
}

#pragma mark - Tests

- (void)testClientIdentifierScheme {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:kClientId];
  XCTAssertEqualObjects(schemes.clientIdentifierScheme, kClientId.lowercaseString);
}

- (void)testAllSchemes {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:kClientId];
  XCTAssertEqual(schemes.allSchemes.count, 1U);
  for (NSString *scheme in schemes.allSchemes) {
    if ([scheme isEqual:kClientId.lowercaseString]) {
      continue;
    }
    XCTAssert(NO, @"Found unknown scheme in schemes list.");
  }
}

/**
 * @fn testUnsupportedSchemes
 * @brief Makes sure that various permutations of the info.plist work with the unsupportedSchemes
 *     method. Specifically, checks that missing schemes are properly returned, that
 *     case-sensitivity issues don't cause a problem, and that the different ways of representing
 *     multiple schemes in the info.plist all work correctly.
 */
- (void)testUnsupportedSchemes {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:kClientId];

  [_fakeMainBundle fakeAllSchemesSupported];
  XCTAssertEqual([schemes unsupportedSchemes].count, 0ul);

  [_fakeMainBundle fakeAllSchemesSupportedAndMerged];
  XCTAssertEqual([schemes unsupportedSchemes].count, 0ul);

  [_fakeMainBundle fakeOtherSchemesAndAllSchemes];
  XCTAssertEqual([schemes unsupportedSchemes].count, 0ul);

  [_fakeMainBundle fakeAllSchemesSupportedWithCasesMangled];
  XCTAssertEqual([schemes unsupportedSchemes].count, 0ul);

  [_fakeMainBundle fakeMissingClientIdScheme];
  XCTAssertEqual([schemes unsupportedSchemes].count, 1ul);

  [_fakeMainBundle fakeMissingAllSchemes];
  XCTAssertEqual([schemes unsupportedSchemes].count, 1ul);

  [_fakeMainBundle fakeOtherSchemes];
  XCTAssertEqual([schemes unsupportedSchemes].count, 1ul);
}

- (void)testURLSchemeIsCallbackScheme {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:kClientId];

  NSURL *clientIdentifierURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:/", kClientId]];
  NSURL *junkIdentifierURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:/", @"junk"]];

  XCTAssert([schemes URLSchemeIsCallbackScheme:clientIdentifierURL]);
  XCTAssertFalse([schemes URLSchemeIsCallbackScheme:junkIdentifierURL]);
}

@end
