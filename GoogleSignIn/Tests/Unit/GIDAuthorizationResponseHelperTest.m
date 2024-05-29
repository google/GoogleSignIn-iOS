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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/GIDAuthorizationResponseHelper.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Fake/GIDAuthorizationResponseHandlingFake.h"
#import "GoogleSignIn/Sources/GIDAuthorizationResponse/Implementations/GIDAuthorizationResponseHandler.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"
#import "GoogleSignIn/Sources/GIDAuthFlow.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"

// The EMM support version
static NSString *const kEMMVersion = @"1";

@interface GIDAuthorizationResponseHelperTest : XCTestCase
@end

@implementation GIDAuthorizationResponseHelperTest

- (void)testInitWithAuthorizationResponseHandler {
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerify
                                                               configuration:nil
                                                                       error:nil];
  GIDAuthorizationResponseHelper *responseHelper = 
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHandler];

  XCTAssertNotNil(responseHelper);
  XCTAssertNotNil(responseHelper.responseHandler);
}

- (void)testFetchTokenWithAuthFlow {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDAuthorizationResponseHandlingFake *fakeHandler = 
      [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthState:authState error:nil];
  GIDAuthorizationResponseHelper *responseHelper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:fakeHandler];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];

  [responseHelper fetchTokenWithAuthFlow:authFlow];
  XCTAssertNotNil(authFlow);
  XCTAssertNotNil(authFlow.authState);
  XCTAssertNil(authFlow.error);
}

- (void)testSuccessfulGenerateAuthFlowFromAuthorizationResponse {
  OIDAuthorizationResponse *authorizationResponse = [OIDAuthorizationResponse testInstance];
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:authorizationResponse
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerify
                                                               configuration:nil
                                                                       error:nil];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertNotNil(authFlow.authState);
  XCTAssertNil(authFlow.error);
}

- (void)testGenerateAuthFlowFromAuthorizationResponse_noCode {
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSDictionary<NSString *, NSString *> *errorDict =
      @{ NSLocalizedDescriptionKey : @"Unknown error" };
  NSError *expectedError = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                               code:GIDVerifyErrorCodeUnknown
                                           userInfo:errorDict];

  OIDAuthorizationResponse *authorizationResponse = 
      [OIDAuthorizationResponse testInstanceNoAuthCodeWithAdditionalParameters:nil 
                                                                   errorString:nil];
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:authorizationResponse
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerify
                                                               configuration:nil
                                                                       error:nil];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error.code, expectedError.code);
  XCTAssertEqual(authFlow.error.userInfo[NSLocalizedDescriptionKey],
                  expectedError.userInfo[NSLocalizedDescriptionKey]);
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
}

- (void)testGenerateAuthFlowWithMissingAuthorizationResponse {
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSError *error = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                       code:GIDVerifyErrorCodeUnknown
                                   userInfo:nil];
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerify
                                                               configuration:nil
                                                                       error:error];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error.code, error.code);
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
}

- (void)testMaybeFetchTokenWithAuthFlowError {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeUnknown
                                   userInfo:nil];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:nil
                                                           error:error
                                                      emmSupport:nil
                                                     profileData:nil];
  GIDAuthorizationResponseHandler *responseHandler = 
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:kEMMVersion
                                                                    flowName:GIDFlowNameSignIn
                                                               configuration:nil
                                                                       error:nil];

  [responseHandler maybeFetchToken:authFlow];
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertNil(authFlow.emmSupport);
}

- (void)testMaybeFetchTokenWithExpirationError {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:authState
                                                           error:nil
                                                      emmSupport:nil
                                                     profileData:nil];
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:kEMMVersion
                                                                    flowName:GIDFlowNameSignIn
                                                               configuration:nil
                                                                       error:nil];

  [responseHandler maybeFetchToken:authFlow];
  XCTAssertNotNil(authFlow.authState);
  XCTAssertNil(authFlow.error);
  XCTAssertNil(authFlow.emmSupport);
}

@end
