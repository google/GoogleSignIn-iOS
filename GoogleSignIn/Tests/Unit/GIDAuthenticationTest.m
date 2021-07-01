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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthentication.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GoogleUtilities_MethodSwizzler;
@import GoogleUtilities_SwizzlerTestHelpers;
@import GTMAppAuth;
@import GTMSessionFetcherCore;
@import OCMock;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDIDToken.h>
#import <AppAuth/OIDServiceConfiguration.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kClientID = @"87654321.googleusercontent.com";
static NSString *const kNewAccessToken = @"new_access_token";
static NSString *const kUserEmail = @"foo@gmail.com";
static NSTimeInterval const kExpireTime = 442886117;
static NSTimeInterval const kNewExpireTime = 442886123;
static NSTimeInterval const kNewExpireTime2 = 442886124;

static NSTimeInterval const kTimeAccuracy = 10;

// The system name in old iOS versions.
static NSString *const kOldIOSName = @"iPhone OS";

// The system name in new iOS versions.
static NSString *const kNewIOSName = @"iOS";

// List of observed properties of the class being tested.
static NSString *const kObservedProperties[] = {
  @"accessToken",
  @"accessTokenExpirationDate",
  @"idToken",
  @"idTokenExpirationDate"
};
static const NSUInteger kNumberOfObservedProperties =
    sizeof(kObservedProperties) / sizeof(*kObservedProperties);

// Bit position for notification change type bitmask flags.
// Must match the list of observed properties above.
typedef NS_ENUM(NSUInteger, ChangeType) {
  kChangeTypeAccessTokenPrior,
  kChangeTypeAccessToken,
  kChangeTypeAccessTokenExpirationDatePrior,
  kChangeTypeAccessTokenExpirationDate,
  kChangeTypeIDTokenPrior,
  kChangeTypeIDToken,
  kChangeTypeIDTokenExpirationDatePrior,
  kChangeTypeIDTokenExpirationDate,
  kChangeTypeEnd  // not a real change type but an end mark for calculating |kChangeAll|
};

static const NSUInteger kChangeNone = 0u;
static const NSUInteger kChangeAll = (1u << kChangeTypeEnd) - 1u;

#if __has_feature(c_static_assert) || __has_extension(c_static_assert)
_Static_assert(kChangeTypeEnd == (sizeof(kObservedProperties) / sizeof(*kObservedProperties)) * 2,
               "List of observed properties must match list of change notification enums");
#endif

@interface GIDAuthenticationTest : XCTestCase
@end

@implementation GIDAuthenticationTest {
  // Whether the auth object has ID token or not.
  BOOL _hasIDToken;

  // Fake data used to generate the expiration date of the access token.
  NSTimeInterval _accessTokenExpireTime;

  // Fake data used to generate the expiration date of the ID token.
  NSTimeInterval _idTokenExpireTime;

  // Fake data used to generate the additional token request parameters.
  NSDictionary *_additionalTokenRequestParameters;

  // The saved token fetch handler.
  OIDTokenCallback _tokenFetchHandler;

  // The saved token request.
  OIDTokenRequest *_tokenRequest;

  // All GIDAuthentication objects that are observed.
  NSMutableArray *_observedAuths;

  // Bitmask flags for observed changes, as specified in |ChangeType|.
  NSUInteger _changesObserved;

  // The fake system name used for testing.
  NSString *_fakeSystemName;
}

