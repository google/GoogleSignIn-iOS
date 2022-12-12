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
#import <TargetConditionals.h>

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDToken.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Tests/Unit/GIDGoogleUser+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GoogleUtilities_MethodSwizzler;
@import GoogleUtilities_SwizzlerTestHelpers;
@import GTMAppAuth;
@import OCMock;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDIDToken.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kNewAccessToken = @"new_access_token";
static NSString *const kNewRefreshToken = @"new_refresh_token";

static NSTimeInterval const kTimeAccuracy = 10;
static NSTimeInterval const kIDTokenExpiresIn = 100;
static NSTimeInterval const kNewIDTokenExpiresIn = 200;

static NSString *const kNewScope = @"newScope";

@interface GIDGoogleUserTest : XCTestCase
@end

@implementation GIDGoogleUserTest {
  // The saved token fetch handler.
  OIDTokenCallback _tokenFetchHandler;
}

- (void)setUp {
  _tokenFetchHandler = nil;
  
  // We need to use swizzle here because OCMock can not stub class method with arguments.
  [GULSwizzler swizzleClass:[OIDAuthorizationService class]
                    selector:@selector(performTokenRequest:originalAuthorizationResponse:callback:)
            isClassSelector:YES
                  withBlock:^(id sender,
                              OIDTokenRequest *request,
                              OIDAuthorizationResponse *authorizationResponse,
                              OIDTokenCallback callback) {
    // Save the OIDTokenCallback.
    self->_tokenFetchHandler = [callback copy];
  }];
}

- (void)tearDown {
  [GULSwizzler unswizzleClass:[OIDAuthorizationService class]
                     selector:@selector(performTokenRequest:originalAuthorizationResponse:callback:)
              isClassSelector:YES];
}

#pragma mark - Tests

- (void)testInitWithAuthState {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                     profileData:[GIDProfileData testInstance]];
  
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

// Test the old encoding format for backword compatability.
- (void)testOldFormatCoding {
  if (@available(iOS 11, macOS 10.13, *)) {
    OIDAuthState *authState = [OIDAuthState testInstance];
    GIDProfileData *profileDate = [GIDProfileData testInstance];
    GIDGoogleUserOldFormat *user = [[GIDGoogleUserOldFormat alloc] initWithAuthState:authState
                                                                         profileData:profileDate];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user
                                         requiringSecureCoding:YES
                                                         error:nil];
    GIDGoogleUser *newUser = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDGoogleUser class]
                                                               fromData:data
                                                                  error:nil];
    XCTAssertEqualObjects(user, newUser);
  }
}

