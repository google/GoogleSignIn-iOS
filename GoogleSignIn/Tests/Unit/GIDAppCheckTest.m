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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <XCTest/XCTest.h>
#import "FirebaseAppCheck/FIRAppCheckToken.h"
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/GIDAppCheckTokenFetcher/Implementations/GIDAppCheckTokenFetcherFake.h"

static NSUInteger const timeout = 1;

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheckTest : XCTestCase
@end

@implementation GIDAppCheckTest

- (void)testGetLimitedUseTokenFailure {
  XCTestExpectation *tokenFailExpectation =
      [self expectationWithDescription:@"App check token fail"];
  NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                               code:kGIDAppCheckTokenFetcherTokenError
                                           userInfo:nil];
  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:nil error:expectedError];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher];

  [appCheck getLimitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertNil(token);
    XCTAssertEqualObjects(expectedError, error);
    [tokenFailExpectation fulfill];
  }];

  [self waitForExpectations:@[tokenFailExpectation] timeout:timeout];
}

- (void)testIsPreparedError {
  XCTestExpectation *notAlreadyPreparedExpectation =
      [self expectationWithDescription:@"App check not already prepared error"];

  FIRAppCheckToken *expectedToken = [[FIRAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];
  // It doesn't matter what we pass for the error since we will check `isPrepared` and make one
  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher];

  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertEqualObjects(token, expectedToken);
    XCTAssertNil(error);
    [notAlreadyPreparedExpectation fulfill];
  }];

  NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                               code:kGIDAppCheckAlreadyPrepared
                                           userInfo:nil];

  XCTestExpectation *alreadyPreparedExpectation =
      [self expectationWithDescription:@"App check already prepared error"];

  // We don't need to wait for `notAlreadyPreparedExpectation` to fulfill  because
  // `prepareForAppCheckWithCompletion:`'s work is dispatched to a serial background queue and will
  // and will execute in the order received
  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token, NSError * _Nullable error) {
    XCTAssertNil(token);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error, expectedError);
    [alreadyPreparedExpectation fulfill];
  }];

  [self waitForExpectations:@[notAlreadyPreparedExpectation, alreadyPreparedExpectation]
                    timeout:timeout];
  XCTAssertTrue(appCheck.isPrepared);
}

- (void)testGetLimitedUseTokenSucceeds {
  XCTestExpectation *prepareExpectation =
      [self expectationWithDescription:@"Prepare for App Check expectation"];
  FIRAppCheckToken *expectedToken = [[FIRAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];

  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher];

  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertEqualObjects(token, expectedToken);
    XCTAssertNil(error);
    [prepareExpectation fulfill];
  }];

  // Wait for preparation to complete to test `isPrepared`
  [self waitForExpectations:@[prepareExpectation] timeout:timeout];

  XCTAssertTrue(appCheck.isPrepared);

  XCTestExpectation *getLimitedUseTokenSucceedsExpectation =
      [self expectationWithDescription:@"getLimitedUseToken should succeed"];

  [appCheck getLimitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertNil(error);
    XCTAssertNotNil(token);
    XCTAssertEqualObjects(token, expectedToken);
    [getLimitedUseTokenSucceedsExpectation fulfill];
  }];

  [self waitForExpectations:@[getLimitedUseTokenSucceedsExpectation] timeout:timeout];

  XCTAssertTrue(appCheck.isPrepared);
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
