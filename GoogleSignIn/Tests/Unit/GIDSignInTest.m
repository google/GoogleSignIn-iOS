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
#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import <SafariServices/SafariServices.h>

#import <XCTest/XCTest.h>

// Test module imports
@import GoogleSignIn;

@import GTMAppAuth;

#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDClaimsInternalOptions.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <AppCheckCore/GACAppCheckToken.h>
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/Fake/GIDAppCheckProviderFake.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDAuthStateMigration/Fake/GIDFakeAuthStateMigration.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import AppAuthTestHelpers;
@import GTMAppAuthTestHelpers;
@import GTMSessionFetcherCore;
@import OCMock;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDFakeAuthorizationService.h>
#import <AppAuth/OIDGrantTypes.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <AppAuth/OIDURLQueryComponent.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
#import <AppAuth/OIDAuthorizationService+IOS.h>
#elif TARGET_OS_OSX
#import <AppAuth/OIDAuthorizationService+Mac.h>
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

// GTMAuthSessionStoreFake is only available through the GTMAppAuthTestHelpers SwiftPM product.
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <OCMock/OCMock.h>
#endif

/// `NSUserDefaults` suite name for testing with `GIDAppCheck`.
static NSString *const kUserDefaultsSuiteName = @"GIDAppCheckKeySuiteName";

static NSString * const kClientId = @"FakeClientID";
static NSString * const kServerClientId = @"FakeServerClientID";
static NSString * const kScope = @"FakeScope";
static NSString * const kScope2 = @"FakeScope2";
static NSString * const kUserEmail = @"FakeUserEmail";
static NSString * const kOpenIDRealm = @"FakeRealm";
static NSString * const kFakeHostedDomain = @"fakehosteddomain.com";

static NSString * const kContinueURL = @"com.google.UnitTests:/oauth2callback";
static NSString * const kWrongSchemeURL = @"wrong.app:/oauth2callback";
static NSString * const kWrongPathURL = @"com.google.UnitTests:/wrong_path";

static NSString * const kEMMRestartAuthURL =
     @"com.google.UnitTests:///emmcallback?action=restart_auth";

static NSString * const kOpenIDRealmKey = @"openid.realm";
static NSString * const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 212;

static NSString *const kEMMSupport = @"1";

static NSString *const kNewScope = @"newScope";

static NSString *const kEssentialAuthTimeClaimJsonString =
    @"{\"id_token\":{\"auth_time\":{\"essential\":true}}}";
static NSString *const kNonEssentialAuthTimeClaimJsonString =
    @"{\"id_token\":{\"auth_time\":{\"essential\":false}}}";

static NSString *const kEssentialAMRClaimJsonString =
    @"{\"id_token\":{\"amr\":{\"essential\":true}}}";
static NSString *const kNonEssentialAMRClaimJsonString =
    @"{\"id_token\":{\"amr\":{\"essential\":false}}}";

static NSString *const kMultipleClaimsJsonString =
    @"{\"id_token\":{\"amr\":{\"essential\":false},\"auth_time\":{\"essential\":false}}}";

// This class extension exposes GIDSignIn methods to our tests.
@interface GIDSignIn ()

// Exposing private method so we can call it to disambiguate between interactive and non-interactive
// sign-in attempts for the purposes of testing the GIDSignInUIDelegate (which should not be
// called in the case of a non-interactive sign in).
- (void)authenticateMaybeInteractively:(BOOL)interactive withParams:(NSDictionary *)params;

- (BOOL)assertValidPresentingViewContoller;

@end

@interface GIDSignInTest : XCTestCase {
@private
  OIDFakeAuthorizationService *_authorizationService;   // stands in for AppAuth
  GTMAuthSessionStoreFake *_authSessionStore;           // stands in for the keychain
  GIDFakeFetcherService *_fetcherService;               // records the SDK's own HTTPS requests
  GIDFakeAuthStateMigration *_authStateMigrationService; // records migration invocations
  GIDFakeMainBundle *_fakeMainBundle;                   // supplies Info.plist config and schemes
  NSUserDefaults *_testUserDefaults;                    // isolated user defaults suite
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  UIViewController *_presentingViewController;          // presentation target on iOS
#elif TARGET_OS_OSX
  NSWindow *_presentingWindow;                          // presentation target on macOS
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
  GIDSignIn *_signIn;                                   // the instance under test
  NSString *_hint;                                      // login hint passed to sign-in helpers
  GIDSignInCompletion _completion;   // the shared completion that records into the two below
  BOOL _completionCalled;            // whether _completion has been invoked
  GIDSignInResult *_signInResult;    // result passed to _completion
  NSError *_authError;               // error passed to _completion
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  BOOL _isEligibleForEMM;            // whether the current iOS version supports EMM
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
}
@end

@implementation GIDSignInTest

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  _isEligibleForEMM = [UIDevice currentDevice].systemVersion.integerValue >= 9;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  _presentingViewController = [[UIViewController alloc] init];
#elif TARGET_OS_OSX
  _presentingWindow = [[NSWindow alloc] init];
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

  _authorizationService = [[OIDFakeAuthorizationService alloc] init];
  _authSessionStore = [[GTMAuthSessionStoreFake alloc] init];
  _fetcherService = [[GIDFakeFetcherService alloc] init];
  _authStateMigrationService = [[GIDFakeAuthStateMigration alloc] init];
  _fakeMainBundle = [[GIDFakeMainBundle alloc] initWithClientID:kClientId];
  [_fakeMainBundle fakeAllSchemesSupported];

  _testUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
  [_testUserDefaults removePersistentDomainForName:kUserDefaultsSuiteName];
  [_testUserDefaults setBool:YES forKey:kAppHasRunBeforeKey];

  _hint = nil;
  [self resetSignIn];
}

- (void)tearDown {
  [_testUserDefaults removePersistentDomainForName:kUserDefaultsSuiteName];
  [GIDSignInPreferences resetWrapperIdentifier];
  [super tearDown];
}

#pragma mark - Tests

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)testConfigureSucceeds {
  if (@available(iOS 14, *)) {
    XCTestExpectation *configureSucceedsExpecation =
        [self expectationWithDescription:@"Configure succeeds expectation"];

    GACAppCheckToken *token = [[GACAppCheckToken alloc] initWithToken:@"foo"
                                                       expirationDate:[NSDate distantFuture]];
    GIDAppCheckProviderFake *fakeProvider =
        [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:token error:nil];
    GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                             userDefaults:_testUserDefaults];

    GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                       authStateMigrationService:_authStateMigrationService
                                                        appCheck:appCheck
                                                          bundle:_fakeMainBundle
                                                    userDefaults:_testUserDefaults
                                            authorizationService:_authorizationService
                                                  fetcherService:_fetcherService];
    [signIn configureWithCompletion:^(NSError *_Nullable error) {
      XCTAssertNil(error);
      [configureSucceedsExpecation fulfill];
    }];

    [self waitForExpectations:@[ configureSucceedsExpecation ] timeout:1];
    XCTAssertTrue(appCheck.isPrepared);
  }
}