- (void)testUpdateAuthState {
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                idTokenExpiresIn:kIDTokenExpiresIn];
  
  NSString *updatedIDToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  OIDAuthState *updatedAuthState = [OIDAuthState testInstanceWithIDToken:updatedIDToken
                                                             accessToken:kNewAccessToken
                                                    accessTokenExpiresIn:kAccessTokenExpiresIn
                                                            refreshToken:kNewRefreshToken];
  GIDProfileData *updatedProfileData = [GIDProfileData testInstance];
  
  [user updateWithTokenResponse:updatedAuthState.lastTokenResponse
          authorizationResponse:updatedAuthState.lastAuthorizationResponse
                    profileData:updatedProfileData];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
  [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
  
  XCTAssertEqualObjects(user.idToken.tokenString, updatedIDToken);
  [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  
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
  
  [user updateWithTokenResponse:authState.lastTokenResponse
          authorizationResponse:authState.lastAuthorizationResponse
                    profileData:nil];
  
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

- (void)testFetcherAuthorizer_returnTheSameInstance {
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                idTokenExpiresIn:kIDTokenExpiresIn];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer = user.fetcherAuthorizer;
  id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer2 = user.fetcherAuthorizer;
#pragma clang diagnostic pop

  XCTAssertIdentical(fetcherAuthorizer, fetcherAuthorizer2);
}

#pragma mark - Test `refreshTokensIfNeededWithCompletion:`

- (void)testRefreshTokensIfNeededWithCompletion_refresh_givenBothTokensExpired {
  // Both tokens expired 10 seconds ago.
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:-10 idTokenExpiresIn:-10];
  NSString *newIdToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error);
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    XCTAssertEqualObjects(user.idToken.tokenString, newIdToken);
    [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  }];
  
  // Creates a fake response.
  OIDTokenResponse *fakeResponse = [OIDTokenResponse testInstanceWithIDToken:newIdToken
                                                                 accessToken:kNewAccessToken
                                                                   expiresIn:@(kAccessTokenExpiresIn)
                                                                refreshToken:kRefreshToken
                                                                tokenRequest:nil];
  
  _tokenFetchHandler(fakeResponse, nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokens_refresh_givenBothTokensExpired_NoNewIDToken {
  // Both tokens expired 10 seconds ago.
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:-10 idTokenExpiresIn:-10];
  // Creates a fake response without ID token.
  
  OIDTokenResponse *fakeResponse = [OIDTokenResponse testInstanceWithIDToken:nil
                                                                 accessToken:kNewAccessToken
                                                                   expiresIn:@(kAccessTokenExpiresIn)
                                                                refreshToken:kRefreshToken
                                                                tokenRequest:nil];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error);
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    XCTAssertNil(user.idToken);
  }];
  
  
  _tokenFetchHandler(fakeResponse, nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokensIfNeededWithCompletion_refresh_givenAccessTokenExpired {
  // Access token expired 10 seconds ago. ID token will expire in 10 minutes.
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:-10 idTokenExpiresIn:10 * 60];
  // Creates a fake response.
  NSString *newIdToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  OIDTokenResponse *fakeResponse = [OIDTokenResponse testInstanceWithIDToken:newIdToken
                                                                 accessToken:kNewAccessToken
                                                                   expiresIn:@(kAccessTokenExpiresIn)
                                                                refreshToken:kRefreshToken
                                                                tokenRequest:nil];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error);
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    XCTAssertEqualObjects(user.idToken.tokenString, newIdToken);
    [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  }];
  
  
  _tokenFetchHandler(fakeResponse, nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokensIfNeededWithCompletion_refresh_givenIDTokenExpired {
  // ID token expired 10 seconds ago. Access token will expire in 10 minutes.
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:10 * 60 idTokenExpiresIn:-10];
  
  // Creates a fake response.
  NSString *newIdToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  OIDTokenResponse *fakeResponse = [OIDTokenResponse testInstanceWithIDToken:newIdToken
                                                                 accessToken:kNewAccessToken
                                                                   expiresIn:@(kAccessTokenExpiresIn)
                                                                refreshToken:kRefreshToken
                                                                tokenRequest:nil];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error);
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    
    XCTAssertEqualObjects(user.idToken.tokenString, newIdToken);
    [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  }];
  
  
  _tokenFetchHandler(fakeResponse, nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRefreshTokensIfNeededWithCompletion_noRefresh_givenBothTokensNotExpired {
  // Both tokens will expire in 10 min.
  NSTimeInterval expiresIn = 10 * 60;
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:expiresIn
                                                idTokenExpiresIn:expiresIn];
  
  NSString *accessTokenStringBeforeRefresh = user.accessToken.tokenString;
  NSString *idTokenStringBeforeRefresh = user.idToken.tokenString;
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error);
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, accessTokenStringBeforeRefresh);
  [self verifyUser:user accessTokenExpiresIn:expiresIn];
  XCTAssertEqualObjects(user.idToken.tokenString, idTokenStringBeforeRefresh);
  [self verifyUser:user idTokenExpiresIn:expiresIn];
}

- (void)testRefreshTokensIfNeededWithCompletion_noRefresh_givenRefreshErrors {
  // Both tokens expired 10 second ago.
  NSTimeInterval expiresIn = -10;
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:expiresIn
                                                idTokenExpiresIn:expiresIn];
  
  NSString *accessTokenStringBeforeRefresh = user.accessToken.tokenString;
  NSString *idTokenStringBeforeRefresh = user.idToken.tokenString;
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  
  // Save the intermediate states.
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser * _Nullable user,
                                              NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNotNil(error);
    XCTAssertNil(user);
  }];
  
  _tokenFetchHandler(nil, [self fakeError]);
  [self waitForExpectationsWithTimeout:1 handler:nil];
  
  XCTAssertEqualObjects(user.accessToken.tokenString, accessTokenStringBeforeRefresh);
  [self verifyUser:user accessTokenExpiresIn:expiresIn];
  XCTAssertEqualObjects(user.idToken.tokenString, idTokenStringBeforeRefresh);
  [self verifyUser:user idTokenExpiresIn:expiresIn];
}

