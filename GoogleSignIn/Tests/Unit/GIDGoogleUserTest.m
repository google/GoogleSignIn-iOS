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
static NSTimeInterval const kExpireTime = 442886117;
static NSTimeInterval const kNewAccessTokenExpireTime = 442886123;
static NSTimeInterval const kNewIDTokenExpireTime = 442886124;

static NSTimeInterval const kTimeAccuracy = 10;

// List of observed properties of the class being tested.
static NSString *const kObservedProperties[] = {
  @"accessToken",
  @"refreshToken",
  @"idToken",
};
static const NSUInteger kNumberOfObservedProperties =
    sizeof(kObservedProperties) / sizeof(*kObservedProperties);

// Bit position for notification change type bitmask flags.
// Must match the list of observed properties above.
typedef NS_ENUM(NSUInteger, ChangeType) {
  kChangeTypeAccessTokenPrior,
  kChangeTypeAccessToken,
  kChangeTypeRefreshTokenPrior,
  kChangeTypeRefreshToken,
  kChangeTypeIDTokenPrior,
  kChangeTypeIDToken,
  kChangeTypeEnd  // not a real change type but an end mark for calculating |kChangeAll|
};

static const NSUInteger kChangeNone = 0u;
static const NSUInteger kChangeAll = (1u << kChangeTypeEnd) - 1u;

#if __has_feature(c_static_assert) || __has_extension(c_static_assert)
_Static_assert(kChangeTypeEnd == (sizeof(kObservedProperties) / sizeof(*kObservedProperties)) * 2,
               "List of observed properties must match list of change notification enums");
#endif

@interface GIDGoogleUserTest : XCTestCase
@end

@implementation GIDGoogleUserTest {
  // Fake data used to generate the expiration date of the access token.
  NSTimeInterval _accessTokenExpireTime;
  
  // Fake data used to generate the expiration date of the ID token.
  NSTimeInterval _idTokenExpireTime;

  // Bitmask flags for observed changes, as specified in |ChangeType|.
  NSUInteger _changesObserved;
}

- (void)setUp {
  _accessTokenExpireTime = kAccessTokenExpiresIn;
  _idTokenExpireTime = kExpireTime;
  _changesObserved = 0;
}

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

- (void) testUpdateAuthState {
  GIDGoogleUser *user = [self observedGoogleUser];
  XCTAssertEqualObjects(user.accessToken.tokenString, kAccessToken);
  [self assertDate:user.accessToken.expirationDate equalTime:_accessTokenExpireTime];
  XCTAssertEqualObjects(user.idToken.tokenString, [self idToken]);
  [self assertDate:user.idToken.expirationDate equalTime:_idTokenExpireTime];
  
  OIDAuthState *newAuthState = [self newAuthState];
  [user updateAuthState:newAuthState profileData:nil];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
  [self assertDate:user.accessToken.expirationDate equalTime:kNewAccessTokenExpireTime];
  XCTAssertEqualObjects(user.idToken.tokenString, [self idTokenNew]);
  [self assertDate:user.idToken.expirationDate equalTime:kNewIDTokenExpireTime];
  XCTAssertEqual(_changesObserved, kChangeAll);
}

#pragma mark - Helpers

- (GIDGoogleUser *)observedGoogleUser {
  GIDGoogleUser *user = [self googleUser];
  for (unsigned int i = 0; i < kNumberOfObservedProperties; ++i) {
    [user addObserver:self
           forKeyPath:kObservedProperties[i]
              options:NSKeyValueObservingOptionPrior
              context:NULL];
  }
  return user;
}

- (GIDGoogleUser *)googleUser {
  NSString *idToken = [self idToken];
  NSNumber *accessTokenExpiresIn =
      @(_accessTokenExpireTime - [[NSDate date] timeIntervalSinceReferenceDate]);
  OIDTokenRequest *tokenRequest =
      [OIDTokenRequest testInstanceWithAdditionalParameters:nil];
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:idToken
                                    accessToken:kAccessToken
                                      expiresIn:accessTokenExpiresIn
                                   tokenRequest:tokenRequest];
  return [[GIDGoogleUser alloc]
          initWithAuthState:[OIDAuthState testInstanceWithTokenResponse:tokenResponse]
                profileData:nil];
}

- (NSString *)idToken {
  return [self idTokenWithExpireTime:_idTokenExpireTime];
}

- (NSString *)idTokenNew {
  return [self idTokenWithExpireTime:kNewIDTokenExpireTime];
}

- (NSString *)idTokenWithExpireTime:(NSTimeInterval)expireTime {
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(expireTime + NSTimeIntervalSince1970)];
}

- (OIDAuthState *)newAuthState {
  NSNumber *expiresIn = @(kNewAccessTokenExpireTime - [NSDate timeIntervalSinceReferenceDate]);
  OIDTokenResponse *newResponse =
    [OIDTokenResponse testInstanceWithIDToken:[self idTokenNew]
                                  accessToken:kNewAccessToken
                                    expiresIn:expiresIn
                                 tokenRequest:nil];
  return [OIDAuthState testInstanceWithTokenResponse:newResponse];
}

- (void)assertDate:(NSDate *)date equalTime:(NSTimeInterval)time {
  XCTAssertEqualWithAccuracy([date timeIntervalSinceReferenceDate], time, kTimeAccuracy);
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  GIDGoogleUser *user = (GIDGoogleUser*)object;
  ChangeType changeType;
  if ([keyPath isEqualToString:@"accessToken"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      XCTAssertEqualObjects(user.accessToken.tokenString, kAccessToken);
      [self assertDate:user.accessToken.expirationDate equalTime:_accessTokenExpireTime];
      changeType = kChangeTypeAccessTokenPrior;
    } else {
      XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
      [self assertDate:user.accessToken.expirationDate equalTime:kNewAccessTokenExpireTime];
      changeType = kChangeTypeAccessToken;
    }
  } else if ([keyPath isEqualToString:@"refreshToken"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      changeType = kChangeTypeRefreshTokenPrior;
    } else {
      changeType = kChangeTypeRefreshToken;
    }
  } else if ([keyPath isEqualToString:@"idToken"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      XCTAssertEqualObjects(user.idToken.tokenString, [self idToken]);
      [self assertDate:user.idToken.expirationDate equalTime:_idTokenExpireTime];
      changeType = kChangeTypeIDTokenPrior;
    } else {
      XCTAssertEqualObjects(user.idToken.tokenString, [self idTokenNew]);
      [self assertDate:user.idToken.expirationDate equalTime:kNewIDTokenExpireTime];
      changeType = kChangeTypeIDToken;
    }
  } else {
    XCTFail(@"unexpected keyPath");
    return;  // so compiler knows |changeType| is always assigned
  }
  
  NSInteger changeMask = 1 << changeType;
  XCTAssertFalse(_changesObserved & changeMask);  // each change type should only fire once
  _changesObserved |= changeMask;
}

@end
