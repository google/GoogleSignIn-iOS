// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDClaim.h"

#ifdef SWIFT_PACKAGE
@import OCMock;
#else
#import <OCMock/OCMock.h>
#endif

static NSString *const kLoginHint = @"login_hint";
static NSString *const kScope1 = @"scope1";
static NSString *const kScope2 = @"scope2";
static NSString *const kNonce = @"test_nonce";
static NSString *const kClaimsAsJSON = @"{\"claim\":\"value\"}";

@interface GIDSignInInternalOptionsTest : XCTestCase {
  // Mock for the configuration passed to the option factories.
  id _configuration;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  // Mock for the presenting view controller passed to the option factories.
  id _presentingViewController;
#elif TARGET_OS_OSX
  // Mock for the presenting window passed to the option factories.
  id _presentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
}
@end

@implementation GIDSignInInternalOptionsTest

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];
  _configuration = OCMStrictClassMock([GIDConfiguration class]);
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  _presentingViewController = OCMStrictClassMock([UIViewController class]);
#elif TARGET_OS_OSX
  _presentingWindow = OCMStrictClassMock([NSWindow class]);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
}

#pragma mark - Helpers

// The claim set requested by `-optionsWithAllParameters`. `GIDClaim` implements
// `-isEqual:` by name and essentiality, so a freshly built set compares equal.
- (NSSet<GIDClaim *> *)expectedClaims {
  return [NSSet setWithObject:[GIDClaim authTimeClaim]];
}

- (GIDSignInInternalOptions *)optionsWithAllParameters {
  GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                     NSError *_Nullable error) {};
  return [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                          presentingViewController:_presentingViewController
#elif TARGET_OS_OSX
                                                  presentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                         loginHint:kLoginHint
                                                     addScopesFlow:NO
                                                            scopes:@[kScope1, kScope2]
                                                             nonce:kNonce
                                                            claims:[self expectedClaims]
                                                        completion:completion];
}

// Verifies the mocks created in `-setUp` have no unfulfilled expectations.
- (void)verifyConfigurationAndPresentationMocks {
  OCMVerifyAll(_configuration);
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  OCMVerifyAll(_presentingViewController);
#elif TARGET_OS_OSX
  OCMVerifyAll(_presentingWindow);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
}

#pragma mark - Tests

- (void)testDefaultOptions {
  GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                     NSError *_Nullable error) {};
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:_presentingViewController
#elif TARGET_OS_OSX
                                               presentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                      loginHint:kLoginHint
                                                  addScopesFlow:NO
                                                     completion:completion];
  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertFalse(options.addScopesFlow);
  XCTAssertNil(options.extraParams);

  [self verifyConfigurationAndPresentationMocks];
}

- (void)testDefaultOptions_withAllParameters_initializesPropertiesCorrectly {
  NSArray<NSString *> *expectedScopes = @[kScope1, kScope2, @"email", @"profile"];

  GIDSignInInternalOptions *options = [self optionsWithAllParameters];

  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertFalse(options.addScopesFlow);
  XCTAssertNil(options.extraParams);

  // Convert arrays to sets for comparison to make the test order-independent.
  XCTAssertEqualObjects([NSSet setWithArray:options.scopes],
                        [NSSet setWithArray:expectedScopes]);
  XCTAssertEqualObjects(options.nonce, kNonce);
  XCTAssertEqualObjects(options.claims, [self expectedClaims]);
  XCTAssertNil(options.claimsAsJSON);

  [self verifyConfigurationAndPresentationMocks];
}

- (void)testOptionsWithExtraParameters_forContinuation_preservesAllPropertiesAndSetsContinuation {
  GIDSignInInternalOptions *options = [self optionsWithAllParameters];
  options.claimsAsJSON = kClaimsAsJSON;
  NSDictionary *extraParams = @{@"extra_key" : @"extra_value"};

  GIDSignInInternalOptions *continuationOptions =
      [options optionsWithExtraParameters:extraParams forContinuation:YES];

  XCTAssertEqualObjects(continuationOptions.nonce, kNonce);
  XCTAssertEqualObjects(continuationOptions.claims, [self expectedClaims]);
  XCTAssertEqualObjects(continuationOptions.claimsAsJSON, kClaimsAsJSON);
  XCTAssertTrue(continuationOptions.continuation);
  XCTAssertEqualObjects(continuationOptions.extraParams, extraParams);
  XCTAssertEqualObjects(continuationOptions.loginHint, kLoginHint);
  XCTAssertEqualObjects([NSSet setWithArray:continuationOptions.scopes],
                        [NSSet setWithArray:options.scopes]);
  XCTAssertFalse(continuationOptions.addScopesFlow);
  XCTAssertTrue(continuationOptions.interactive);

  [self verifyConfigurationAndPresentationMocks];
}

- (void)testSilentOptions {
  GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                     NSError * _Nullable error) {};
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions silentOptionsWithCompletion:completion];
  XCTAssertFalse(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);
  XCTAssertEqual(options.completion, completion);
}

@end