- (void)setUp {
  _hasIDToken = YES;
  _accessTokenExpireTime = kAccessTokenExpiresIn;
  _idTokenExpireTime = kExpireTime;
  _additionalTokenRequestParameters = nil;
  _tokenFetchHandler = nil;
  _tokenRequest = nil;
  [GULSwizzler swizzleClass:[OIDAuthorizationService class]
                   selector:@selector(performTokenRequest:originalAuthorizationResponse:callback:)
            isClassSelector:YES
                  withBlock:^(id sender,
                              OIDTokenRequest *request,
                              OIDAuthorizationResponse *authorizationResponse,
                              OIDTokenCallback callback) {
    XCTAssertNotNil(authorizationResponse.request.clientID);
    XCTAssertNotNil(authorizationResponse.request.configuration.tokenEndpoint);
    XCTAssertNil(self->_tokenFetchHandler);  // only one on-going fetch allowed
    self->_tokenFetchHandler = [callback copy];
    self->_tokenRequest = [request copy];
    return nil;
  }];
  _observedAuths = [[NSMutableArray alloc] init];
  _changesObserved = 0;
  _fakeSystemName = kNewIOSName;
  [GULSwizzler swizzleClass:[UIDevice class]
                   selector:@selector(systemName)
            isClassSelector:NO
                  withBlock:^(id sender) { return self->_fakeSystemName; }];
}

- (void)tearDown {
  [GULSwizzler unswizzleClass:[OIDAuthorizationService class]
                     selector:@selector(performTokenRequest:originalAuthorizationResponse:callback:)
              isClassSelector:YES];
  [GULSwizzler unswizzleClass:[UIDevice class]
                     selector:@selector(systemName)
              isClassSelector:NO];
  for (GIDAuthentication *auth in _observedAuths) {
    for (unsigned int i = 0; i < kNumberOfObservedProperties; ++i) {
      [auth removeObserver:self forKeyPath:kObservedProperties[i]];
    }
  }
  _observedAuths = nil;
}

#pragma mark - Tests

