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
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

NSString *const kAccountDetailTypeAgeOver18Scopey = @"https://www.googleapis.com/auth/verified.age.over18.standard";

@interface GIDVerifiedAccountDetailResultTest : XCTestCase
@end

@implementation GIDVerifiedAccountDetailResultTest : XCTestCase

- (void)testInit {
  OIDAuthState *authState = [OIDAuthState testInstance];

  GIDVerifiableAccountDetail *verifiedAccountDetail =
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];

  NSArray<GIDVerifiableAccountDetail *> *verifiedList =
  @[verifiedAccountDetail, verifiedAccountDetail];

  GIDVerifiedAccountDetailResult *result = [[GIDVerifiedAccountDetailResult alloc] initWithLastTokenResponse:authState.lastTokenResponse accountDetails:verifiedList authState:authState];

  XCTAssertEqual(result.verifiedAuthState, authState);
  XCTAssertEqual(result.verifiedAccountDetails, verifiedList);
  XCTAssertEqual(result.expirationDate, authState.lastTokenResponse.accessTokenExpirationDate);
  XCTAssertEqual(result.accessTokenString, authState.lastTokenResponse.accessToken);
  XCTAssertEqual(result.refreshTokenString, authState.lastTokenResponse.refreshToken);

}

- (void)testRefreshTokensWithCompletion_success {
  GIDVerifiableAccountDetail *verifiedAccountDetail = 
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];

  NSArray<GIDVerifiableAccountDetail *> *expectedVerifiedList =
  @[verifiedAccountDetail, verifiedAccountDetail];

  NSString *accountDetailString = @"https://www.googleapis.com/auth/verified.age.over18.standard  https://www.googleapis.com/auth/verified.age.over18.standard";

  OIDTokenResponse *tokenResponse = [OIDTokenResponse testInstanceWithScope:accountDetailString];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];

  GIDVerifiedAccountDetailResultFake *result =
      [[GIDVerifiedAccountDetailResultFake alloc] initWithTokenResponse:authState.lastTokenResponse
                                                      verifiedAuthState:authState
                                                                  error:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion called"];
  [result refreshTokensWithCompletion:^(GIDVerifiedAccountDetailResult * _Nullable refreshedResult,
                                      NSError * _Nullable error) {
    XCTAssertNil(error);
    XCTAssertNotNil(refreshedResult);
    XCTAssertNotNil(refreshedResult.verifiedAccountDetails);
    XCTAssertTrue([refreshedResult.verifiedAccountDetails isEqualToArray:expectedVerifiedList]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokensWithCompletion_noTokenResponse {
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:nil];
  NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeUnknown
                                   userInfo:nil];

  GIDVerifiedAccountDetailResultFake *result =
      [[GIDVerifiedAccountDetailResultFake alloc] initWithTokenResponse:authState.lastTokenResponse
                                                      verifiedAuthState:authState
                                                                  error:expectedError];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion called"];
  [result refreshTokensWithCompletion:^(GIDVerifiedAccountDetailResult * _Nullable refreshedResult,
                                      NSError * _Nullable error) {
    XCTAssertNotNil(error);
    XCTAssertEqual(error, expectedError);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeUnknown);
    XCTAssertNotNil(refreshedResult);
    XCTAssertEqual(refreshedResult.verifiedAccountDetails, @[]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end