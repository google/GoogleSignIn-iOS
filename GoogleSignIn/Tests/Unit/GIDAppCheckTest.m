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
#import <AppCheckCore/GACAppCheckToken.h>
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/Fake/GIDAppCheckProviderFake.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAppCheckError.h"

static NSUInteger const timeout = 1;
static NSString *const kUserDefaultsTestSuiteName = @"GIDAppCheckTestKeySuiteName";

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheckTest : XCTestCase

@property(nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation GIDAppCheckTest

- (void)setUp {
  [super setUp];
  _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsTestSuiteName];
}

- (void)tearDown {
  [super tearDown];
  [self.userDefaults removeObjectForKey:kGIDAppCheckPreparedKey];
  [self.userDefaults removeSuiteNamed:kUserDefaultsTestSuiteName];
}

- (void)testGetLimitedUseTokenFailureReturnsPlaceholder {
  XCTestExpectation *tokenFailExpectation =
      [self expectationWithDescription:@"App check token fail"];
  NSError *expectedError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                               code:kGIDAppCheckProviderFakeError
                                           userInfo:nil];

  GIDAppCheckProviderFake *fakeProvider =
      [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:nil error:expectedError];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                           userDefaults:self.userDefaults];

  [appCheck getLimitedUseTokenWithCompletion:^(GACAppCheckToken *token,
                                               NSError * _Nullable error) {
    XCTAssertEqualObjects(expectedError, error);
    XCTAssertNotNil(token); // If there is an error, we expect a placeholder token
    [tokenFailExpectation fulfill];
  }];

  [self waitForExpectations:@[tokenFailExpectation] timeout:timeout];
}

- (void)testIsPreparedError {
  XCTestExpectation *notAlreadyPreparedExpectation =
      [self expectationWithDescription:@"App check not already prepared error"];

  GACAppCheckToken *expectedToken = [[GACAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];
  // It doesn't matter what we pass for the error since we will check `isPrepared` and make one
  GIDAppCheckProviderFake *fakeProvider =
      [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:expectedToken error:nil];

  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                           userDefaults:self.userDefaults];

  [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [notAlreadyPreparedExpectation fulfill];
  }];

  [self waitForExpectations:@[notAlreadyPreparedExpectation] timeout:timeout];

  XCTestExpectation *alreadyPreparedExpectation =
      [self expectationWithDescription:@"App check already prepared error"];

  // Should be no error since multiple calls to prepare should be fine.
  [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [alreadyPreparedExpectation fulfill];
  }];

  [self waitForExpectations:@[alreadyPreparedExpectation] timeout:timeout];

  XCTAssertTrue([appCheck isPrepared]);
}

- (void)testGetLimitedUseTokenSucceeds {
  XCTestExpectation *prepareExpectation =
      [self expectationWithDescription:@"Prepare for App Check expectation"];

  GACAppCheckToken *expectedToken = [[GACAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];

  GIDAppCheckProviderFake *fakeProvider =
      [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                           userDefaults:self.userDefaults];

  [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [prepareExpectation fulfill];
  }];

  // Wait for preparation to complete to test `isPrepared`
  [self waitForExpectations:@[prepareExpectation] timeout:timeout];

  XCTAssertTrue(appCheck.isPrepared);

  XCTestExpectation *getLimitedUseTokenSucceedsExpectation =
      [self expectationWithDescription:@"getLimitedUseToken should succeed"];

  [appCheck getLimitedUseTokenWithCompletion:^(GACAppCheckToken *token,
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

  GACAppCheckToken *expectedToken = [[GACAppCheckToken alloc] initWithToken:@"foo"
                                                             expirationDate:[NSDate distantFuture]];

  GIDAppCheckProviderFake *fakeProvider =
      [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:expectedToken error:nil];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                           userDefaults:self.userDefaults];

  dispatch_async(dispatch_get_main_queue(), ^{
    [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
      XCTAssertNil(error);
      [firstPrepareExpectation fulfill];
    }];
  });

  dispatch_async(dispatch_get_main_queue(), ^{
    [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
      XCTAssertNil(error);
      [secondPrepareExpectation fulfill];
    }];
  });

  [self waitForExpectations:@[firstPrepareExpectation, secondPrepareExpectation] timeout:timeout];

  XCTAssertTrue([appCheck isPrepared]);

  // Simulate requesting later on after `appCheck` is prepared
  XCTestExpectation *preparedExpectation =
      [self expectationWithDescription:@"Prepared expectation"];

  [appCheck prepareForAppCheckWithCompletion:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [preparedExpectation fulfill];
  }];

  [self waitForExpectations:@[preparedExpectation] timeout:timeout];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