- (void)testInitWithAuthState {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDAuthentication *auth = [[GIDAuthentication alloc] initWithAuthState:authState];

  XCTAssertEqualObjects(auth.clientID, authState.lastAuthorizationResponse.request.clientID);
  XCTAssertEqualObjects(auth.accessToken, authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(auth.accessTokenExpirationDate,
                        authState.lastTokenResponse.accessTokenExpirationDate);
  XCTAssertEqualObjects(auth.refreshToken, authState.refreshToken);
  XCTAssertEqualObjects(auth.idToken, authState.lastTokenResponse.idToken);
  OIDIDToken *idToken = [[OIDIDToken alloc]
      initWithIDTokenString:authState.lastTokenResponse.idToken];
  XCTAssertEqualObjects(auth.idTokenExpirationDate, [idToken expiresAt]);
}

- (void)testInitWithAuthStateNoIDToken {
  OIDAuthState *authState = [OIDAuthState testInstanceWithIDToken:nil];
  GIDAuthentication *auth = [[GIDAuthentication alloc] initWithAuthState:authState];

  XCTAssertEqualObjects(auth.clientID, authState.lastAuthorizationResponse.request.clientID);
  XCTAssertEqualObjects(auth.accessToken, authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(auth.accessTokenExpirationDate,
                        authState.lastTokenResponse.accessTokenExpirationDate);
  XCTAssertEqualObjects(auth.refreshToken, authState.refreshToken);
  XCTAssertNil(auth.idToken);
  XCTAssertNil(auth.idTokenExpirationDate);
}

- (void)testAuthState {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GIDAuthentication *auth = [[GIDAuthentication alloc] initWithAuthState:authState];
  OIDAuthState *authStateReturned = auth.authState;

  XCTAssertEqual(authState, authStateReturned);
}

- (void)testCoding {
  GIDAuthentication *auth = [self auth];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:auth];
  GIDAuthentication *newAuth = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(auth, newAuth);
  XCTAssertTrue([GIDAuthentication supportsSecureCoding]);
}

- (void)testFetcherAuthorizer {
  // This is really hard to test without assuming how GTMAppAuthFetcherAuthorization works
  // internally, so let's just take the shortcut here by asserting we get a
  // GTMAppAuthFetcherAuthorization object.
  GIDAuthentication *auth = [self auth];
  id<GTMFetcherAuthorizationProtocol> fetcherAuthroizer = auth.fetcherAuthorizer;
  XCTAssertTrue([fetcherAuthroizer isKindOfClass:[GTMAppAuthFetcherAuthorization class]]);
  XCTAssertTrue([fetcherAuthroizer canAuthorize]);
}

- (void)testDoWithFreshTokensWithBothExpired {
  // Both tokens expired 10 seconds ago.
  [self setExpireTimeForAccessToken:-10 IDToken:-10];
  [self verifyTokensRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensWithAccessTokenExpired {
  // Access token expired 10 seconds ago while ID token to expire in 10 minutes.
  [self setExpireTimeForAccessToken:-10 IDToken:10 * 60];
  [self verifyTokensRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensWithIDTokenToExpire {
  // Access token to expire in 10 minutes while ID token to expire in 10 seconds.
  [self setExpireTimeForAccessToken:10 * 60 IDToken:10];
  [self verifyTokensRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensWithBothFresh {
  // Both tokens to expire in 10 minutes.
  [self setExpireTimeForAccessToken:10 * 60 IDToken:10 * 60];
  [self verifyTokensNotRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensWithAccessTokenExpiredAndNoIDToken {
  _hasIDToken = NO;
  [self setExpireTimeForAccessToken:-10 IDToken:10 * 60];  // access token expired 10 seconds ago
  [self verifyTokensRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensWithAccessTokenFreshAndNoIDToken {
  _hasIDToken = NO;
  [self setExpireTimeForAccessToken:10 * 60 IDToken:-10];  // access token to expire in 10 minutes
  [self verifyTokensNotRefreshedWithMethod:@selector(doWithFreshTokens:)];
}

- (void)testDoWithFreshTokensError {
  [self setTokensExpireTime:-10];  // expired 10 seconds ago
  GIDAuthentication *auth = [self observedAuth];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
  [auth doWithFreshTokens:^(GIDAuthentication *authentication, NSError *error) {
    [expectation fulfill];
    XCTAssertNil(authentication);
    XCTAssertNotNil(error);
  }];
  _tokenFetchHandler(nil, [self fakeError]);
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [self assertOldTokensInAuth:auth];
}

- (void)testDoWithFreshTokensQueue {
  GIDAuthentication *auth = [self observedAuth];
  XCTestExpectation *firstExpectation =
      [self expectationWithDescription:@"First callback is called"];
  [auth doWithFreshTokens:^(GIDAuthentication *authentication, NSError *error) {
    [firstExpectation fulfill];
    [self assertNewTokensInAuth:authentication];
    XCTAssertNil(error);
  }];
  XCTestExpectation *secondExpectation =
      [self expectationWithDescription:@"Second callback is called"];
  [auth doWithFreshTokens:^(GIDAuthentication *authentication, NSError *error) {
    [secondExpectation fulfill];
    [self assertNewTokensInAuth:authentication];
    XCTAssertNil(error);
  }];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [self assertNewTokensInAuth:auth];
}

#pragma mark - EMM Support

- (void)testEMMSupport {
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
  };
  GIDAuthentication *auth = [self auth];
  [auth doWithFreshTokens:^(GIDAuthentication * _Nonnull authentication,
                            NSError * _Nullable error) {}];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  NSDictionary *expectedParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : [NSString stringWithFormat:@"%@ %@",
        _fakeSystemName, [UIDevice currentDevice].systemVersion],
    kSDKVersionLoggingParameter : GIDVersion(),
  };
  XCTAssertEqualObjects(auth.authState.lastTokenResponse.request.additionalParameters,
                        expectedParameters);
}

- (void)testSystemNameNormalization {
  _fakeSystemName = kOldIOSName;
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
  };
  GIDAuthentication *auth = [self auth];
  [auth doWithFreshTokens:^(GIDAuthentication * _Nonnull authentication,
                            NSError * _Nullable error) {}];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  NSDictionary *expectedParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : [NSString stringWithFormat:@"%@ %@",
        kNewIOSName, [UIDevice currentDevice].systemVersion],
    kSDKVersionLoggingParameter : GIDVersion(),
  };
  XCTAssertEqualObjects(auth.authState.lastTokenResponse.request.additionalParameters,
                        expectedParameters);
}

- (void)testEMMPasscodeInfo {
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : @"old one",
    @"emm_passcode_info" : @"something",
  };
  GIDAuthentication *auth = [self auth];
  [auth doWithFreshTokens:^(GIDAuthentication * _Nonnull authentication,
                            NSError * _Nullable error) {}];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  NSDictionary *expectedParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : [NSString stringWithFormat:@"%@ %@",
        _fakeSystemName, [UIDevice currentDevice].systemVersion],
    @"emm_passcode_info" : [GIDMDMPasscodeState passcodeState].info,
    kSDKVersionLoggingParameter : GIDVersion(),
  };
  XCTAssertEqualObjects(auth.authState.lastTokenResponse.request.additionalParameters,
                        expectedParameters);
}

- (void)testEMMError {
  // Set expectations.
  NSDictionary *errorJSON = @{ @"error" : @"EMM Specific Error" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];
  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^completion)(void);
  [[[mockEMMErrorHandler expect] andReturnValue:@YES]
      handleErrorFromResponse:errorJSON completion:[OCMArg checkWithBlock:^(id arg) {
    completion = arg;
    return YES;
  }]];

  // Start testing.
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
  };
  GIDAuthentication *auth = [self auth];
  XCTestExpectation *notCalled = [self expectationWithDescription:@"Callback is not called"];
  notCalled.inverted = YES;
  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];
  [auth doWithFreshTokens:^(GIDAuthentication *authentication, NSError *error) {
    [notCalled fulfill];
    [called fulfill];
    XCTAssertNil(authentication);
    XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeEMM);
  }];
  _tokenFetchHandler(nil, emmError);

  // Verify and clean up.
  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  [self waitForExpectations:@[ notCalled ] timeout:1];
  completion();
  [self waitForExpectations:@[ called ] timeout:1];
  [self assertOldTokensInAuth:auth];
}

- (void)testNonEMMError {
  // Set expectations.
  NSDictionary *errorJSON = @{ @"error" : @"Not EMM Specific Error" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];
  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^completion)(void);
  [[[mockEMMErrorHandler expect] andReturnValue:@NO]
      handleErrorFromResponse:errorJSON completion:[OCMArg checkWithBlock:^(id arg) {
    completion = arg;
    return YES;
  }]];

  // Start testing.
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
  };
  GIDAuthentication *auth = [self auth];
  XCTestExpectation *notCalled = [self expectationWithDescription:@"Callback is not called"];
  notCalled.inverted = YES;
  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];
  [auth doWithFreshTokens:^(GIDAuthentication *authentication, NSError *error) {
    [notCalled fulfill];
    [called fulfill];
    XCTAssertNil(authentication);
    XCTAssertEqualObjects(error.domain, @"anydomain");
    XCTAssertEqual(error.code, 12345);
  }];
  _tokenFetchHandler(nil, emmError);

  // Verify and clean up.
  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  [self waitForExpectations:@[ notCalled ] timeout:1];
  completion();
  [self waitForExpectations:@[ called ] timeout:1];
  [self assertOldTokensInAuth:auth];
}