- (void)testConfigureFailsNoTokenOrError {
  if (@available(iOS 14, *)) {
    XCTestExpectation *configureFailsExpecation =
        [self expectationWithDescription:@"Configure fails expectation"];

    GIDAppCheckProviderFake *fakeProvider =
        [[GIDAppCheckProviderFake alloc] initWithAppCheckToken:nil error:nil];
    GIDAppCheck *appCheck = [[GIDAppCheck alloc] initWithAppCheckProvider:fakeProvider
                                                             userDefaults:_testUserDefaults];

    GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                       authStateMigrationService:_authStateMigrationService
                                                        appCheck:appCheck
                                                          bundle:_fakeMainBundle
                                                    userDefaults:_testUserDefaults
                                            authorizationService:_authorizationService
                                                  fetcherService:_fetcherService];

    // Should fail if missing both token and error
    [signIn configureWithCompletion:^(NSError *_Nullable error) {
      XCTAssertNotNil(error);
      XCTAssertEqual(error.code, kGIDAppCheckUnexpectedError);
      [configureFailsExpecation fulfill];
    }];

    [self waitForExpectations:@[ configureFailsExpecation ] timeout:1];
    XCTAssertFalse(appCheck.isPrepared);
  }
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (void)testInitWithKeychainStore {
  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];
  XCTAssertNotNil(signIn.configuration);
  XCTAssertEqualObjects(signIn.configuration.clientID, kClientId);
  XCTAssertNil(signIn.configuration.serverClientID);
  XCTAssertNil(signIn.configuration.hostedDomain);
  XCTAssertNil(signIn.configuration.openIDRealm);
}

- (void)testInitWithKeychainStore_noConfig {
  [_fakeMainBundle fakeWithClientID:nil
                     serverClientID:nil
                       hostedDomain:nil
                        openIDRealm:nil];
  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];
  XCTAssertNil(signIn.configuration);
}

- (void)testInitWithKeychainStore_fullConfig {
  [_fakeMainBundle fakeWithClientID:kClientId
                     serverClientID:kServerClientId
                       hostedDomain:kFakeHostedDomain
                        openIDRealm:kOpenIDRealm];

  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];
  XCTAssertNotNil(signIn.configuration);
  XCTAssertEqualObjects(signIn.configuration.clientID, kClientId);
  XCTAssertEqualObjects(signIn.configuration.serverClientID, kServerClientId);
  XCTAssertEqualObjects(signIn.configuration.hostedDomain, kFakeHostedDomain);
  XCTAssertEqualObjects(signIn.configuration.openIDRealm, kOpenIDRealm);
}

- (void)testInitWithKeychainStore_invalidConfig {
  [_fakeMainBundle fakeWithClientID:@[ @"bad", @"config", @"values" ]
                     serverClientID:nil
                       hostedDomain:nil
                        openIDRealm:nil];
  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];
  XCTAssertNil(signIn.configuration);
}

- (void)testInitWithKeychainStore_attemptsMigration {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called."];
  _authStateMigrationService.migrationInvokedCallback =
      ^(NSURL *tokenURL, NSString *callbackPath, BOOL isFreshInstall) {
        XCTAssertFalse(isFreshInstall);
        [expectation fulfill];
      };

  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];

  XCTAssertNotNil(signIn.configuration);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRestorePreviousSignInNoRefresh_hasPreviousUser {
  [self storeSessionWithAuthState:[self authStateWithIDToken:[OIDTokenResponse fatIDToken]
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];

  XCTAssertTrue([_signIn restorePreviousSignInNoRefresh]);
  XCTAssertEqualObjects(_signIn.currentUser.userID, kUserID);
  XCTAssertEqualObjects(_signIn.currentUser.profile.name, kFatName);
  XCTAssertEqualObjects(_signIn.currentUser.profile.email, kFatEmail);
  XCTAssertEqualObjects(_signIn.currentUser.accessToken.tokenString, kAccessToken);
}

- (void)testRestoredPreviousSignInNoRefresh_hasNoPreviousUser {
  XCTAssertFalse([_signIn restorePreviousSignInNoRefresh]);
  XCTAssertNil(_signIn.currentUser);
}

- (void)testHasPreviousSignIn_HasBeenAuthenticated {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  XCTAssertTrue([_signIn hasPreviousSignIn], @"should return |YES|");
  XCTAssertNotNil(_authSessionStore.savedAuthSession, @"should not remove keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
  XCTAssertNil(_authError, @"should have no error");
}

- (void)testHasPreviousSignIn_HasNotBeenAuthenticated {
  OIDAuthState *unauthorizedState =
      [[OIDAuthState alloc] initWithAuthorizationResponse:[OIDAuthorizationResponse testInstance]];
  [self storeSessionWithAuthState:unauthorizedState];
  XCTAssertFalse([_signIn hasPreviousSignIn], @"should return |NO|");
  XCTAssertNotNil(_authSessionStore.savedAuthSession, @"should not remove keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

- (void)testRestorePreviousSignInWhenSignedOut {
  OIDAuthState *unauthorizedState =
      [[OIDAuthState alloc] initWithAuthorizationResponse:[OIDAuthorizationResponse testInstance]];
  [self storeSessionWithAuthState:unauthorizedState];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called."];

  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable user,
                                                 NSError *_Nullable error) {
    [expectation fulfill];
    XCTAssertNil(user);
    XCTAssertNotNil(error, @"error should not have been nil");
    XCTAssertEqualObjects(error.domain,
                          kGIDSignInErrorDomain,
                          @"error domain should have been the sign-in error domain.");
    XCTAssertEqual(error.code,
                   kGIDSignInErrorCodeHasNoAuthInKeychain,
                   @"error code should have been the 'NoAuthInKeychain' error code.");
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testNotRestorePreviousSignInWhenSignedOutAndCompletionIsNil {
  OIDAuthState *unauthorizedState =
      [[OIDAuthState alloc] initWithAuthorizationResponse:[OIDAuthorizationResponse testInstance]];
  [self storeSessionWithAuthState:unauthorizedState];

  [_signIn restorePreviousSignInWithCompletion:nil];

  XCTAssertNil(_signIn.currentUser);
}

- (void)testRestorePreviousSignInWhenCompletionIsNil {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:@(3600)]];
  XCTAssertNil(_signIn.currentUser);

  [_signIn restorePreviousSignInWithCompletion:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Main queue drained"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:1];

  XCTAssertNotNil(_signIn.currentUser);
  XCTAssertEqual(_authorizationService.tokenRequestCount, 0u);
}

- (void)testOAuthLogin {
  GIDGoogleUser *user = [self signInSuccessfully];
  XCTAssertEqualObjects(_signInResult.serverAuthCode, kServerAuthCode);
  XCTAssertEqualObjects(user.profile.name, kFatName);
  XCTAssertEqualObjects(user.profile.givenName, kFatGivenName);
  XCTAssertEqualObjects(user.profile.familyName, kFatFamilyName);
  XCTAssertTrue(user.profile.hasImage);
  GTMAuthSession *savedSession = _authSessionStore.savedAuthSession;
  XCTAssertNotNil(savedSession);
  XCTAssertEqualObjects(savedSession.authState.lastTokenResponse.accessToken, kAccessToken);

  NSUInteger tokenRequestCountBefore = _authorizationService.tokenRequestCount;
  XCTestExpectation *restoreExpectation =
      [self expectationWithDescription:@"Callback should be called"];
  __block GIDGoogleUser *restoredUser;
  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable callbackUser,
                                                 NSError *_Nullable error) {
    restoredUser = callbackUser;
    XCTAssertNil(error, @"should have no error");
    [restoreExpectation fulfill];
  }];
  [self waitForExpectations:@[ restoreExpectation ] timeout:1];

  XCTAssertEqual(restoredUser, user);
  XCTAssertEqual(_authorizationService.tokenRequestCount, tokenRequestCountBefore);
  XCTAssertEqual(_authSessionStore.savedAuthSession, savedSession);
}

- (void)testOAuthLogin_RestoredSignIn {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:@(3600)]];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Restored sign-in completes"];
  __block GIDGoogleUser *restoredUser;
  __block NSError *restoredError;
  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable user,
                                                 NSError *_Nullable error) {
    restoredUser = user;
    restoredError = error;
    [expectation fulfill];
  }];

  [self waitForExpectations:@[ expectation ] timeout:1];
  XCTAssertNil(restoredError);
  XCTAssertNotNil(_signIn.currentUser);
  XCTAssertEqual(_signIn.currentUser, restoredUser);
  XCTAssertEqual(_authorizationService.tokenRequestCount, 0u);
}

