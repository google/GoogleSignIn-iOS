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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthentication.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

@interface GIDGoogleUserTest : XCTestCase
@end

@implementation GIDGoogleUserTest

#pragma mark - Tests

- (void)testInitWithAuthState {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                     profileData:[GIDProfileData testInstance]];
  GIDAuthentication *authentication =
      [[GIDAuthentication alloc] initWithAuthState:authState];

  XCTAssertEqualObjects(user.authentication, authentication);
  XCTAssertEqualObjects(user.grantedScopes, @[ OIDAuthorizationRequestTestingScope2 ]);
  XCTAssertEqualObjects(user.userID, kUserID);
  XCTAssertEqualObjects(user.hostedDomain, kHostedDomain);
  XCTAssertEqualObjects(user.serverAuthCode, kServerAuthCode);
  XCTAssertEqualObjects(user.profile, [GIDProfileData testInstance]);
}

- (void)testCoding {
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:[OIDAuthState testInstance]
                                                     profileData:[GIDProfileData testInstance]];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user];
  GIDGoogleUser *newUser = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(user, newUser);
  XCTAssertTrue(GIDGoogleUser.supportsSecureCoding);
}

@end