- (void)testCodingPreserveEMMParameters {
  _additionalTokenRequestParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : @"old one",
    @"emm_passcode_info" : @"something",
  };
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self auth]];
  GIDAuthentication *auth = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  [auth doWithFreshTokens:^(GIDAuthentication * _Nonnull authentication,
                            NSError * _Nullable error) {}];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  NSDictionary *expectedParameters = @{
    @"emm_support" : @"xyz",
    @"device_os" : [NSString stringWithFormat:@"%@ %@",
        [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion],
    @"emm_passcode_info" : [GIDMDMPasscodeState passcodeState].info,
    kSDKVersionLoggingParameter : GIDVersion(),
  };
  XCTAssertEqualObjects(auth.authState.lastTokenResponse.request.additionalParameters,
                        expectedParameters);
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  GIDAuthentication *auth = (GIDAuthentication *)object;
  ChangeType changeType;
  if ([keyPath isEqualToString:@"accessToken"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      XCTAssertEqualObjects(auth.accessToken, kAccessToken);
      changeType = kChangeTypeAccessTokenPrior;
    } else {
      XCTAssertEqualObjects(auth.accessToken, kNewAccessToken);
      changeType = kChangeTypeAccessToken;
    }
  } else if ([keyPath isEqualToString:@"accessTokenExpirationDate"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      [self assertDate:auth.accessTokenExpirationDate equalTime:_accessTokenExpireTime];
      changeType = kChangeTypeAccessTokenExpirationDatePrior;
    } else {
      [self assertDate:auth.accessTokenExpirationDate equalTime:kNewExpireTime];
      changeType = kChangeTypeAccessTokenExpirationDate;
    }
  } else if ([keyPath isEqualToString:@"idToken"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      XCTAssertEqualObjects(auth.idToken, [self idToken]);
      changeType = kChangeTypeIDTokenPrior;
    } else {
      XCTAssertEqualObjects(auth.idToken, [self idTokenNew]);
      changeType = kChangeTypeIDToken;
    }
  } else if ([keyPath isEqualToString:@"idTokenExpirationDate"]) {
    if (change[NSKeyValueChangeNotificationIsPriorKey]) {
      if (_hasIDToken) {
        [self assertDate:auth.idTokenExpirationDate equalTime:_idTokenExpireTime];
      }
      changeType = kChangeTypeIDTokenExpirationDatePrior;
    } else {
      if (_hasIDToken) {
        [self assertDate:auth.idTokenExpirationDate equalTime:kNewExpireTime2];
      }
      changeType = kChangeTypeIDTokenExpirationDate;
    }
  } else {
    XCTFail(@"unexpected keyPath");
    return;  // so compiler knows |changeType| is always assigned
  }
  NSUInteger changeMask = 1u << changeType;
  XCTAssertFalse(_changesObserved & changeMask);  // each change type should only fire once
  _changesObserved |= changeMask;
}

