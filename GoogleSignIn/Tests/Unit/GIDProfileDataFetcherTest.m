// Copyright 2023 Google LLC
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

#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/Fakes/GIDFakeHTTPFetcher.h"
#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/GIDProfileDataFetcher.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

static NSString *const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 400;

@interface GIDProfileDataFetcherTest : XCTestCase
@end

@implementation GIDProfileDataFetcherTest {
  GIDProfileDataFetcher *_profileDataFetcher;
  GIDFakeHTTPFetcher *_httpFetcher;
}

- (void)setUp {
  [super setUp];
  _httpFetcher = [[GIDFakeHTTPFetcher alloc] init];
  _profileDataFetcher = [[GIDProfileDataFetcher alloc] initWithHTTPFetcher:_httpFetcher];
}

// Extracts the `GIDProfileData` out of a fat ID token.
- (void)testFetchProfileData_fatIDToken_success {
  NSString *fatIDToken = [OIDTokenResponse fatIDToken];
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:fatIDToken
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  GIDHTTPFetcherTestBlock testBlock =
      ^(NSURLRequest *request, GIDHTTPFetcherFakeResponseProviderBlock responseProvider) {
        XCTFail(@"_httpFetcher should not be invoked");
      };
  [_httpFetcher setTestBlock:testBlock];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"completion is invoked"];
  
  [_profileDataFetcher
      fetchProfileDataWithAuthState:authState
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

// Can not extracts the `GIDProfileData` out of a non-fat ID token. Try to fetch it from the
// UserInfo endpoint and get an error.
- (void)testFetchProfileData_nonFatIDToken_fetchingError {
  NSString *nonFatIDToken = [OIDTokenResponse idToken];
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:nonFatIDToken
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  NSError *fetchingError = [self error];
  [self setGIDHTTPFetcherTestBlockWithData:nil error:fetchingError];
  
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"completion is invoked"];
  
  [_profileDataFetcher
      fetchProfileDataWithAuthState:authState
                         completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(profileData);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, kErrorDomain);
    XCTAssertEqual(error.code, kErrorCode);
    [completionExpectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

// There is no ID token. Try to fetch it from the UserInfo endpoint and get an error.
- (void)testFetchProfileData_noIDToken_fetchingError {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:nil
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  NSError *fetchingError = [self error];
  [self setGIDHTTPFetcherTestBlockWithData:nil error:fetchingError];
  
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"completion is invoked"];
  
  [_profileDataFetcher
      fetchProfileDataWithAuthState:authState
                         completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(profileData);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, kErrorDomain);
    XCTAssertEqual(error.code, kErrorCode);
    [completionExpectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Fetch the NSData from the UserInfo endpoint successfully but can not parse it.
- (void)testFetchProfileData_noIDToken_parsingError {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:nil
                                    accessToken:kAccessToken
                                      expiresIn:@(300)
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
  
  NSData *data = [[NSData alloc] init];
  [self setGIDHTTPFetcherTestBlockWithData:data error:nil];
  
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"completion is invoked"];
  
  [_profileDataFetcher
      fetchProfileDataWithAuthState:authState
                         completion:^(GIDProfileData *profileData, NSError *error) {
    XCTAssertNil(profileData);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, NSCocoaErrorDomain);
    [completionExpectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Helpers

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

/// Set the return value from the UserInfo endpoint.
- (void)setGIDHTTPFetcherTestBlockWithData:(NSData *)data
                                     error:(NSError *)error {
  XCTestExpectation *fetcherExpectation =
      [self expectationWithDescription:@"_httpFetcher is invoked"];
  GIDHTTPFetcherTestBlock testBlock =
      ^(NSURLRequest *request, GIDHTTPFetcherFakeResponseProviderBlock responseProvider) {
        responseProvider(data, error);
        [fetcherExpectation fulfill];
      };
  [_httpFetcher setTestBlock:testBlock];
}

@end
