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

#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/GIDAuthorizationFlowProcessor.h"

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

#import <XCTest/XCTest.h>

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import OCMock;
#else
#import <AppAuth/AppAuth.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kFakeURL = @"www.fakeURL.com";
static NSString *const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 400;
static NSInteger const kTimeout = 1;

@interface GIDAuthorizationFlowProcessorTest : XCTestCase {
  GIDAuthorizationFlowProcessor *_authorizationFlowProcessor;
  id _authorizationServiceMock;
  id _externalUserAgentSession;
}

@end

@implementation GIDAuthorizationFlowProcessorTest

- (void)setUp {
  [super setUp];
  
  _authorizationFlowProcessor = [[GIDAuthorizationFlowProcessor alloc] init];
  _externalUserAgentSession = OCMProtocolMock(@protocol(OIDExternalUserAgentSession));
  _authorizationServiceMock = OCMClassMock([OIDAuthorizationService class]);
  OIDAuthorizationResponse *response = [OIDAuthorizationResponse testInstance];
  NSError *error = [self error];
  OCMStub([_authorizationServiceMock
      presentAuthorizationRequest:[OCMArg any]
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
         presentingViewController:[OCMArg any]
#elif TARGET_OS_OSX
                 presentingWindow:[OCMArg any]
#endif // TARGET_OS_OSX
                         callback:([OCMArg invokeBlockWithArgs:response, error, nil])
          ]).andReturn(_externalUserAgentSession);
}

- (void)testStartAndCancelAuthorizationFlow_success {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completion is invoked."];
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  [_authorizationFlowProcessor startWithOptions:options
                                     emmSupport:nil
                                     completion:^(OIDAuthorizationResponse *authorizationResponse,
                                                  NSError *error) {
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
  XCTAssertTrue(_authorizationFlowProcessor.isStarted);
  
  [_authorizationFlowProcessor cancelAuthenticationFlow];
  XCTAssertFalse(_authorizationFlowProcessor.isStarted);
}

- (void)testStartAndResumeAuthorizationFlow_success {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completion is invoked."];
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  [_authorizationFlowProcessor startWithOptions:options
                                     emmSupport:nil
                                     completion:^(OIDAuthorizationResponse *authorizationResponse,
                                                  NSError *error) {
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_authorizationFlowProcessor.isStarted);
  
  OCMStub([_externalUserAgentSession resumeExternalUserAgentFlowWithURL:[OCMArg any]])
      .andReturn(YES);
  NSURL *url = [[NSURL alloc] initWithString:kFakeURL];
  [_authorizationFlowProcessor resumeExternalUserAgentFlowWithURL:url];
  XCTAssertFalse(_authorizationFlowProcessor.isStarted);
}

- (void)testStartAndFailToResumeAuthorizationFlow {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completion is invoked."];
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  [_authorizationFlowProcessor startWithOptions:options
                                     emmSupport:nil
                                     completion:^(OIDAuthorizationResponse *authorizationResponse,
                                                  NSError *error) {
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
  XCTAssertTrue(_authorizationFlowProcessor.isStarted);
 
  OCMStub([_externalUserAgentSession resumeExternalUserAgentFlowWithURL:[OCMArg any]])
      .andReturn(NO);
  NSURL *url = [[NSURL alloc] initWithString:kFakeURL];
  [_authorizationFlowProcessor resumeExternalUserAgentFlowWithURL:url];
  XCTAssertTrue(_authorizationFlowProcessor.isStarted);
}

#pragma mark - Helpers

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

@end