- (void)testOAuthLogin_RestoredSignInOldAccessToken {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:@(300)]];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Restored sign-in completes"];
  __block GIDGoogleUser *restoredUser;
  __block NSError *restoredError;
  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable user,
                                                 NSError *_Nullable error) {
    restoredUser = user;
    restoredError = error;
    [expectation fulfill];
  }];

  XCTAssertNotNil(_authorizationService.lastTokenRequest);
  XCTAssertEqualObjects(_authorizationService.lastTokenRequest.grantType,
                        OIDGrantTypeRefreshToken);
  XCTAssertEqualObjects(_authorizationService.lastTokenRequest.refreshToken, kRefreshToken);

  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:@(3600)];
  [self waitForExpectations:@[ expectation ] timeout:1];

  XCTAssertNil(restoredError);
  XCTAssertNotNil(_signIn.currentUser);
  XCTAssertEqual(_signIn.currentUser, restoredUser);
  XCTAssertNotNil(_authSessionStore.savedAuthSession);
}

- (void)testOAuthLogin_AdditionalScopes {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  NSString *expectedScopeString = [@[ @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.scope, expectedScopeString);
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];

  [self resetSignIn];
  [self startSignInWithHint:_hint additionalScopes:@[ kScope ] nonce:nil claims:nil];
  expectedScopeString = [@[ kScope, @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.scope, expectedScopeString);
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];

  [self resetSignIn];
  [self startSignInWithHint:_hint additionalScopes:@[ kScope, kScope2 ] nonce:nil claims:nil];
  expectedScopeString = [@[ kScope, kScope2, @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.scope, expectedScopeString);
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];
}

- (void)testOAuthLogin_WithAuthTimeClaim_FormatsParametersCorrectly {
  GIDClaim *authTimeClaim = [GIDClaim authTimeClaim];
  GIDClaim *essentialAuthTimeClaim = [GIDClaim essentialAuthTimeClaim];

  [self startSignInWithHint:_hint
           additionalScopes:nil
                      nonce:nil
                     claims:[NSSet setWithObject:essentialAuthTimeClaim]];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.additionalParameters[@"claims"],
                        kEssentialAuthTimeClaimJsonString,
                        @"Claims JSON should be correctly formatted");

  [self resetSignIn];
  [self startSignInWithHint:_hint
           additionalScopes:nil
                      nonce:nil
                     claims:[NSSet setWithObject:authTimeClaim]];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.additionalParameters[@"claims"],
                        kNonEssentialAuthTimeClaimJsonString,
                        @"Claims JSON should be correctly formatted");
}

- (void)testOAuthLogin_WithAMRClaim_FormatsParametersCorrectly {
  GIDClaim *AMRClaim = [GIDClaim AMRClaim];
  GIDClaim *essentialAMRClaim = [GIDClaim essentialAMRClaim];

  [self startSignInWithHint:_hint
           additionalScopes:nil
                      nonce:nil
                     claims:[NSSet setWithObject:essentialAMRClaim]];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.additionalParameters[@"claims"],
                        kEssentialAMRClaimJsonString,
                        @"Claims JSON should be correctly formatted");

  [self resetSignIn];
  [self startSignInWithHint:_hint
           additionalScopes:nil
                      nonce:nil
                     claims:[NSSet setWithObject:AMRClaim]];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.additionalParameters[@"claims"],
                        kNonEssentialAMRClaimJsonString,
                        @"Claims JSON should be correctly formatted");
}

- (void)testOAuthLogin_WithMultipleClaims_FormatsParametersCorrectly {
  GIDClaim *authTimeClaim = [GIDClaim authTimeClaim];
  GIDClaim *AMRClaim = [GIDClaim AMRClaim];
  NSSet<GIDClaim *> *claims = [NSSet setWithArray:@[ authTimeClaim, AMRClaim ]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:claims];
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.additionalParameters[@"claims"],
                        kMultipleClaimsJsonString,
                        @"Claims JSON should be correctly formatted");
}

- (void)testOAuthLogin_WithMultipleClaims_ReturnsIdTokenWithCorrectClaims {
  GIDClaim *authTimeClaim = [GIDClaim authTimeClaim];
  GIDClaim *AMRClaim = [GIDClaim AMRClaim];
  NSSet<GIDClaim *> *claims = [NSSet setWithArray:@[ authTimeClaim, AMRClaim ]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:claims];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:[OIDTokenResponse fatIDTokenWithClaims]
                          accessToken:kAccessToken
                            expiresIn:nil];
  [self waitForCompletion];

  XCTAssertNotNil(_signIn.currentUser,
                  @"The currentUser should not be nil after a successful sign-in.");
  NSString *idTokenString = _signIn.currentUser.idToken.tokenString;
  XCTAssertNotNil(idTokenString, @"ID token string should not be nil.");
  NSArray<NSString *> *components = [idTokenString componentsSeparatedByString:@"."];
  XCTAssertEqual(components.count, 3u, @"JWT should have 3 parts.");
  NSData *payloadData = [[NSData alloc]
      initWithBase64EncodedString:components[1]
                          options:NSDataBase64DecodingIgnoreUnknownCharacters];
  NSDictionary *receivedClaims = [NSJSONSerialization JSONObjectWithData:payloadData
                                                                 options:0
                                                                   error:nil];
  XCTAssertEqualObjects(receivedClaims[@"auth_time"],
                        kAuthTime,
                        @"The 'auth_time' claim should be present and correct.");
  XCTAssertEqualObjects(receivedClaims[@"amr"],
                        [OIDTokenResponse stubbedAMRValues],
                        @"The 'amr' claim should be present and correct.");
}

- (void)testAddScopes {
  GIDGoogleUser *originalUser = [self signInSuccessfully];
  GTMAuthSession *initialSession = _authSessionStore.savedAuthSession;
  XCTAssertNotNil(initialSession);

  XCTestExpectation *addScopesExpectation =
      [self expectationWithDescription:@"addScopes completion called"];
  __block GIDSignInResult *addScopesResult;
  __block NSError *addScopesError;
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  [_signIn addScopes:@[ kNewScope ]
      presentingViewController:_presentingViewController
#elif TARGET_OS_OSX
  [_signIn addScopes:@[ kNewScope ]
      presentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
            completion:^(GIDSignInResult *_Nullable signInResult, NSError *_Nullable error) {
              addScopesResult = signInResult;
              addScopesError = error;
              [addScopesExpectation fulfill];
            }];

  OIDAuthorizationRequest *authRequest = _authorizationService.lastAuthorizationRequest;
  XCTAssertNotNil(authRequest);
  XCTAssertEqualObjects(authRequest.additionalParameters[@"login_hint"], kFatEmail);
  NSSet<NSString *> *requestedScopes =
      [NSSet setWithArray:[authRequest.scope componentsSeparatedByString:@" "]];
  NSSet<NSString *> *expectedScopes =
      [NSSet setWithObjects:kNewScope, OIDAuthorizationRequestTestingScope2, nil];
  XCTAssertEqualObjects(requestedScopes, expectedScopes);

  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForExpectations:@[ addScopesExpectation ] timeout:1];

  XCTAssertNil(addScopesError);
  XCTAssertNotNil(addScopesResult);
  XCTAssertEqual(addScopesResult.user, originalUser);
  XCTAssertNotNil(_authSessionStore.savedAuthSession);
  XCTAssertNotEqual(_authSessionStore.savedAuthSession, initialSession);
}