#pragma mark - Helpers

- (GIDAuthentication *)auth {
  NSString *idToken = [self idToken];
  NSNumber *accessTokenExpiresIn =
      @(_accessTokenExpireTime - [[NSDate date] timeIntervalSinceReferenceDate]);
  OIDTokenRequest *tokenRequest =
      [OIDTokenRequest testInstanceWithAdditionalParameters:_additionalTokenRequestParameters];
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:idToken
                                    accessToken:kAccessToken
                                      expiresIn:accessTokenExpiresIn
                                   tokenRequest:tokenRequest];
  return [[GIDAuthentication alloc]
      initWithAuthState:[OIDAuthState testInstanceWithTokenResponse:tokenResponse]];
}

- (NSString *)idTokenWithExpireTime:(NSTimeInterval)expireTime {
  if (!_hasIDToken) {
    return nil;
  }
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(expireTime + NSTimeIntervalSince1970)];
}

- (NSString *)idToken {
  return [self idTokenWithExpireTime:_idTokenExpireTime];
}

- (NSString *)idTokenNew {
  return [self idTokenWithExpireTime:kNewExpireTime2];
}

// Return the auth object that has certain property changes observed.
- (GIDAuthentication *)observedAuth {
  GIDAuthentication *auth = [self auth];
  for (unsigned int i = 0; i < kNumberOfObservedProperties; ++i) {
    [auth addObserver:self
           forKeyPath:kObservedProperties[i]
              options:NSKeyValueObservingOptionPrior
              context:NULL];
  }
  [_observedAuths addObject:auth];
  return auth;
}

