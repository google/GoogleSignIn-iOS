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
// The difference between times.
// It should be larger than kTimeAccuracy which is used in the method `XCTAssertEqualWithAccuracy`.
static NSTimeInterval const kTimeIncrement = 100;

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
  NSTimeInterval accessTokenExpireTime = [[NSDate date] timeIntervalSince1970];
  NSTimeInterval idTokenExpireTime = accessTokenExpireTime + kTimeIncrement;
  
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpireTime:accessTokenExpireTime
                                                idTokenExpireTime:idTokenExpireTime];
  
  NSTimeInterval updatedAccessTokenExpireTime = idTokenExpireTime + kTimeIncrement;
  NSTimeInterval updatedIDTokenExpireTime = updatedAccessTokenExpireTime + kTimeIncrement;
  NSString *updatedIDToken = [self idTokenWithExpireTime:updatedIDTokenExpireTime];
  OIDAuthState *updatedAuthState = [OIDAuthState testInstanceWithIDToken:updatedIDToken
                                                             accessToken:kNewAccessToken
                                                   accessTokenExpireTime:updatedAccessTokenExpireTime
                                                            refreshToken:kNewRefreshToken];
  GIDProfileData *updatedProfileData = [GIDProfileData testInstance];
  
  [user updateAuthState:updatedAuthState profileData:updatedProfileData];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
  XCTAssertEqualWithAccuracy([user.accessToken.expirationDate timeIntervalSince1970],
                             updatedAccessTokenExpireTime, kTimeAccuracy);
  XCTAssertEqualObjects(user.idToken.tokenString, updatedIDToken);
  XCTAssertEqualWithAccuracy([user.idToken.expirationDate timeIntervalSince1970],
                             updatedIDTokenExpireTime, kTimeAccuracy);
  XCTAssertEqualObjects(user.refreshToken.tokenString, kNewRefreshToken);
  XCTAssertEqual(user.profile, updatedProfileData);
}

#pragma mark - Helpers

- (GIDGoogleUser *)googleUserWithAccessTokenExpireTime:(NSTimeInterval)accessTokenExpireTime
                                     idTokenExpireTime:(NSTimeInterval)idTokenExpireTime {
  NSString *idToken = [self idTokenWithExpireTime:idTokenExpireTime];
  OIDAuthState *authState = [OIDAuthState testInstanceWithIDToken:idToken
                                                      accessToken:kAccessToken
                                            accessTokenExpireTime:accessTokenExpireTime
                                                     refreshToken:kRefreshToken];
  
  return [[GIDGoogleUser alloc] initWithAuthState:authState profileData:nil];
}

// The expireTime should be based on 1970.
- (NSString *)idTokenWithExpireTime:(NSTimeInterval)expireTime {
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(expireTime)];
}

@end
