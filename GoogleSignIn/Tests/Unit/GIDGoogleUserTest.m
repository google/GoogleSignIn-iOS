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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDToken.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

static NSString *const kNewAccessToken = @"new_access_token";
static NSString *const kNewRefreshToken = @"new_refresh_token";

static NSTimeInterval const kTimeAccuracy = 10;
static NSTimeInterval const kIDTokenExpiresIn = 100;
static NSTimeInterval const kNewIDTokenExpiresIn = 200;

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
  XCTAssertEqualObjects(user.configuration.hostedDomain, kHostedDomain);
  XCTAssertEqualObjects(user.configuration.clientID, OIDAuthorizationRequestTestingClientID);
  XCTAssertEqualObjects(user.profile, [GIDProfileData testInstance]);
  XCTAssertEqualObjects(user.accessToken.tokenString, kAccessToken);
  XCTAssertEqualObjects(user.refreshToken.tokenString, kRefreshToken);
  
  OIDIDToken *idToken = [[OIDIDToken alloc]
      initWithIDTokenString:authState.lastTokenResponse.idToken];
  XCTAssertEqualObjects(user.idToken.expirationDate, [idToken expiresAt]);
}

- (void)testCoding {
  if (@available(iOS 11, macOS 10.13, *)) {
    GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:[OIDAuthState testInstance]
                                                       profileData:[GIDProfileData testInstance]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user
                                         requiringSecureCoding:YES
                                                         error:nil];
    GIDGoogleUser *newUser = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDGoogleUser class]
                                                               fromData:data
                                                                  error:nil];
    XCTAssertEqualObjects(user, newUser);
    XCTAssertTrue(GIDGoogleUser.supportsSecureCoding);
  }  else {
    XCTSkip(@"Required API is not available for this test.");
  }
}

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
// Deprecated in iOS 13 and macOS 10.14
- (void)testLegacyCoding {
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:[OIDAuthState testInstance]
                                                     profileData:[GIDProfileData testInstance]];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user];
  GIDGoogleUser *newUser = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(user, newUser);
  XCTAssertTrue(GIDGoogleUser.supportsSecureCoding);
}
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

- (void)testUpdateAuthState {
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                idTokenExpiresIn:kIDTokenExpiresIn];
  
  NSString *updatedIDToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  OIDAuthState *updatedAuthState = [OIDAuthState testInstanceWithIDToken:updatedIDToken
                                                             accessToken:kNewAccessToken
                                                    accessTokenExpiresIn:kAccessTokenExpiresIn
                                                            refreshToken:kNewRefreshToken];
  GIDProfileData *updatedProfileData = [GIDProfileData testInstance];
  
  [user updateAuthState:updatedAuthState profileData:updatedProfileData];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
  NSDate *expectedAccessTokenExpirationDate = [[NSDate date] dateByAddingTimeInterval:kAccessTokenExpiresIn];
  XCTAssertEqualWithAccuracy([user.accessToken.expirationDate timeIntervalSince1970],
                             [expectedAccessTokenExpirationDate timeIntervalSince1970], kTimeAccuracy);
  
  XCTAssertEqualObjects(user.idToken.tokenString, updatedIDToken);
  NSDate *expectedIDTokenExpirationDate = [[NSDate date] dateByAddingTimeInterval:kNewIDTokenExpiresIn];
  XCTAssertEqualWithAccuracy([user.idToken.expirationDate timeIntervalSince1970],
                             [expectedIDTokenExpirationDate timeIntervalSince1970], kTimeAccuracy);
  
  XCTAssertEqualObjects(user.refreshToken.tokenString, kNewRefreshToken);
  
  XCTAssertEqual(user.profile, updatedProfileData);
}

// When updating with a new OIDAuthState in which token information is not changed, the token objects
// should remain the same.
- (void)testUpdateAuthState_tokensAreNotChanged {
  NSString *idToken = [self idTokenWithExpiresIn:kIDTokenExpiresIn];
  OIDAuthState *authState = [OIDAuthState testInstanceWithIDToken:idToken
                                                      accessToken:kAccessToken
                                             accessTokenExpiresIn:kAccessTokenExpiresIn
                                                     refreshToken:kRefreshToken];
  
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState profileData:nil];
  
  GIDToken *accessTokenBeforeUpdate = user.accessToken;
  GIDToken *refreshTokenBeforeUpdate = user.refreshToken;
  GIDToken *idTokenBeforeUpdate = user.idToken;
  
  [user updateAuthState:authState profileData:nil];
  
  XCTAssertIdentical(user.accessToken, accessTokenBeforeUpdate);
  XCTAssertIdentical(user.idToken, idTokenBeforeUpdate);
  XCTAssertIdentical(user.refreshToken, refreshTokenBeforeUpdate);
}

- (void)testFetcherAuthorizer {
  // This is really hard to test without assuming how GTMAppAuthFetcherAuthorization works
  // internally, so let's just take the shortcut here by asserting we get a
  // GTMAppAuthFetcherAuthorization object.
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                idTokenExpiresIn:kIDTokenExpiresIn];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer = user.fetcherAuthorizer;
#pragma clang diagnostic pop
  XCTAssertTrue([fetcherAuthorizer isKindOfClass:[GTMAppAuthFetcherAuthorization class]]);
  XCTAssertTrue([fetcherAuthorizer canAuthorize]);
}

// TODO(pinlu): Add a test that the property `fetcherAuthorizer` returns the same instance
// after authState is updated.

#pragma mark - Helpers

- (GIDGoogleUser *)googleUserWithAccessTokenExpiresIn:(NSTimeInterval)accessTokenExpiresIn
                                     idTokenExpiresIn:(NSTimeInterval)idTokenExpiresIn {
  NSString *idToken = [self idTokenWithExpiresIn:idTokenExpiresIn];
  OIDAuthState *authState = [OIDAuthState testInstanceWithIDToken:idToken
                                                      accessToken:kAccessToken
                                             accessTokenExpiresIn:accessTokenExpiresIn
                                                     refreshToken:kRefreshToken];
  
  return [[GIDGoogleUser alloc] initWithAuthState:authState profileData:nil];
}

- (NSString *)idTokenWithExpiresIn:(NSTimeInterval)expiresIn {
  // The expireTime should be based on 1970.
  NSTimeInterval expireTime = [[NSDate date] timeIntervalSince1970] + expiresIn;
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(expireTime)];
}

@end
