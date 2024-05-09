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

#if TARGET_OS_IOS
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"

// Exception Reasons
static NSString * const kSchemesNotSupportedExceptionReason =
    @"Your app is missing support for the following URL schemes: fakeclientid";
static NSString * const kClientIDMissingExceptionReason =
    @"You must specify |clientID| in |GIDConfiguration|";
static NSString * const kMissingCurrentUserExceptionReason =
    @"|currentUser| must be set to verify.";
static NSString * const kMissingPresentingViewControllerExceptionReason =
    @"|presentingViewController| must be set.";

static NSString * const kClientId = @"FakeClientID";
static NSString * const kServerClientId = @"FakeServerClientID";
static NSString * const kOpenIDRealm = @"FakeRealm";
static NSString * const kFakeHostedDomain = @"fakehosteddomain.com";

@interface GIDVerifyAccountDetailTests : XCTestCase
/// The |UIViewController| object being tested.
@property UIViewController *presentingViewController;

/// Fake [NSBundle mainBundle].
@property GIDFakeMainBundle *fakeMainBundle;

/// The |GIDVerifyAccountDetail| object being tested.
@property GIDVerifyAccountDetail *verifyAccountDetail;

/// The list of account details when testing [GIDVerifiableAccountDetail].
@property NSArray<GIDVerifiableAccountDetail *> *verifiableAccountDetails;
@end

@implementation GIDVerifyAccountDetailTests

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];

  _presentingViewController = [[UIViewController alloc] init];

  _verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];

  GIDVerifiableAccountDetail *ageOver18Detail = 
      [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];
  _verifiableAccountDetails = @[ageOver18Detail];

  _fakeMainBundle = [[GIDFakeMainBundle alloc] initWithClientID:kClientId
                                                 serverClientID:kServerClientId
                                                   hostedDomain:kFakeHostedDomain
                                                    openIDRealm:kOpenIDRealm];
}

#pragma mark - Tests

- (void)testInit {
  [_fakeMainBundle startFakingWithClientID:kClientId];

  GIDVerifyAccountDetail *verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];
  XCTAssertNotNil(verifyAccountDetail.configuration);
  XCTAssertEqual(verifyAccountDetail.configuration.clientID, kClientId);
  XCTAssertNil(verifyAccountDetail.configuration.serverClientID);
  XCTAssertNil(verifyAccountDetail.configuration.hostedDomain);
  XCTAssertNil(verifyAccountDetail.configuration.openIDRealm);

  [_fakeMainBundle stopFaking];
}

- (void)testInit_noConfig {
  [_fakeMainBundle startFakingWithClientID:nil];
  GIDVerifyAccountDetail *verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];

  XCTAssertNil(verifyAccountDetail.configuration);

  [_fakeMainBundle stopFaking];
}


- (void)testInit_fullConfig {
  [_fakeMainBundle startFaking];

  GIDVerifyAccountDetail *verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];
  XCTAssertNotNil(verifyAccountDetail.configuration);
  XCTAssertEqual(verifyAccountDetail.configuration.clientID, kClientId);
  XCTAssertEqual(verifyAccountDetail.configuration.serverClientID, kServerClientId);
  XCTAssertEqual(verifyAccountDetail.configuration.hostedDomain, kFakeHostedDomain);
  XCTAssertEqual(verifyAccountDetail.configuration.openIDRealm, kOpenIDRealm);

  [_fakeMainBundle stopFaking];
}

- (void)testInit_invalidConfig {
  _fakeMainBundle = [[GIDFakeMainBundle alloc] initWithClientID:@[ @"bad", @"config", @"values" ]
                                                 serverClientID:nil
                                                   hostedDomain:nil
                                                    openIDRealm:nil];
  [_fakeMainBundle startFaking];

  GIDVerifyAccountDetail *verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];
  XCTAssertNil(verifyAccountDetail.configuration);

  [_fakeMainBundle stopFaking];
}

- (void)testInitWithConfig_noConfig {
  GIDVerifyAccountDetail *verifyAccountDetail = [[GIDVerifyAccountDetail alloc] initWithConfig:nil];
  XCTAssertNil(verifyAccountDetail.configuration);
}

- (void)testInitWithConfig_fullConfig {
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                                serverClientID:kServerClientId
                                                                  hostedDomain:kFakeHostedDomain
                                                                   openIDRealm:kOpenIDRealm];

  GIDVerifyAccountDetail *verifyAccountDetail =
      [[GIDVerifyAccountDetail alloc] initWithConfig:configuration];
  XCTAssertNotNil(verifyAccountDetail.configuration);
  XCTAssertEqual(verifyAccountDetail.configuration.clientID, kClientId);
  XCTAssertEqual(verifyAccountDetail.configuration.serverClientID, kServerClientId);
  XCTAssertEqual(verifyAccountDetail.configuration.hostedDomain, kFakeHostedDomain);
  XCTAssertEqual(verifyAccountDetail.configuration.openIDRealm, kOpenIDRealm);
}

- (void)testCurrentUserException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  _verifyAccountDetail.configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  GIDSignIn.sharedInstance.currentUser = nil;

  @try {
    [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                      presentingViewController:_presentingViewController
                                    completion:nil];
  } @catch (NSException *exception) {
    XCTAssertEqual(exception.name, NSInvalidArgumentException);
    XCTAssertEqualObjects(exception.reason, kMissingCurrentUserExceptionReason);
  }
}

- (void)testPresentingViewControllerException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  _verifyAccountDetail.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId];
#pragma GCC diagnostic pop
  _presentingViewController = nil;

  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDSignIn.sharedInstance.currentUser = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                                      profileData:nil];
  @try {
    [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                      presentingViewController:_presentingViewController
                                    completion:nil];
  } @catch (NSException *exception) {
    XCTAssertEqual(exception.name, NSInvalidArgumentException);
    XCTAssertEqualObjects(exception.reason, kMissingPresentingViewControllerExceptionReason);
  }
}

- (void)testClientIDMissingException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  _verifyAccountDetail.configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop

  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDSignIn.sharedInstance.currentUser = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                                      profileData:nil];

  @try {
    [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                      presentingViewController:_presentingViewController
                                    completion:nil];
  } @catch (NSException *exception) {
    XCTAssertEqual(exception.name, NSInvalidArgumentException);
    XCTAssertEqualObjects(exception.reason, kClientIDMissingExceptionReason);
  }
}

- (void)testSchemesNotSupportedException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  _verifyAccountDetail.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId];
#pragma GCC diagnostic pop

  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDSignIn.sharedInstance.currentUser = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                                      profileData:nil];

  @try {
    [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                      presentingViewController:_presentingViewController
                                    completion:nil];
  } @catch (NSException *exception) {
    XCTAssertEqual(exception.name, NSInvalidArgumentException);
    XCTAssertEqualObjects(exception.reason, kSchemesNotSupportedExceptionReason);
  }
}

@end

#endif // TARGET_OS_IOS
