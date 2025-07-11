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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiedAccountDetailResult.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"

#import "GoogleSignIn/Sources/GIDVerifyAccountDetail/Fake/GIDVerifiedAccountDetailHandlingFake.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDToken_Private.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

@interface GIDVerifiedAccountDetailResultTest : XCTestCase
@end

@implementation GIDVerifiedAccountDetailResultTest : XCTestCase

- (void)testInit {
  OIDAuthState *authState = [OIDAuthState testInstance];

  GIDVerifiableAccountDetail *verifiedAccountDetail =
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeUnknown];

  NSArray<GIDVerifiableAccountDetail *> *verifiedList =
      @[verifiedAccountDetail, verifiedAccountDetail];

  GIDVerifiedAccountDetailResult *result = 
      [[GIDVerifiedAccountDetailResult alloc] initWithAccountDetails:verifiedList
                                                           authState:authState];

  XCTAssertEqual(result.verifiedAuthState, authState);
  XCTAssertEqual(result.verifiedAccountDetails, verifiedList);
  XCTAssertEqual(result.accessToken.expirationDate, authState.lastTokenResponse.accessTokenExpirationDate);
  XCTAssertEqual(result.accessToken.tokenString, authState.lastTokenResponse.accessToken);
  XCTAssertEqual(result.refreshToken.tokenString, authState.lastTokenResponse.refreshToken);
}

- (void)testRefreshTokensWithCompletion_randomScope {
  NSString *kAccountDetailList = [NSString stringWithFormat:@"some_scope"];
  OIDTokenResponse *tokenResponse = [OIDTokenResponse testInstanceWithScope:kAccountDetailList];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  GIDVerifiedAccountDetailHandlingFake *result =
      [[GIDVerifiedAccountDetailHandlingFake alloc] initWithTokenResponse:authState.lastTokenResponse
                                                        verifiedAuthState:authState
                                                                    error:nil];

  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Refreshed verified account details completion called"];
  [result refreshTokensWithCompletion:^(GIDVerifiedAccountDetailResult * _Nullable refreshedResult,
                                      NSError * _Nullable error) {
    XCTAssertNil(error);
    XCTAssertNotNil(refreshedResult);
    XCTAssertTrue([refreshedResult.verifiedAccountDetails count] == 0,
                  @"verifiedAccountDetails should have a count of 0");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokensWithCompletion_noTokenResponse {
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:nil];
  NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                               code:kGIDSignInErrorCodeUnknown
                                           userInfo:nil];

  GIDVerifiedAccountDetailHandlingFake *result =
      [[GIDVerifiedAccountDetailHandlingFake alloc] initWithTokenResponse:authState.lastTokenResponse
                                                        verifiedAuthState:authState
                                                                    error:expectedError];

  XCTestExpectation *expectation = 
      [self expectationWithDescription:@"Refreshed verified account details completion called"];
  [result refreshTokensWithCompletion:^(GIDVerifiedAccountDetailResult * _Nullable refreshedResult,
                                      NSError * _Nullable error) {
    XCTAssertNotNil(error);
    XCTAssertEqual(error, expectedError);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeUnknown);
    XCTAssertNotNil(refreshedResult);
    XCTAssertTrue([refreshedResult.verifiedAccountDetails count] == 0,
                  @"verifiedAccountDetails should have a count of 0");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
