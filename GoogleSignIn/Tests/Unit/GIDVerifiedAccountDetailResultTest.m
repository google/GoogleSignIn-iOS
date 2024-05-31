// Copyright 2024 Google LLC
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

#import "GoogleSignIn/Sources/GIDVerifyAccountDetail/Fake/GIDVerifiedAccountDetailResultFake.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

@interface GIDVerifiedAccountDetailResultTest : XCTestCase
@end

@implementation GIDVerifiedAccountDetailResultTest : XCTestCase

- (void)testInit {

}

- (void)testRefreshTokensWithCompletion_success {

}

- (void)testRefreshTokensWithCompletion_noTokenResponse {
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:nil];
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeUnknown
                                   userInfo:nil];

//  GIDVerifiedAccountDetailResult *result =
//      [[GIDVerifiedAccountDetailResult alloc] initWithTokenResponse:authState.lastTokenResponse
//                                                              authState:authState
//                                                                  error:nil];

  GIDVerifiedAccountDetailResultFake *result =
      [[GIDVerifiedAccountDetailResultFake alloc] initWithTokenResponse:authState.lastTokenResponse
                                                      verifiedAuthState:authState
                                                                  error:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion called"];
  [result refreshTokensWithCompletion:^(GIDVerifiedAccountDetailResult * _Nullable refreshedResult,
                                      NSError * _Nullable error) {
    XCTAssertNotNil(error);
    XCTAssertNil(refreshedResult);
    XCTAssertNil(refreshedResult.verifiedAccountDetails);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeUnknown);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
