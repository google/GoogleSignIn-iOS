/*
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDAuthFlow.h"

#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"

@interface GIDAuthFlowTest : XCTestCase
@end

@implementation GIDAuthFlowTest

- (void)testInitWithAuthState {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDProfileData *profileData = [GIDProfileData testInstance];

  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:authState
                                                           error:nil
                                                      emmSupport:nil
                                                     profileData:profileData];

  XCTAssertNotNil(authFlow);
  XCTAssertEqual(authFlow.authState, authState);
  XCTAssertNil(authFlow.error);
  XCTAssertNil(authFlow.emmSupport);
  XCTAssertEqual(authFlow.profileData, profileData);
}

- (void)testInit {
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];

  XCTAssertNotNil(authFlow);
  XCTAssertNil(authFlow.authState);
  XCTAssertNil(authFlow.error);
  XCTAssertNil(authFlow.emmSupport);
  XCTAssertNil(authFlow.profileData);
}

@end
