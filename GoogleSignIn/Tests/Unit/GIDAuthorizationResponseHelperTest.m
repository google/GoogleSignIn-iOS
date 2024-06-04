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
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

// The EMM support version
static NSString *const kEMMVersion = @"1";

// Time interval to use for an expiring access token.
static NSTimeInterval kExpiringAccessToken = 20;

@interface GIDAuthorizationResponseHelperTest : XCTestCase
@end

@implementation GIDAuthorizationResponseHelperTest

- (void)testInitWithAuthorizationResponseHandler {
  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerifyAccountDetail
                                                               configuration:nil
                                                                       error:nil];
  GIDAuthorizationResponseHelper *responseHelper = 
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHandler];

  XCTAssertNotNil(responseHelper);
  XCTAssertNotNil(responseHelper.responseHandler);
}

- (void)testFetchTokenWithAuthFlow {
  OIDTokenResponse *tokenResponse = 
      [OIDTokenResponse testInstanceWithAccessTokenExpiresIn:@(kAccessTokenExpiresIn)];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];

  GIDAuthorizationResponseHandlingFake *responseHandler =
      [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthState:authState error:nil];
  GIDAuthorizationResponseHelper *responseHelper =
      [[GIDAuthorizationResponseHelper alloc] initWithAuthorizationResponseHandler:responseHandler];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:authState 
                                                           error:nil
                                                      emmSupport:nil
                                                     profileData:nil];

  [responseHelper fetchTokenWithAuthFlow:authFlow];
  XCTAssertNotNil(authFlow);
  XCTAssertEqual(authFlow.authState, authState);
  XCTAssertNil(authFlow.error);
}

- (void)testSuccessfulGenerateAuthFlowFromAuthorizationResponse {
  OIDTokenResponse *tokenResponse = 
      [OIDTokenResponse testInstanceWithAccessTokenExpiresIn:@(kAccessTokenExpiresIn)];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];

  GIDAuthorizationResponseHandlingFake *responseHandler =
      [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthState:authState error:nil];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertEqual(authFlow.authState, authState);
  XCTAssertNil(authFlow.error);
}

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)testGenerateAuthFlowFromAuthorizationResponse_noCode {
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
                                                                    flowName:GIDFlowNameVerifyAccountDetail
                                                               configuration:nil
                                                                       error:nil];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error.domain, expectedError.domain);
  XCTAssertEqual(authFlow.error.code, expectedError.code);
  XCTAssertEqualObjects(authFlow.error.userInfo, expectedError.userInfo);
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)testGenerateAuthFlowWithMissingAuthorizationResponse {
  NSError *error = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                       code:GIDVerifyErrorCodeUnknown
                                   userInfo:nil];

  NSString *errorString = [error localizedDescription];
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  NSError *expectedError = [NSError errorWithDomain:kGIDVerifyErrorDomain
                                               code:GIDVerifyErrorCodeUnknown
                                           userInfo:errorDict];

  GIDAuthorizationResponseHandler *responseHandler =
      [[GIDAuthorizationResponseHandler alloc] initWithAuthorizationResponse:nil
                                                                  emmSupport:nil
                                                                    flowName:GIDFlowNameVerifyAccountDetail
                                                               configuration:nil
                                                                       error:error];

  GIDAuthFlow *authFlow = [responseHandler generateAuthFlowFromAuthorizationResponse];
  XCTAssertNotNil(authFlow);
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error.domain, expectedError.domain);
  XCTAssertEqual(authFlow.error.code, expectedError.code);
  XCTAssertEqualObjects(authFlow.error.userInfo, expectedError.userInfo);
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (void)testMaybeFetchToken_authFlowError {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeUnknown
                                   userInfo:nil];

  OIDTokenResponse *tokenResponse = 
      [OIDTokenResponse testInstanceWithAccessTokenExpiresIn:@(kAccessTokenExpiresIn)];
  OIDAuthState *authState = [OIDAuthState testInstanceWithTokenResponse:tokenResponse];

  GIDAuthorizationResponseHandlingFake *responseHandler = 
      [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthState:authState error:nil];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:nil
                                                           error:error
                                                      emmSupport:nil
                                                     profileData:nil];

  [responseHandler maybeFetchToken:authFlow];
  XCTAssertNil(authFlow.authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error, error);
}

- (void)testMaybeFetchToken_noRefresh {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeUnknown
                                   userInfo:nil];

  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDAuthorizationResponseHandlingFake *responseHandler = 
      [[GIDAuthorizationResponseHandlingFake alloc] initWithAuthState:authState error:nil];
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] initWithAuthState:authState
                                                           error:error
                                                      emmSupport:nil
                                                     profileData:nil];

  [responseHandler maybeFetchToken:authFlow];
  XCTAssertNotNil(authFlow.authState);
  XCTAssertEqual(authFlow.authState, authState);
  XCTAssertNotNil(authFlow.error);
  XCTAssertEqual(authFlow.error, error);
}

@end