- (void)testAddScopes_WithPreviouslyRequestedClaims {
  GIDClaim *authTimeClaim = [GIDClaim authTimeClaim];
  [self startSignInWithHint:_hint
           additionalScopes:nil
                      nonce:nil
                     claims:[NSSet setWithObject:authTimeClaim]];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];
  GIDGoogleUser *originalUser = _signIn.currentUser;
  XCTAssertNotNil(originalUser);
  GTMAuthSession *initialSession = _authSessionStore.savedAuthSession;

  XCTestExpectation *addScopesExpectation =
      [self expectationWithDescription:@"addScopes completion called"];
  __block GIDSignInResult *addScopesResult;
  __block NSError *addScopesError;
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  [_signIn addScopes:@[ kNewScope ]
      presentingViewController:_presentingViewController
#elif TARGET_OS_OSX
  [_signIn addScopes:@[ kNewScope ]
      presentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
            completion:^(GIDSignInResult *_Nullable signInResult, NSError *_Nullable error) {
              addScopesResult = signInResult;
              addScopesError = error;
              [addScopesExpectation fulfill];
            }];

  OIDAuthorizationRequest *authRequest = _authorizationService.lastAuthorizationRequest;
  XCTAssertNotNil(authRequest);
  XCTAssertEqualObjects(authRequest.additionalParameters[@"login_hint"], kFatEmail);
  NSSet<NSString *> *requestedScopes =
      [NSSet setWithArray:[authRequest.scope componentsSeparatedByString:@" "]];
  NSSet<NSString *> *expectedScopes =
      [NSSet setWithObjects:kNewScope, OIDAuthorizationRequestTestingScope2, nil];
  XCTAssertEqualObjects(requestedScopes, expectedScopes);
  XCTAssertEqualObjects(authRequest.additionalParameters[@"claims"],
                        kNonEssentialAuthTimeClaimJsonString,
                        @"Claims JSON should be correctly formatted");

  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForExpectations:@[ addScopesExpectation ] timeout:1];

  XCTAssertNil(addScopesError);
  XCTAssertEqual(addScopesResult.user, originalUser);
  XCTAssertNotNil(_authSessionStore.savedAuthSession);
  XCTAssertNotEqual(_authSessionStore.savedAuthSession, initialSession);
}

- (void)testOpenIDRealm {
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                      serverClientID:nil
                                                        hostedDomain:nil
                                                         openIDRealm:kOpenIDRealm];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];

  NSDictionary<NSString *, NSString *> *params =
      _authorizationService.lastTokenRequest.additionalParameters;
  XCTAssertEqualObjects(params[kOpenIDRealmKey], kOpenIDRealm, @"OpenID Realm should match.");
}

- (void)testManualNonce {
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                      serverClientID:nil
                                                        hostedDomain:nil
                                                         openIDRealm:kOpenIDRealm];

  NSString *manualNonce = @"manual_nonce";
  [self startSignInWithHint:_hint additionalScopes:@[] nonce:manualNonce claims:nil];

  XCTAssertEqualObjects(_authorizationService.lastAuthorizationRequest.nonce,
                        manualNonce,
                        @"Provided nonce should match nonce in authorization request.");
}

- (void)testOAuthLogin_LoginHint {
  _hint = kUserEmail;
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];

  NSDictionary<NSString *, NSObject *> *params =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"login_hint"], kUserEmail, @"login hint should match");
}

- (void)testOAuthLogin_HostedDomain {
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                      serverClientID:nil
                                                        hostedDomain:kHostedDomain
                                                         openIDRealm:nil];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];

  NSDictionary<NSString *, NSObject *> *params =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"hd"], kHostedDomain, @"hosted domain should match");
}

- (void)testWrapperIdentifier_PresentInAuthorizationRequestWhenSet {
  GIDSignIn.wrapperIdentifier = @"firebase";
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];

  NSDictionary<NSString *, NSObject *> *params =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"gidwrapper"], @"firebase",
                        @"The authorization request should contain the 'gidwrapper' parameter "
                        "when set.");
}

- (void)testWrapperIdentifier_AbsentFromAuthorizationRequestWhenUnset {
  [GIDSignInPreferences resetWrapperIdentifier];
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];

  NSDictionary<NSString *, NSObject *> *params =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  XCTAssertNil(params[@"gidwrapper"],
               @"The authorization request should not contain the 'gidwrapper' parameter "
               "when unset.");
}

- (void)testWrapperIdentifier_DroppedValueIsIgnored {
  XCTAssertNoThrow(GIDSignIn.wrapperIdentifier = @"firebasé",
                   @"Setting a dropped wrapper identifier should be ignored.");
  XCTAssertNil(GIDSignIn.wrapperIdentifier,
               @"The wrapper identifier should be nil after a dropped assignment.");
}

- (void)testWrapperIdentifier_PresentOnRevokeURL {
  GIDSignIn.wrapperIdentifier = @"my-sdk";
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];

  [_signIn disconnectWithCompletion:nil];

  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  NSURL *url = [self fetchedURL];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                           resolvingAgainstBaseURL:NO];
  NSArray<NSURLQueryItem *> *queryItems = components.queryItems;

  XCTAssertEqualObjects([self valueForQueryItemName:@"gidwrapper" inArray:queryItems],
                        @"my-sdk", @"The revoke URL should contain the 'gidwrapper' parameter.");
  XCTAssertEqualObjects([self valueForQueryItemName:kSDKVersionLoggingParameter inArray:queryItems],
                        [GIDSignInPreferences sdkVersion],
                        @"The revoke URL should contain the SDK version parameter.");
  XCTAssertEqualObjects([self valueForQueryItemName:kEnvironmentLoggingParameter
                                            inArray:queryItems],
                        [GIDSignInPreferences environment],
                        @"The revoke URL should contain the environment parameter.");
  XCTAssertEqualObjects([self valueForQueryItemName:@"token" inArray:queryItems],
                        kAccessToken, @"The revoke URL should contain the 'token' parameter.");
}

