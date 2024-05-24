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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Implementations/GIDAuthorizationResponseHelper.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Fake/GIDAuthorizationResponseHandlingFake.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Implementations/GIDAuthorizationResponseHandler.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

@interface GIDAuthorizationResponseHelperTest : XCTestCase
@end

@implementation GIDAuthorizationResponseHelperTest

/*- (void)testInitWithAuthorizationResponseHandler {
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:nil
                                                         errorString:nil];

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:authResponse
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerify
                                                               configuration:configuration
                                                                       error:nil];

  GIDAuthorizationResponseHelper *responseHelper = [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHelper];
}*/

/*- (void)testInitWithAuthorizationResponse {
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:nil
                                                         errorString:nil];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  GIDAuthorizationResponseHelper *responseHandler =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:authResponse
                                                                 emmSupport:nil
                                                                   flowName:GIDFlowNameVerify
                                                              configuration:configuration];

  XCTAssertNotNil(responseHelper);
  XCTAssertNotNil(responseHelper.authorizationResponse);
  XCTAssertNil(responseHelper.emmSupport);
  XCTAssertEqual(responseHelper.flowName, GIDFlowNameVerify);
  XCTAssertNotNil(responseHelper.configuration);
}*/

///processWithError
/// 1. successful authorization code flow
///  2. authorization code error
///  3. authorization response error flow
///  4. emmHandling
/*
- (void)testSuccessfulProcessWithError {
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:nil
                                                         errorString:nil];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  GIDAuthorizationResponseHandlingFake *responseHandler = 
  [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthorizationResponse:authResponse
                                                                  emmSupport:nil
                                                                     flowName:GIDFlowNameVerify
                                                                configuration:configuration];

  GIDAuthorizationResponseHelper *responseHelper = [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHandler];

//  GIDAuthorizationResponseHelper *responseHelper =
//      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:authResponse
//                                                                 emmSupport:nil
//                                                                   flowName:GIDFlowNameVerify
//                                                              configuration:configuration];
  // Create mock for presenting the authorization request.
  GIDAuthFlow *authFlow = [responseHelper processWithError:error];
  // maybe fetch token checks

  XCTAssertNotNil(authFlow);
  XCTAssertNotNil(authFlow.authState);
}

- (void)testProcessWithError_noAuthorizationResponse {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDAuthorizationResponseHelper *helper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:nil
                                                                emmSupport:nil
                                                                  flowName:GIDFlowNameVerify
                                                             configuration:nil];
#pragma GCC diagnostic pop

  static NSString *const kUserCanceledVerifyError = @"The user canceled the verification flow.";
  NSError *expectedError = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                       code:GIDVerifyErrorCodeCanceled
                                   userInfo:nil];
  NSError *_Nullable error;
  GIDAuthFlow *authFlow = [helper processWithError:error];

  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error, error);
  XCTAssertEqual(authFlow.error.code, GIDVerifyErrorCodeUnknown);
}

- (void)testProcessWithError_noAuthorizationCode {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDAuthorizationResponseHelper *helper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:nil
                                                                emmSupport:nil
                                                                  flowName:GIDFlowNameVerify
                                                             configuration:nil];
#pragma GCC diagnostic pop

  static NSString *const kUserCanceledVerifyError = @"The user canceled the verification flow.";
  NSError *expectedError = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                       code:GIDVerifyErrorCodeCanceled
                                   userInfo:nil];
  NSError *_Nullable error;
  GIDAuthFlow *authFlow = [helper processWithError:error];

  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error, error);
  XCTAssertEqual(authFlow.error.code, GIDVerifyErrorCodeUnknown);
}

// Repeat for `GIDFlowNameSignIn`

- (void)testProcessWithError_noAuthorizationCodeWithEMMSupport {
  // The EMM support version
  static NSString *const kEMMVersion = @"1";
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDAuthorizationResponseHelper *helper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponse:nil
                                                                emmSupport:kEMMVersion
                                                                  flowName:GIDFlowNameSignIn
                                                             configuration:nil];
#pragma GCC diagnostic pop

  static NSString *const kUserCanceledVerifyError = @"The user canceled the verification flow.";
  NSError *expectedError = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                       code:GIDVerifyErrorCodeCanceled
                                   userInfo:nil];
  NSError *_Nullable error;
  GIDAuthFlow *authFlow = [helper processWithError:error];

  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.emmSupport);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error, error);
  XCTAssertEqual(authFlow.error.code, GIDVerifyErrorCodeUnknown);
}

///  maybeFetchToken
///  1. Return if there's an auth flow error or restored access token that isn't near expiration
///  2. Handle EMMSupport for GIDSignIn flow
///  3. token request with additional parameters
///
*/
@end