- (OIDTokenResponse *)tokenResponseWithNewTokens {
  NSNumber *expiresIn = @(kNewExpireTime - [NSDate timeIntervalSinceReferenceDate]);
  return [OIDTokenResponse testInstanceWithIDToken:(_hasIDToken ? [self idTokenNew] : nil)
                                       accessToken:kNewAccessToken
                                         expiresIn:expiresIn
                                      tokenRequest:_tokenRequest ?: nil];
}

- (NSError *)fakeError {
  return [NSError errorWithDomain:@"fake.domain" code:-1 userInfo:nil];
}

- (void)assertDate:(NSDate *)date equalTime:(NSTimeInterval)time {
  XCTAssertEqualWithAccuracy([date timeIntervalSinceReferenceDate], time, kTimeAccuracy);
}

- (void)assertOldAccessTokenInAuth:(GIDAuthentication *)auth {
  XCTAssertEqualObjects(auth.accessToken, kAccessToken);
  [self assertDate:auth.accessTokenExpirationDate equalTime:_accessTokenExpireTime];
  XCTAssertEqual(_changesObserved, kChangeNone);
}

- (void)assertNewAccessTokenInAuth:(GIDAuthentication *)auth {
  XCTAssertEqualObjects(auth.accessToken, kNewAccessToken);
  [self assertDate:auth.accessTokenExpirationDate equalTime:kNewExpireTime];
  XCTAssertEqual(_changesObserved, kChangeAll);
}

- (void)assertOldTokensInAuth:(GIDAuthentication *)auth {
  [self assertOldAccessTokenInAuth:auth];
  XCTAssertEqualObjects(auth.idToken, [self idToken]);
  if (_hasIDToken) {
    [self assertDate:auth.idTokenExpirationDate equalTime:_idTokenExpireTime];
  }
}

- (void)assertNewTokensInAuth:(GIDAuthentication *)auth {
  [self assertNewAccessTokenInAuth:auth];
  XCTAssertEqualObjects(auth.idToken, [self idTokenNew]);
  if (_hasIDToken) {
    [self assertDate:auth.idTokenExpirationDate equalTime:kNewExpireTime2];
  }
}

- (void)setTokensExpireTime:(NSTimeInterval)fromNow {
  [self setExpireTimeForAccessToken:fromNow IDToken:fromNow];
}

- (void)setExpireTimeForAccessToken:(NSTimeInterval)accessExpire IDToken:(NSTimeInterval)idExpire {
  _accessTokenExpireTime = [[NSDate date] timeIntervalSinceReferenceDate] + accessExpire;
  _idTokenExpireTime = [[NSDate date] timeIntervalSinceReferenceDate] + idExpire;
}

- (void)verifyTokensRefreshedWithMethod:(SEL)sel {
  GIDAuthentication *auth = [self observedAuth];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  // We know the method doesn't return anything, so there is no risk of leaking.
  [auth performSelector:sel withObject:^(GIDAuthentication *authentication, NSError *error) {
#pragma clang diagnostic pop
    [expectation fulfill];
    [self assertNewTokensInAuth:authentication];
    XCTAssertNil(error);
  }];
  _tokenFetchHandler([self tokenResponseWithNewTokens], nil);
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [self assertNewTokensInAuth:auth];
}

- (void)verifyTokensNotRefreshedWithMethod:(SEL)sel {
  GIDAuthentication *auth = [self observedAuth];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback is called"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  // We know the method doesn't return anything, so there is no risk of leaking.
  [auth performSelector:sel withObject:^(GIDAuthentication *authentication, NSError *error) {
#pragma clang diagnostic pop
    [expectation fulfill];
    [self assertOldTokensInAuth:authentication];
    XCTAssertNil(error);
  }];
  XCTAssertNil(_tokenFetchHandler);
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [self assertOldTokensInAuth:auth];
}

@end
