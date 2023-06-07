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
#import "GoogleSignIn/Sources/GIDAppCheck.h"
#import "GoogleSignIn/Tests/Unit/GIDAppCheckProviderFake.h"

@interface GIDAppCheckTest : XCTestCase
@end

@implementation GIDAppCheckTest

- (void)testGetLimitedUseTokenFailure {
  XCTestExpectation *tokenFailExpectation =
      [self expectationWithDescription:@"App check token fail"];
  NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                               code:kGIDAppCheckProviderTokenError
                                           userInfo:nil];
  GIDAppCheckProviderFake *appCheckProvider =
      [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:nil error:expectedError];
  GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:appCheckProvider];

  [appCheck getLimitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                               NSError * _Nullable error) {
    XCTAssertNil(token);
    XCTAssertEqualObjects(expectedError, error);
    [tokenFailExpectation fulfill];
  }];

  [self waitForExpectations:@[tokenFailExpectation]];
}

@end
