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

// Test module imports
@import GoogleSignIn;

#import "GoogleSignIn/Sources/GIDDataFetcher/Implementations/Fakes/GIDFakeDataFetcher.h"
#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/GIDProfileDataFetcher.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

static NSString *const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 400;

@interface GIDProfileDataFetcherTest : XCTestCase
@end

@implementation GIDProfileDataFetcherTest {
  GIDProfileDataFetcher *_profileDataFetcher;
  GIDFakeDataFetcher *_dataFetcher;
}

- (void)setUp {
  [super setUp];
  _dataFetcher = [[GIDFakeDataFetcher alloc] init];
  _profileDataFetcher = [[GIDProfileDataFetcher alloc] initWithDataFetcher:_dataFetcher];
}

- (void)testFetchProfileData_outOfAuthState_success {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:[OIDTokenResponse fatIDToken]
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with no error"];
  
  [_profileDataFetcher fetchProfileDataWithAuthState:authState
                                          completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(profileData.name, kFatName);
    XCTAssertEqualObjects(profileData.givenName, kFatGivenName);
    XCTAssertEqualObjects(profileData.familyName, kFatFamilyName);
    XCTAssertTrue(profileData.hasImage);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchProfileData_fromInfoURL_fetchingError {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:nil
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  GIDDataFetcherTestBlock testBlock =
      ^(GIDDataFetcherFakeResponse response) {
        NSError *fetchingError = [self error];
        response(nil, fetchingError);
     };
  [_dataFetcher setTestBlock:testBlock];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with error"];
  
  [_profileDataFetcher fetchProfileDataWithAuthState:authState
                                          completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(profileData);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, kErrorDomain);
    XCTAssertEqual(error.code, kErrorCode);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fetch the NSData successfully but can not parse it.
- (void)testFetchProfileData_fromInfoURL_parsingError {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:nil
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  GIDDataFetcherTestBlock testBlock =
      ^(GIDDataFetcherFakeResponse response) {
        NSData *data = [[NSData alloc] init];
        response(data, nil);
     };
  [_dataFetcher setTestBlock:testBlock];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with error"];
  
  [_profileDataFetcher fetchProfileDataWithAuthState:authState
                                          completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(profileData);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, NSCocoaErrorDomain);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Helpers

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

@end
