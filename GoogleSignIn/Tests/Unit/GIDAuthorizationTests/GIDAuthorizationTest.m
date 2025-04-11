// Copyright 2025 Google LLC
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
#import "GoogleSignIn/Sources/GIDAuthorization_Private.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Fake/GIDAuthorizationFlowFake.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInResult_Private.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthorization.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignInResult.h"
#import "GoogleSignIn/Tests/Unit/GIDAuthorizationTests/GIDKeychainHelperFake.h"
#import "GoogleSignIn/Tests/Unit/GIDAuthorizationTests/GIDBundleFake.h"
#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"

static NSString *const kKeychainItemName = @"test_keychain_name";

@import GTMAppAuth;

@interface GIDAuthorizationTest : XCTestCase

@end

@implementation GIDAuthorizationTest

- (void)testAuthorizationConfigurationAssertValidParameters {
  GIDConfiguration *config =
    [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                serverClientID:kServerClientID
                                  hostedDomain:kHostedDomain
                                   openIDRealm:kOpenIDRealm];
  
  GIDSignInInternalOptions *opts = [GIDSignInInternalOptions defaultOptionsWithConfiguration:config
                                                                    presentingViewController:nil
                                                                                   loginHint:nil
                                                                               addScopesFlow:NO
                                                                                      bundle:nil
                                                                                  completion:nil];
  GIDAuthorizationFlowFake *fakeFlow = [[GIDAuthorizationFlowFake alloc] initWithSignInOptions:opts
                                                                                     authState:nil
                                                                                   profileData:nil
                                                                                    googleUser:nil
                                                                      externalUserAgentSession:nil
                                                                                    emmSupport:nil
                                                                                         error:nil];
  @try {
    GIDAuthorization *authorization = [[GIDAuthorization alloc] initWithKeychainStore:nil
                                                                        configuration:config
                                                         authorizationFlowCoordinator:fakeFlow];
    [authorization assertValidParameters];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have valid parameters.");
  }
  @finally {}
}

- (void)testAuthorizationConfigurationAssertValidPresentingController {
  
  UIViewController *vc = [[UIViewController alloc] init];
  GIDSignInInternalOptions *opts = [GIDSignInInternalOptions defaultOptionsWithConfiguration:nil
                                                                    presentingViewController:vc
                                                                                   loginHint:nil
                                                                               addScopesFlow:NO
                                                                                      bundle:nil
                                                                                  completion:nil];
  GIDAuthorizationFlowFake *fakeFlow = [[GIDAuthorizationFlowFake alloc] initWithSignInOptions:opts
                                                                                     authState:nil
                                                                                   profileData:nil
                                                                                    googleUser:nil
                                                                      externalUserAgentSession:nil
                                                                                    emmSupport:nil
                                                                                         error:nil];
  @try {
    GIDAuthorization *authorization = [[GIDAuthorization alloc] initWithKeychainStore:nil
                                                                        configuration:nil
                                                         authorizationFlowCoordinator:fakeFlow];
    [authorization assertValidPresentingController];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have a valid presenting controller.");
  }
  @finally {}
}

- (void)testThatAuthorizeInteractivelySetsCurrentUser {
  XCTestExpectation *currentUserExpectation =
    [self expectationWithDescription:@"Current user expectation"];
  GIDKeychainHelperFake *keychainFake =
    [[GIDKeychainHelperFake alloc] initWithKeychainAttributes:[NSSet setWithArray:@[]]];
  GTMKeychainStore *keychainStore = [[GTMKeychainStore alloc] initWithItemName:kKeychainItemName
                                                                keychainHelper:keychainFake];
  
  GIDConfiguration *config =
    [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                serverClientID:kServerClientID
                                  hostedDomain:kHostedDomain
                                   openIDRealm:kOpenIDRealm];
  UIViewController *vc = [[UIViewController alloc] init];
  
  OIDAuthState *expectedAuthState = [OIDAuthState testInstance];
  GIDProfileData *expectedProfileData = [GIDProfileData testInstanceWithImageURL:@"test.com"];
  GIDGoogleUser *expectedGoogleUser = [[GIDGoogleUser alloc] initWithAuthState:expectedAuthState
                                                                   profileData:expectedProfileData];
  
  GIDSignInCompletion comp = ^(GIDSignInResult *_Nullable result, NSError *_Nullable error) {
    XCTAssertNotNil(result, @"The sign in result should be non-nil.");
    XCTAssertNil(error, @"There should be no error from authorizing.");
    XCTAssertEqualObjects(expectedGoogleUser, result.user);
    XCTAssertEqualObjects(expectedAuthState, result.user.authState);
    XCTAssertEqualObjects(expectedProfileData, result.user.profile);
    [currentUserExpectation fulfill];
  };
  
  GIDBundleFake *bFake = [[GIDBundleFake alloc] init];
  GIDSignInInternalOptions *opts = [GIDSignInInternalOptions defaultOptionsWithConfiguration:config
                                                                    presentingViewController:vc
                                                                                   loginHint:nil
                                                                               addScopesFlow:NO
                                                                                      bundle:bFake
                                                                                  completion:comp];
  GIDAuthorizationFlowFake *fakeFlow =
    [[GIDAuthorizationFlowFake alloc] initWithSignInOptions:opts
                                                  authState:expectedAuthState
                                                profileData:expectedProfileData
                                                 googleUser:expectedGoogleUser
                                   externalUserAgentSession:nil
                                                 emmSupport:nil
                                                      error:nil];
  
  GIDAuthorization *auth = [[GIDAuthorization alloc] initWithKeychainStore:keychainStore
                                                             configuration:config
                                              authorizationFlowCoordinator:fakeFlow];
  [auth signInWithOptions:opts];
  [self waitForExpectations:@[currentUserExpectation] timeout:5];
  XCTAssertNotNil(auth.currentUser);
  XCTAssertEqualObjects(expectedGoogleUser, auth.currentUser);
}

@end
