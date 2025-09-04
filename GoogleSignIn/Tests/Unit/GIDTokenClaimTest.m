// Copyright 2025 Google LLC
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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDTokenClaim.h"

static NSString *const kAuthTimeClaimName = @"auth_time";

@interface GIDTokenClaimTest : XCTestCase
@end

@implementation GIDTokenClaimTest

- (void)testAuthTimeClaim_PropertiesAreCorrect {
  GIDTokenClaim *claim = [GIDTokenClaim authTimeClaim];
  XCTAssertEqualObjects(claim.name, kAuthTimeClaimName);
  XCTAssertFalse(claim.isEssential);
}

- (void)testEssentialAuthTimeClaim_PropertiesAreCorrect {
  GIDTokenClaim *claim = [GIDTokenClaim essentialAuthTimeClaim];
  XCTAssertEqualObjects(claim.name, kAuthTimeClaimName);
  XCTAssertTrue(claim.isEssential);
}

- (void)testEquality_WithEqualClaims {
  GIDTokenClaim *claim1 = [GIDTokenClaim authTimeClaim];
  GIDTokenClaim *claim2 = [GIDTokenClaim authTimeClaim];
  XCTAssertEqualObjects(claim1, claim2);
  XCTAssertEqual(claim1.hash, claim2.hash);
}

- (void)testEquality_WithUnequalClaims {
  GIDTokenClaim *claim1 = [GIDTokenClaim authTimeClaim];
  GIDTokenClaim *claim2 = [GIDTokenClaim essentialAuthTimeClaim];
  XCTAssertNotEqualObjects(claim1, claim2);
}

@end