- (void)testWrapperIdentifier_AbsentFromRevokeURLWhenUnset {
  [GIDSignInPreferences resetWrapperIdentifier];
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];

  [_signIn disconnectWithCompletion:nil];

  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  NSURL *url = [self fetchedURL];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                           resolvingAgainstBaseURL:NO];
  NSArray<NSURLQueryItem *> *queryItems = components.queryItems;

  XCTAssertNil([self valueForQueryItemName:@"gidwrapper" inArray:queryItems],
               @"The revoke URL should not contain the 'gidwrapper' parameter when unset.");
  XCTAssertEqualObjects([self valueForQueryItemName:kSDKVersionLoggingParameter inArray:queryItems],
                        [GIDSignInPreferences sdkVersion],
                        @"The revoke URL should still contain the SDK version parameter.");
  XCTAssertEqualObjects([self valueForQueryItemName:kEnvironmentLoggingParameter
                                            inArray:queryItems],
                        [GIDSignInPreferences environment],
                        @"The revoke URL should still contain the environment parameter.");
  XCTAssertEqualObjects([self valueForQueryItemName:@"token" inArray:queryItems],
                        kAccessToken,
                        @"The revoke URL should still contain the 'token' parameter.");
}

- (void)testOAuthLogin_ConsentCanceled {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:@"access_denied"];
  [self waitForCompletion];

  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
  XCTAssertNil(_signIn.currentUser);
  XCTAssertNil(_authSessionStore.savedAuthSession);
}

- (void)testOAuthLogin_ModalCanceled {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  NSError *error = [NSError errorWithDomain:OIDGeneralErrorDomain
                                       code:OIDErrorCodeUserCanceledAuthorizationFlow
                                   userInfo:nil];
  [self failAuthorizationWithError:error];
  [self waitForCompletion];

  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
  XCTAssertNil(_signIn.currentUser);
  XCTAssertNil(_authSessionStore.savedAuthSession);
}

- (void)testOAuthLogin_KeychainError {
  _authSessionStore.saveError = [NSError errorWithDomain:@"com.googleSignIn.throwAway"
                                                    code:1
                                                userInfo:nil];
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];

  XCTAssertNil(_authSessionStore.savedAuthSession);
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeKeychain);
  XCTAssertNil(_signIn.currentUser);
}

- (void)testOAuthLogin_Claims_FailsWithError {
  GIDClaim *authTimeClaim = [GIDClaim authTimeClaim];
  GIDClaim *essentialAuthTimeClaim = [GIDClaim essentialAuthTimeClaim];
  NSSet<GIDClaim *> *conflictingClaims =
      [NSSet setWithObjects:authTimeClaim, essentialAuthTimeClaim, nil];

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  [_signIn signInWithPresentingViewController:_presentingViewController
                                         hint:_hint
                             additionalScopes:nil
                                        nonce:nil
                                       claims:conflictingClaims
                                   completion:_completion];
#elif TARGET_OS_OSX
  [_signIn signInWithPresentingWindow:_presentingWindow
                                 hint:_hint
                     additionalScopes:nil
                                nonce:nil
                               claims:conflictingClaims
                           completion:_completion];
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

  XCTAssertNil(_authorizationService.lastAuthorizationRequest);
  [self waitForCompletion];

  XCTAssertNotNil(_authError, @"An error object should have been returned.");
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeAmbiguousClaims,
                 @"The error code should be for ambiguous claims.");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain,
                        @"The error domain should be the GIDSignIn error domain.");
  XCTAssertEqualObjects(_authError.localizedDescription, kGIDClaimErrorDescription,
                        @"The error description should clearly explain the ambiguity.");
}

- (void)testSignOut {
  [self signInSuccessfully];
  XCTAssertNotNil(_signIn.currentUser);

  [_signIn signOut];
  XCTAssertNil(_signIn.currentUser, @"should not have a current user");
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should remove keychain");
}

- (void)testNotHandleWrongScheme {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  _authorizationService.lastAuthorizationSession.resumeResult = NO;
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongSchemeURL]],
                 @"should not handle URL");
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

- (void)testNotHandleWrongPath {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongPathURL]], @"should not handle URL");
  XCTAssertNil(_authorizationService.lastAuthorizationSession.lastResumedURL);
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

- (void)testHandleURL_resumesPendingFlow {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  NSURL *continueURL = [NSURL URLWithString:kContinueURL];
  XCTAssertTrue([_signIn handleURL:continueURL]);
  XCTAssertEqualObjects(_authorizationService.lastAuthorizationSession.lastResumedURL, continueURL);
}

#pragma mark - Test Fresh Install

- (void)testFreshInstall_removesKeychainEntries {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  XCTAssertNotNil(_authSessionStore.savedAuthSession);

  // Simulate that the app has been deleted and the key removed from the test user defaults.
  [_testUserDefaults removeObjectForKey:kAppHasRunBeforeKey];
  // Initialization should check `isFreshInstall`.
  GIDSignIn *signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                                     authStateMigrationService:_authStateMigrationService
                                                        bundle:_fakeMainBundle
                                                  userDefaults:_testUserDefaults
                                          authorizationService:_authorizationService
                                                fetcherService:_fetcherService];
  // If `isFreshInstall`, keychain entries should be removed.
  XCTAssertNotNil(signIn);
  XCTAssertNil(_authSessionStore.savedAuthSession);
}

#pragma mark - Tests - disconnectWithCallback:

// Verifies disconnect calls callback with no errors if access token is present.
- (void)testDisconnect_accessToken {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  XCTestExpectation *accessTokenExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError *_Nullable error) {
    if (error == nil) {
      [accessTokenExpectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kAccessToken
                 hasCallback:YES
      waitingForExpectations:@[ accessTokenExpectation ]];
}

// Verifies disconnect if access token is present.
- (void)testDisconnectNoCallback_accessToken {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];
  [self verifyAndRevokeToken:kAccessToken hasCallback:NO waitingForExpectations:@[]];
}

// Verifies a token containing characters that are reserved in a URL query is percent-encoded
// in the revoke URL, so that it arrives at the server intact.
- (void)testDisconnectNoCallback_tokenWithReservedCharacters {
  NSString *tokenWithReservedCharacters = @"token&with=reserved#characters";
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:tokenWithReservedCharacters
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];
  [self verifyAndRevokeToken:tokenWithReservedCharacters
                 hasCallback:NO
      waitingForExpectations:@[]];
}

// OAuth parameters use application/x-www-form-urlencoded (RFC 6749 Appendix B), where "+"
// means a space, so a literal "+" in a token is sent as "%2B" even though RFC 3986
// would permit it unescaped in a query.
- (void)testDisconnectNoCallback_tokenWithPlusCharacter {
  NSString *tokenWithPlusCharacter = @"token+with+plus";
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:tokenWithPlusCharacter
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];

  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  NSURL *url = [self fetchedURL];
  XCTAssertEqualObjects([url scheme], @"https", @"scheme must match");
  XCTAssertEqualObjects([url host], @"accounts.google.com", @"host must match");
  XCTAssertEqualObjects([url path], @"/o/oauth2/revoke", @"path must match");

  NSString *query = [[self fetchedURL] query];
  XCTAssertTrue([query containsString:@"token=token%2Bwith%2Bplus"],
                @"'+' should be percent-encoded in the query string");
  XCTAssertFalse([query containsString:@"token=token+with+plus"],
                 @"'+' should not be literal in the query string");

  NSURLComponents *components =
      [NSURLComponents componentsWithURL:[self fetchedURL] resolvingAgainstBaseURL:NO];
  NSURLQueryItem *tokenItem;
  for (NSURLQueryItem *item in components.queryItems) {
    if ([item.name isEqualToString:@"token"]) {
      tokenItem = item;
      break;
    }
  }
  XCTAssertEqualObjects(tokenItem.value, tokenWithPlusCharacter);

  [self didFetch:nil error:nil];
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should clear saved keychain name");
}

