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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAppCheckError.h"

static NSUInteger const timeout = 1;
static NSString *const kUserDefaultsSuiteName = @"GIDAppCheckKeySuiteName";

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheckTest : XCTestCase

@property(nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation GIDAppCheckTest

- (void)setUp {
  [super setUp];
  _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
}

- (void)tearDown {
  [super tearDown];
  [self.userDefaults removeObjectForKey:kGIDAppCheckPreparedKey];
  [self.userDefaults removeSuiteNamed:kUserDefaultsSuiteName];
}

- (void)testGetLimitedUseTokenFailure {
  XCTestExpectation *tokenFailExpectation =
      [self expectationWithDescription:@"App check token fail"];
  NSError *expectedError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                               code:kGIDAppCheckTokenFetcherTokenError
                                           userInfo:nil];
  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:nil error:expectedError];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher
                                                               userDefaults:self.userDefaults];

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
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher
                                                               userDefaults:self.userDefaults];

  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertEqualObjects(token, expectedToken);
    XCTAssertNil(error);
    [notAlreadyPreparedExpectation fulfill];
  }];

  [self waitForExpectations:@[notAlreadyPreparedExpectation] timeout:timeout];

  NSError *expectedError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                               code:kGIDAppCheckAlreadyPrepared
                                           userInfo:nil];

  XCTestExpectation *alreadyPreparedExpectation =
      [self expectationWithDescription:@"App check already prepared error"];

  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertNil(token);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error, expectedError);
    [alreadyPreparedExpectation fulfill];
  }];

  [self waitForExpectations:@[alreadyPreparedExpectation] timeout:timeout];

  XCTAssertTrue([appCheck isPrepared]);
}

- (void)testGetLimitedUseTokenSucceeds {
  XCTestExpectation *prepareExpectation =
      [self expectationWithDescription:@"Prepare for App Check expectation"];
  FIRAppCheckToken *expectedToken = [[FIRAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];

  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher
                                                               userDefaults:self.userDefaults];

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

  XCTAssertTrue([appCheck isPrepared]);
}

- (void)testAsyncCompletions {
  XCTestExpectation *firstPrepareExpectation =
      [self expectationWithDescription:@"First async prepare for App Check expectation"];

  XCTestExpectation *secondPrepareExpectation =
      [self expectationWithDescription:@"Second async prepare for App Check expectation"];

  FIRAppCheckToken *expectedToken = [[FIRAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];

  GIDAppCheckTokenFetcherFake *tokenFetcher =
      [[GIDAppCheckTokenFetcherFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckTokenFetcher:tokenFetcher
                                                               userDefaults:self.userDefaults];

  dispatch_async(dispatch_get_main_queue(), ^{
    [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                 NSError * _Nullable error) {
      XCTAssertNil(error);
      XCTAssertNotNil(token);
      XCTAssertEqualObjects(token, expectedToken);
      [firstPrepareExpectation fulfill];
    }];
  });

  dispatch_async(dispatch_get_main_queue(), ^{
    [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                 NSError * _Nullable error) {
      XCTAssertNil(error);
      XCTAssertNotNil(token);
      XCTAssertEqualObjects(token, expectedToken);
      [secondPrepareExpectation fulfill];
    }];
  });

  [self waitForExpectations:@[firstPrepareExpectation, secondPrepareExpectation] timeout:timeout];

  XCTAssertTrue([appCheck isPrepared]);

  // Simulate requesting later on after `appCheck` is prepared
  XCTestExpectation *preparedExpectation =
      [self expectationWithDescription:@"Prepared expectation"];

  [appCheck prepareForAppCheckWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertNil(token);
    XCTAssertNotNil(error);
    NSError *expectedError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                                 code:kGIDAppCheckAlreadyPrepared
                                             userInfo:nil];
    XCTAssertEqualObjects(error, expectedError);
    [preparedExpectation fulfill];
  }];

  [self waitForExpectations:@[preparedExpectation] timeout:timeout];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