- (void)testRefreshTokensIfNeededWithCompletion_handleConcurrentRefresh {
  // Both tokens expired 10 second ago.
  NSTimeInterval expiresIn = -10;
  GIDGoogleUser *user = [self googleUserWithAccessTokenExpiresIn:expiresIn
                                                idTokenExpiresIn:expiresIn];
  // Creates a fake response.
  NSString *newIdToken = [self idTokenWithExpiresIn:kNewIDTokenExpiresIn];
  OIDTokenResponse *fakeResponse = [OIDTokenResponse testInstanceWithIDToken:newIdToken
                                                                 accessToken:kNewAccessToken
                                                                   expiresIn:@(kAccessTokenExpiresIn)
                                                                refreshToken:kRefreshToken
                                                                tokenRequest:nil];
  
  XCTestExpectation *firstExpectation =
      [self expectationWithDescription:@"First callback is called"];
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser *user, NSError *error) {
    [firstExpectation fulfill];
    XCTAssertNil(error);
    
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    
    XCTAssertEqualObjects(user.idToken.tokenString, newIdToken);
    [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  }];
  XCTestExpectation *secondExpectation =
      [self expectationWithDescription:@"Second callback is called"];
  [user refreshTokensIfNeededWithCompletion:^(GIDGoogleUser *user, NSError *error) {
    [secondExpectation fulfill];
    XCTAssertNil(error);
    
    XCTAssertEqualObjects(user.accessToken.tokenString, kNewAccessToken);
    [self verifyUser:user accessTokenExpiresIn:kAccessTokenExpiresIn];
    
    XCTAssertEqualObjects(user.idToken.tokenString, newIdToken);
    [self verifyUser:user idTokenExpiresIn:kNewIDTokenExpiresIn];
  }];
  
  
  _tokenFetchHandler(fakeResponse, nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

# pragma mark - Test `addScopes:`

- (void)testAddScopes_success {
  id signIn = OCMClassMock([GIDSignIn class]);
  OCMStub([signIn sharedInstance]).andReturn(signIn);
  [[signIn expect] addScopes:OCMOCK_ANY
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
      presentingViewController:OCMOCK_ANY
#elif TARGET_OS_OSX
              presentingWindow:OCMOCK_ANY
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                    completion:OCMOCK_ANY];
  
  GIDGoogleUser *currentUser = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                       idTokenExpiresIn:kIDTokenExpiresIn];
  
  OCMStub([signIn currentUser]).andReturn(currentUser);
  
  [currentUser addScopes:@[kNewScope]
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
      presentingViewController:[[UIViewController alloc] init]
#elif TARGET_OS_OSX
              presentingWindow:[[NSWindow alloc] init]
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                    completion:nil];
  
  [signIn verify];
}

- (void)testAddScopes_failure_addScopesToPreviousUser {
  id signIn = OCMClassMock([GIDSignIn class]);
  OCMStub([signIn sharedInstance]).andReturn(signIn);

  GIDGoogleUser *currentUser = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                       idTokenExpiresIn:kIDTokenExpiresIn];
  
  OCMStub([signIn currentUser]).andReturn(currentUser);
  
  GIDGoogleUser *previousUser = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                        idTokenExpiresIn:kNewIDTokenExpiresIn];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Completion is called."];
  
  [previousUser addScopes:@[kNewScope]
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
      presentingViewController:[[UIViewController alloc] init]
#elif TARGET_OS_OSX
              presentingWindow:[[NSWindow alloc] init]
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                    completion:^(GIDSignInResult *signInResult, NSError *error) {
    [expectation fulfill];
    XCTAssertNil(signInResult);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeMismatchWithCurrentUser);
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testAddScopes_failure_addScopesToPreviousUser_currentUserIsNull {
  id signIn = OCMClassMock([GIDSignIn class]);
  OCMStub([signIn sharedInstance]).andReturn(signIn);

  GIDGoogleUser *currentUser = nil;
  OCMStub([signIn currentUser]).andReturn(currentUser);
  
  GIDGoogleUser *previousUser = [self googleUserWithAccessTokenExpiresIn:kAccessTokenExpiresIn
                                                        idTokenExpiresIn:kNewIDTokenExpiresIn];
  
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Completion is called."];
  
  [previousUser addScopes:@[kNewScope]
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
      presentingViewController:[[UIViewController alloc] init]
#elif TARGET_OS_OSX
              presentingWindow:[[NSWindow alloc] init]
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                    completion:^(GIDSignInResult *signInResult, NSError *error) {
    [expectation fulfill];
    XCTAssertNil(signInResult);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeMismatchWithCurrentUser);
  }];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Helpers

// Returns a GIDGoogleUser with different tokens expiresIn time. The token strings are constants.
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

- (void)verifyUser:(GIDGoogleUser *)user accessTokenExpiresIn:(NSTimeInterval)expiresIn {
  NSDate *expectedAccessTokenExpirationDate = [[NSDate date] dateByAddingTimeInterval:expiresIn];
  XCTAssertEqualWithAccuracy([user.accessToken.expirationDate timeIntervalSince1970],
                             [expectedAccessTokenExpirationDate timeIntervalSince1970],
                             kTimeAccuracy);
}

- (void)verifyUser:(GIDGoogleUser *)user idTokenExpiresIn:(NSTimeInterval)expiresIn {
  NSDate *expectedIDTokenExpirationDate = [[NSDate date] dateByAddingTimeInterval:expiresIn];
  XCTAssertEqualWithAccuracy([user.idToken.expirationDate timeIntervalSince1970],
                             [expectedIDTokenExpirationDate timeIntervalSince1970], kTimeAccuracy);
}

- (NSError *)fakeError {
  return [NSError errorWithDomain:@"fake.domain" code:-1 userInfo:nil];
}

@end
