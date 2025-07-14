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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"

@interface GIDVerifiableAccountDetailTests : XCTestCase
@end

@implementation GIDVerifiableAccountDetailTests

- (void)testDesignatedInitializer {
  GIDVerifiableAccountDetail *detail =
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeUnknown];
  XCTAssertNotNil(detail);
  XCTAssertEqual(detail.accountDetailType, GIDAccountDetailTypeUnknown);
}

- (void)testScopeRetrieval {
  GIDVerifiableAccountDetail *detail =
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeUnknown];
  NSString *retrievedScope = [detail scope];
  XCTAssertNil(retrievedScope);
}

- (void)testScopeRetrieval_MissingScope {
  NSInteger missingScope = 5;
  GIDVerifiableAccountDetail *detail =
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:missingScope];
  NSString *retrievedScope = [detail scope];
  XCTAssertNil(retrievedScope);
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
