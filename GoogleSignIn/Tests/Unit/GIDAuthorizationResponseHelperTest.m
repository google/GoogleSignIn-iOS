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

#import "GoogleSignIn/Sources/GIDAuthorizationResponseHelper.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

@interface GIDAuthorizationResponseHelperTest : XCTestCase
@end

@implementation GIDAuthorizationResponseHelperTest

- (void)testInitWithAuthorizationResponse {
  // Mock generating a GIDConfiguration when initializing GIDGoogleUser.
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:nil
                                                         errorString:nil];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  GIDAuthorizationResponseHelper *responseHelper = 
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:authResponse
                                                                 emmSupport:nil
                                                                   flowName:Verify
                                                              configuration:configuration];

  XCTAssertNotNil(responseHelper);
  XCTAssertNotNil(responseHelper.authorizationResponse);
  XCTAssertNil(responseHelper.emmSupport);
  XCTAssertEqual(responseHelper.flowName, Verify);
  XCTAssertNotNil(responseHelper.configuration);
}

@end