// Guard the "+" to "%2B" rewrite, which is only safe if a space encodes as "%20", never as "+".
// Whilst this is technically testing Foundation behaviour, it's undocumented behaviour.
- (void)testDisconnectNoCallback_tokenWithSpace {
  NSString *tokenWithSpace = @"token with space";
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:tokenWithSpace
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];

  NSString *query = [[self fetchedURL] query];
  XCTAssertTrue([query containsString:@"token=token%20with%20space"],
                @"a space should be percent-encoded in the query string");
  XCTAssertFalse([query containsString:@"+"], @"a space should never be encoded as '+'");

  [self didFetch:nil error:nil];
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should clear saved keychain name");
}

// Round-trip the revoke URL through OIDURLQueryComponent, a pretend server, to check "+" survives.
- (void)testDisconnectNoCallback_tokenWithPlusCharacterFormDecoded {
  NSString *tokenWithPlusCharacter = @"token+with+plus";
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:tokenWithPlusCharacter
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];

  [self verifyAndRevokeToken:tokenWithPlusCharacter
                 hasCallback:NO
      waitingForExpectations:@[]];
}

// Verifies disconnect calls callback with no errors if refresh token is present.
- (void)testDisconnect_refreshToken {
  OIDTokenResponse *tokenResponse =
      [[OIDTokenResponse alloc] initWithRequest:[OIDTokenRequest testInstance]
                                     parameters:@{
                                       @"refresh_token" : kRefreshToken,
                                       @"token_type" : @"Bearer",
                                     }];
  [self storeSessionWithAuthState:[OIDAuthState testInstanceWithTokenResponse:tokenResponse]];
  XCTestExpectation *refreshTokenExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError *_Nullable error) {
    if (error == nil) {
      [refreshTokenExpectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kRefreshToken
                 hasCallback:YES
      waitingForExpectations:@[ refreshTokenExpectation ]];
}

// Verifies disconnect errors are passed along to the callback.
- (void)testDisconnect_errors {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  XCTestExpectation *errorExpectation =
      [self expectationWithDescription:@"Callback called with an error"];
  [_signIn disconnectWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      [errorExpectation fulfill];
    }
  }];
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  [self waitForExpectations:@[ errorExpectation ] timeout:1];
  XCTAssertNotNil(_authSessionStore.savedAuthSession);
}

// Verifies disconnect with errors.
- (void)testDisconnectNoCallback_errors {
  [self storeSessionWithAuthState:[self authStateWithIDToken:nil
                                                 accessToken:kAccessToken
                                                   expiresIn:nil]];
  [_signIn disconnectWithCompletion:nil];
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  XCTAssertNotNil(_authSessionStore.savedAuthSession);
}

// Verifies disconnect calls callback with no errors and clears keychain if no tokens are present.
- (void)testDisconnect_noTokens {
  OIDAuthState *authState =
      [[OIDAuthState alloc] initWithAuthorizationResponse:[OIDAuthorizationResponse testInstance]];
  [self storeSessionWithAuthState:authState];
  XCTestExpectation *noTokensExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError *_Nullable error) {
    if (error == nil) {
      [noTokensExpectation fulfill];
    }
  }];
  [self waitForExpectations:@[ noTokensExpectation ] timeout:1];
  XCTAssertFalse([self isFetcherStarted], @"should not fetch");
  XCTAssertNil(_authSessionStore.savedAuthSession, @"keychain should be removed");
}

// Verifies disconnect clears keychain if no tokens are present.
- (void)testDisconnectNoCallback_noTokens {
  OIDAuthState *authState =
      [[OIDAuthState alloc] initWithAuthorizationResponse:[OIDAuthorizationResponse testInstance]];
  [self storeSessionWithAuthState:authState];
  [_signIn disconnectWithCompletion:nil];
  XCTAssertFalse([self isFetcherStarted], @"should not fetch");
  XCTAssertNil(_authSessionStore.savedAuthSession, @"keychain should be removed");
}

- (void)testPresentingViewControllerException {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  _presentingViewController = nil;
#elif TARGET_OS_OSX
  _presentingWindow = nil;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  XCTAssertThrows([_signIn signInWithPresentingViewController:_presentingViewController
#elif TARGET_OS_OSX
  XCTAssertThrows([_signIn signInWithPresentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                 hint:_hint
                                           completion:_completion]);
}

- (void)testClientIDMissingException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop
  BOOL threw = NO;
  @try {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    [_signIn signInWithPresentingViewController:_presentingViewController
#elif TARGET_OS_OSX
    [_signIn signInWithPresentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                             completion:nil];
  } @catch (NSException *exception) {
    threw = YES;
    XCTAssertEqualObjects(exception.description,
                          @"You must specify |clientID| in |GIDConfiguration|");
  } @finally {
  }
  XCTAssert(threw);
}

- (void)testSchemesNotSupportedException {
  [_fakeMainBundle fakeMissingAllSchemes];
  BOOL threw = NO;
  @try {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    [_signIn signInWithPresentingViewController:_presentingViewController
#elif TARGET_OS_OSX
    [_signIn signInWithPresentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                   hint:_hint
                             completion:_completion];
  } @catch (NSException *exception) {
    threw = YES;
    XCTAssertEqualObjects(exception.description,
                          @"Your app is missing support for the following URL schemes: "
                          "fakeclientid");
  } @finally {
  }
  XCTAssert(threw);
}

#pragma mark - Restarting Authentication Tests

// Verifies that URL is not handled if there is no pending sign-in
- (void)testRequiringPendingSignIn {
  BOOL result = [_signIn handleURL:[NSURL URLWithString:kEMMRestartAuthURL]];
  XCTAssertFalse(result);
}

#pragma mark - EMM tests

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (void)testEmmSupportRequestParameters {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];

  NSString *systemName = [UIDevice currentDevice].systemName;
  if ([systemName isEqualToString:@"iPhone OS"]) {
    systemName = @"iOS";
  }
  NSString *expectedOSVersion = [NSString stringWithFormat:@"%@ %@",
      systemName, [UIDevice currentDevice].systemVersion];
  NSDictionary<NSString *, NSObject *> *authParams =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  NSDictionary<NSString *, NSString *> *tokenParams =
      _authorizationService.lastTokenRequest.additionalParameters;
  if (_isEligibleForEMM) {
    XCTAssertEqualObjects(authParams[@"emm_support"], kEMMSupport,
                          @"EMM support should match in auth request");
    XCTAssertEqualObjects(authParams[@"device_os"], expectedOSVersion,
                          @"OS version should match in auth request");
    XCTAssertEqualObjects(tokenParams[@"emm_support"], kEMMSupport,
                          @"EMM support should match in token request");
    XCTAssertEqualObjects(tokenParams[@"device_os"],
                          expectedOSVersion,
                          @"OS version should match in token request");
    XCTAssertNil(tokenParams[@"emm_passcode_info"],
                 @"no passcode info should be in token request");
  } else {
    XCTAssertNil(authParams[@"emm_support"],
                 @"EMM support should not be in auth request for unsupported OS");
    XCTAssertNil(authParams[@"device_os"],
                 @"OS version should not be in auth request for unsupported OS");
    XCTAssertNil(tokenParams[@"emm_support"],
                 @"EMM support should not be in token request for unsupported OS");
    XCTAssertNil(tokenParams[@"device_os"],
                 @"OS version should not be in token request for unsupported OS");
    XCTAssertNil(tokenParams[@"emm_passcode_info"],
                 @"passcode info should not be in token request for unsupported OS");
  }
}

- (void)testEmmPasscodeInfo {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:
            [self additionalParametersWithEMMPasscodeInfoRequired:YES claimsAsJSONRequired:NO]
                                              nonce:nil
                                        errorString:nil];
  NSDictionary<NSString *, NSString *> *tokenParams =
      _authorizationService.lastTokenRequest.additionalParameters;
  if (_isEligibleForEMM) {
    XCTAssertNotNil(tokenParams[@"emm_passcode_info"],
                    @"passcode info should be in token request");
  } else {
    XCTAssertNil(tokenParams[@"emm_passcode_info"],
                 @"passcode info should not be in token request for unsupported OS");
  }
}

- (void)testAuthEndpointEMMError {
  if (!_isEligibleForEMM) {
    return;
  }

  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^completion)(BOOL handled);
  NSDictionary<NSString *, NSString *> *callbackParams = @{ @"error" : @"EMM Specific Error" };
  [[mockEMMErrorHandler expect]
      handleErrorFromResponse:callbackParams
                   completion:[OCMArg checkWithBlock:^BOOL(id arg) {
                     completion = [arg copy];
                     return YES;
                   }]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil
                                              nonce:nil
                                        errorString:callbackParams[@"error"]];

  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  XCTAssertNotNil(completion);
  completion(YES);

  [self waitForCompletion];

  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeEMM);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

// Verifies that an authorization error the EMM handler declines is reported as unknown.
- (void)testAuthEndpointEMMError_NotHandled {
  if (!_isEligibleForEMM) {
    return;
  }

  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^completion)(BOOL handled);
  NSDictionary<NSString *, NSString *> *callbackParams = @{ @"error" : @"invalid_request" };
  [[mockEMMErrorHandler expect]
      handleErrorFromResponse:callbackParams
                   completion:[OCMArg checkWithBlock:^BOOL(id arg) {
                     completion = [arg copy];
                     return YES;
                   }]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil
                                              nonce:nil
                                        errorString:callbackParams[@"error"]];

  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  XCTAssertNotNil(completion);
  completion(NO);

  [self waitForCompletion];

  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeUnknown);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

// Verifies that access_denied is reported as canceled even when the EMM handler claims it.
- (void)testAuthEndpointEMMError_AccessDeniedTakesPriority {
  if (!_isEligibleForEMM) {
    return;
  }

  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^completion)(BOOL handled);
  NSDictionary<NSString *, NSString *> *callbackParams = @{ @"error" : @"access_denied" };
  [[mockEMMErrorHandler expect]
      handleErrorFromResponse:callbackParams
                   completion:[OCMArg checkWithBlock:^BOOL(id arg) {
                     completion = [arg copy];
                     return YES;
                   }]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil
                                              nonce:nil
                                        errorString:callbackParams[@"error"]];

  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  XCTAssertNotNil(completion);
  completion(YES);

  [self waitForCompletion];

  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

- (void)testTokenEndpointEMMError {
  if (!_isEligibleForEMM) {
    return;
  }

  __block void (^completion)(NSError *);
  NSDictionary *errorJSON = @{ @"error" : @"EMM Specific Error" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorFieldError : errorJSON }];
  id emmSupport = OCMStrictClassMock([GIDEMMSupport class]);
  [[[emmSupport expect] classMethod]
      handleTokenFetchEMMError:emmError
                    completion:[OCMArg checkWithBlock:^BOOL(id arg) {
                      completion = [arg copy];
                      return YES;
                    }]];

  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self failTokenRequestWithError:emmError];

  [emmSupport verify];
  [emmSupport stopMocking];

  NSError *handledError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                              code:kGIDSignInErrorCodeEMM
                                          userInfo:emmError.userInfo];
  XCTAssertNotNil(completion);
  completion(handledError);

  [self waitForCompletion];

  XCTAssertNil(_authSessionStore.savedAuthSession, @"should not save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeEMM);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#pragma mark - Helpers

// Recreates `_signIn` and resets the shared completion recording state.
- (void)resetSignIn {
  _completionCalled = NO;
  _signInResult = nil;
  _authError = nil;

  _signIn = [[GIDSignIn alloc] initWithKeychainStore:_authSessionStore
                           authStateMigrationService:_authStateMigrationService
                                              bundle:_fakeMainBundle
                                        userDefaults:_testUserDefaults
                                authorizationService:_authorizationService
                                      fetcherService:_fetcherService];

  __weak GIDSignInTest *weakSelf = self;
  _completion = ^(GIDSignInResult *_Nullable signInResult, NSError *_Nullable error) {
    GIDSignInTest *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (!signInResult) {
      XCTAssertNotNil(error, @"should have an error if the signInResult is nil");
    }
    XCTAssertFalse(strongSelf->_completionCalled, @"callback already called");
    strongSelf->_completionCalled = YES;
    strongSelf->_signInResult = signInResult;
    strongSelf->_authError = error;
  };
}

// Returns a fat ID token with an expiration date in the future.
- (NSString *)freshFatIDToken {
  NSTimeInterval exp = [[NSDate date] timeIntervalSince1970] + kAccessTokenExpiresIn;
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(exp) fat:YES];
}

// Returns an OIDAuthState holding a token response built from the arguments (fat ID token by default).
- (OIDAuthState *)authStateWithIDToken:(nullable NSString *)idToken
                           accessToken:(NSString *)accessToken
                             expiresIn:(nullable NSNumber *)expiresIn {
  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:idToken ?: [self freshFatIDToken]
                                    accessToken:accessToken
                                      expiresIn:expiresIn
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];
  return [OIDAuthState testInstanceWithTokenResponse:tokenResponse];
}

// Stores a GTMAuthSession for `authState` in the fake store, as a previous sign-in would have.
- (GTMAuthSession *)storeSessionWithAuthState:(OIDAuthState *)authState {
  GTMAuthSession *session = [[GTMAuthSession alloc] initWithAuthState:authState];
  _authSessionStore.savedAuthSession = session;
  return session;
}

// Starts an interactive sign-in with the given options and asserts the fake service received the request.
- (void)startSignInWithHint:(nullable NSString *)hint
           additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                      nonce:(nullable NSString *)nonce
                     claims:(nullable NSSet<GIDClaim *> *)claims {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  [_signIn signInWithPresentingViewController:_presentingViewController
                                         hint:hint
                             additionalScopes:additionalScopes
                                        nonce:nonce
                                       claims:claims
                                   completion:_completion];
#elif TARGET_OS_OSX
  [_signIn signInWithPresentingWindow:_presentingWindow
                                 hint:hint
                     additionalScopes:additionalScopes
                                nonce:nonce
                               claims:claims
                           completion:_completion];
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

  XCTAssertNotNil(_authorizationService.lastAuthorizationRequest);
  XCTAssertNotNil(_authorizationService.lastAuthorizationCallback);
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  XCTAssertTrue([_authorizationService.lastExternalUserAgent
      isKindOfClass:[OIDExternalUserAgentIOS class]]);
  XCTAssertEqual(
      ((OIDExternalUserAgentIOS *)_authorizationService.lastExternalUserAgent)
          .presentingViewController,
      _presentingViewController);
#elif TARGET_OS_OSX
  XCTAssertTrue([_authorizationService.lastExternalUserAgent
      isKindOfClass:[OIDExternalUserAgentMac class]]);
  XCTAssertEqual(
      ((OIDExternalUserAgentMac *)_authorizationService.lastExternalUserAgent).presentingWindow,
      _presentingWindow);
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

  NSDictionary<NSString *, NSObject *> *params =
      _authorizationService.lastAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"include_granted_scopes"], @"true");
  XCTAssertEqualObjects(params[kSDKVersionLoggingParameter], [GIDSignInPreferences sdkVersion]);
  XCTAssertEqualObjects(params[kEnvironmentLoggingParameter], [GIDSignInPreferences environment]);
}

// Completes the pending authorization request with a response built from the arguments.
- (void)finishAuthorizationWithAdditionalParameters:
            (nullable NSDictionary<NSString *, NSString *> *)additionalParameters
                                              nonce:(nullable NSString *)nonce
                                        errorString:(nullable NSString *)errorString {
  OIDAuthorizationResponse *testResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:additionalParameters
                                                               nonce:nonce
                                                         errorString:errorString];
  NSMutableDictionary<NSString *, NSObject<NSCopying> *> *parameters =
      [NSMutableDictionary dictionary];
  if (testResponse.authorizationCode) {
    parameters[@"code"] = testResponse.authorizationCode;
  }
  if (testResponse.state) {
    parameters[@"state"] = testResponse.state;
  }
  if (testResponse.tokenType) {
    parameters[@"token_type"] = testResponse.tokenType;
  }
  if (testResponse.additionalParameters) {
    [parameters addEntriesFromDictionary:testResponse.additionalParameters];
  }
  OIDAuthorizationRequest *request =
      _authorizationService.lastAuthorizationRequest ?: testResponse.request;
  OIDAuthorizationResponse *response =
      [[OIDAuthorizationResponse alloc] initWithRequest:request parameters:parameters];
  _authorizationService.lastAuthorizationCallback(response, nil);
}

// Completes the pending authorization request with an AppAuth error (no response).
- (void)failAuthorizationWithError:(NSError *)error {
  XCTAssertNotNil(_authorizationService.lastAuthorizationCallback);
  _authorizationService.lastAuthorizationCallback(nil, error);
}

// Completes the pending token request with a response (or error) and returns after the completion ran.
- (void)finishTokenRequestWithIDToken:(nullable NSString *)idToken
                          accessToken:(NSString *)accessToken
                            expiresIn:(nullable NSNumber *)expiresIn {
  XCTAssertNotNil(_authorizationService.lastTokenRequest);
  XCTAssertNotNil(_authorizationService.lastTokenCallback);
  OIDTokenResponse *response =
      [OIDTokenResponse testInstanceWithIDToken:idToken ?: [self freshFatIDToken]
                                    accessToken:accessToken
                                      expiresIn:expiresIn
                                   refreshToken:kRefreshToken
                                   tokenRequest:_authorizationService.lastTokenRequest];
  _authorizationService.lastTokenCallback(response, nil);
}

- (void)failTokenRequestWithError:(NSError *)error {
  XCTAssertNotNil(_authorizationService.lastTokenRequest);
  XCTAssertNotNil(_authorizationService.lastTokenCallback);
  _authorizationService.lastTokenCallback(nil, error);
}

// Waits for the sign-in completion to be called on the main queue.
- (void)waitForCompletion {
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:1];
  while (!_completionCalled && [deadline timeIntervalSinceNow] > 0) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
  }
  XCTAssertTrue(_completionCalled, @"the sign-in completion was not called within 1s");
}

// Full happy path: start, authorize, exchange the code for the fat ID token, wait. Returns the user.
- (GIDGoogleUser *)signInSuccessfully {
  [self startSignInWithHint:_hint additionalScopes:nil nonce:nil claims:nil];
  [self finishAuthorizationWithAdditionalParameters:nil nonce:nil errorString:nil];
  [self finishTokenRequestWithIDToken:nil accessToken:kAccessToken expiresIn:nil];
  [self waitForCompletion];
  XCTAssertNil(_authError);
  XCTAssertNotNil(_signIn.currentUser);
  return _signIn.currentUser;
}

// Returns the value for the query item with the given name in the array of query items.
- (nullable NSString *)valueForQueryItemName:(NSString *)name
                                     inArray:(NSArray<NSURLQueryItem *> *)queryItems {
  for (NSURLQueryItem *item in queryItems) {
    if ([item.name isEqualToString:name]) {
      return item.value;
    }
  }
  return nil;
}

// Whether or not a fetcher has been started.
- (BOOL)isFetcherStarted {
  NSUInteger count = _fetcherService.fetchers.count;
  XCTAssertTrue(count <= 1, @"Only one fetcher is supported");
  return !!count;
}

// Gets the URL being fetched.
- (NSURL *)fetchedURL {
  return [_fetcherService.fetchers[0] requestURL];
}

// Emulates server returning the data as in JSON.
- (void)didFetch:(id)dataObject error:(NSError *)error {
  NSData *data = nil;
  if (dataObject) {
    NSError *jsonError = nil;
    data = [NSJSONSerialization dataWithJSONObject:dataObject
                                           options:0
                                             error:&jsonError];
    XCTAssertNil(jsonError, @"must provide valid data");
  }
  [_fetcherService.fetchers[0] didFinishWithData:data error:error];
}

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

// Verifies a fetcher has started for revoking token and emulates a server response.
- (void)verifyAndRevokeToken:(NSString *)token
                 hasCallback:(BOOL)hasCallback
      waitingForExpectations:(NSArray<XCTestExpectation *> *)expectations {
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  NSURL *url = [self fetchedURL];
  XCTAssertEqualObjects([url scheme], @"https", @"scheme must match");
  XCTAssertEqualObjects([url host], @"accounts.google.com", @"host must match");
  XCTAssertEqualObjects([url path], @"/o/oauth2/revoke", @"path must match");
  OIDURLQueryComponent *queryComponent = [[OIDURLQueryComponent alloc] initWithURL:url];
  NSDictionary<NSString *, NSObject<NSCopying> *> *params = queryComponent.dictionaryValue;
  XCTAssertEqualObjects([params valueForKey:@"token"], token,
                        @"token parameter should match");
  XCTAssertEqualObjects([params valueForKey:kSDKVersionLoggingParameter],
                        [GIDSignInPreferences sdkVersion],
                        @"SDK version logging parameter should match");
  XCTAssertEqualObjects([params valueForKey:kEnvironmentLoggingParameter],
                        [GIDSignInPreferences environment],
                        @"Environment logging parameter should match");
  // Emulate result back from server.
  [self didFetch:nil error:nil];
  XCTAssertNil(_authSessionStore.savedAuthSession, @"should clear saved keychain name");
  if (hasCallback) {
    [self waitForExpectations:expectations timeout:1];
  }
}

#pragma mark - Private Helpers

- (NSDictionary<NSString *, NSString *> *)
    additionalParametersWithEMMPasscodeInfoRequired:(BOOL)emmPasscodeInfoRequired
                               claimsAsJSONRequired:(BOOL)claimsAsJSONRequired {
  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
      [NSMutableDictionary dictionary];

  if (emmPasscodeInfoRequired) {
    additionalParameters[@"emm_passcode_info_required"] = @"1";
  }
  if (claimsAsJSONRequired) {
    additionalParameters[@"claims"] = kNonEssentialAuthTimeClaimJsonString;
  }

  return [additionalParameters copy];
}

@end
