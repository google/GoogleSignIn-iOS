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

#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

// Test module imports
@import GoogleSignIn;

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import GTMSessionFetcherCore;
@import OCMock;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDGrantTypes.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <AppAuth/OIDURLQueryComponent.h>
#import <AppAuth/OIDAuthorizationService+IOS.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization+Keychain.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <OCMock/OCMock.h>
#endif

// Create a BLOCK to store the actual address for arg in param.
#define SAVE_TO_ARG_BLOCK(param) [OCMArg checkWithBlock:^(id arg) {\
    param = arg;\
    return YES;\
}]

#define COPY_TO_ARG_BLOCK(param) [OCMArg checkWithBlock:^(id arg) {\
    param = [arg copy];\
    return YES;\
}]

static NSString * const kFakeGaiaID = @"123456789";
static NSString * const kFakeIDToken = @"FakeIDToken";
static NSString * const kClientId = @"FakeClientID";
static NSString * const kDotReversedClientId = @"FakeClientID";
static NSString * const kClientId2 = @"FakeClientID2";
static NSString * const kAppBundleId = @"FakeBundleID";
static NSString * const kLanguage = @"FakeLanguage";
static NSString * const kScope = @"FakeScope";
static NSString * const kScope2 = @"FakeScope2";
static NSString * const kAuthCode = @"FakeAuthCode";
static NSString * const kPassword = @"FakePassword";
static NSString * const kFakeKeychainName = @"FakeKeychainName";
static NSString * const kUserEmail = @"FakeUserEmail";
static NSString * const kVerifier = @"FakeVerifier";
static NSString * const kOpenIDRealm = @"FakeRealm";
static NSString * const kFakeHostedDomain = @"fakehosteddomain.com";
static NSString * const kFakeUserName = @"fake username";
static NSString * const kFakeUserGivenName = @"fake";
static NSString * const kFakeUserFamilyName = @"username";
static NSString * const kFakeUserPictureURL = @"fake_user_picture_url";

static NSString * const kContinueURL = @"com.google.UnitTests:/oauth2callback";
static NSString * const kContinueURLWithClientID = @"FakeClientID:/oauth2callback";
static NSString * const kWrongSchemeURL = @"wrong.app:/oauth2callback";
static NSString * const kWrongPathURL = @"com.google.UnitTests:/wrong_path";

static NSString * const kEMMRestartAuthURL =
     @"com.google.UnitTests:///emmcallback?action=restart_auth";
static NSString * const kEMMWrongPathURL =
     @"com.google.UnitTests:///unknowcallback?action=restart_auth";
static NSString * const kEMMWrongActionURL =
     @"com.google.UnitTests:///emmcallback?action=unrecognized";
static NSString * const kDevicePolicyAppBundleID = @"com.google.DevicePolicy";

static NSString * const kAppHasRunBeforeKey = @"GPP_AppHasRunBefore";

static NSString * const kFingerprintKeychainName = @"fingerprint";
static NSString * const kVerifierKeychainName = @"verifier";
static NSString * const kVerifierKey = @"verifier";
static NSString * const kOpenIDRealmKey = @"openid.realm";
static NSString * const kSavedKeychainServiceName = @"saved-keychain";
static NSString * const kKeychainAccountName = @"GooglePlus";
static NSString * const kUserNameKey = @"name";
static NSString * const kUserGivenNameKey = @"givenName";
static NSString * const kUserFamilyNameKey = @"familyName";
static NSString * const kUserImageKey = @"picture";
static NSString * const kAppName = @"UnitTests";
static NSString * const kUserIDKey = @"userID";
static NSString * const kHostedDomainKey = @"hostedDomain";
static NSString * const kIDTokenExpirationKey = @"idTokenExp";
static NSString * const kScopeKey = @"scope";

// Basic profile (Fat ID Token / userinfo endpoint) keys
static NSString *const kBasicProfilePictureKey = @"picture";
static NSString *const kBasicProfileNameKey = @"name";
static NSString *const kBasicProfileGivenNameKey = @"given_name";
static NSString *const kBasicProfileFamilyNameKey = @"family_name";

static NSString * const kCustomKeychainName = @"CUSTOM_KEYCHAIN_NAME";
static NSString * const kAddActivity = @"http://schemas.google.com/AddActivity";
static NSString * const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 212;

static NSString *const kDriveScope = @"https://www.googleapis.com/auth/drive";

static NSString *const kTokenURL = @"https://oauth2.googleapis.com/token";

static NSString *const kFakeURL = @"http://foo.com";

static NSString *const kEMMSupport = @"1";

/// Unique pointer value for KVO tests.
static void *kTestObserverContext = &kTestObserverContext;

// This category is used to allow the test to swizzle a private method.
@interface UIViewController (Testing)

// This private method provides access to the window. It's declared here to avoid a warning about
// an unrecognized selector in the test.
- (UIWindow *)_window;

@end

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
  // Whether or not the OS version is eligible for EMM.
  BOOL _isEligibleForEMM;

  // Mock |OIDAuthState|.
  id _authState;

  // Mock |OIDTokenResponse|.
  id _tokenResponse;

  // Mock |OIDTokenRequest|.
  id _tokenRequest;

  // Mock |GTMAppAuthFetcherAuthorization|.
  id _authorization;

  // Mock |UIViewController|.
  id _presentingViewController;

  // Mock for |GIDGoogleUser|.
  id _user;

  // Mock for |GIDAuthentication|.
  id _authentication;

  // Mock for |OIDAuthorizationService|
  id _oidAuthorizationService;

  // Parameter saved from delegate call.
  NSError *_authError;

  // Whether callback block has been called.
  BOOL _callbackCalled;

  // Fake fetcher service to emulate network requests.
  GIDFakeFetcherService *_fetcherService;

  // Fake [NSBundle mainBundle];
  GIDFakeMainBundle *_fakeMainBundle;

  // Whether |saveParamsToKeychainForName:authentication:| has been called.
  BOOL _keychainSaved;

  // Whether |removeAuthFromKeychainForName:| has been called.
  BOOL _keychainRemoved;

  // The |GIDSignIn| object being tested.
  GIDSignIn *_signIn;

  // The configuration to be used when testing |GIDSignIn|.
  GIDConfiguration *_configuration;

  // The login hint to be used when testing |GIDSignIn|.
  NSString *_hint;

  // The callback to be used when testing |GIDSignIn|.
  GIDSignInCallback _callback;

  // The saved authorization request.
  OIDAuthorizationRequest *_savedAuthorizationRequest;

  // The saved presentingViewController from the authorization request.
  UIViewController *_savedPresentingViewController;

  // The saved authorization callback.
  OIDAuthorizationCallback _savedAuthorizationCallback;

  // The saved token request.
  OIDTokenRequest *_savedTokenRequest;

  // The saved token request callback.
  OIDTokenCallback _savedTokenCallback;

  // Set of all |GIDSignIn| key paths which were observed to change.
  NSMutableSet *_changedKeyPaths;

  // Status returned by saveAuthorization:toKeychainForName:
  BOOL _saveAuthorizationReturnValue;
}
@end

@implementation GIDSignInTest

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];
  _isEligibleForEMM = [UIDevice currentDevice].systemVersion.integerValue >= 9;
  _saveAuthorizationReturnValue = YES;

  // States
  _callbackCalled = NO;
  _keychainSaved = NO;
  _keychainRemoved = NO;
  _changedKeyPaths = [[NSMutableSet alloc] init];

  // Mocks
  _presentingViewController = OCMStrictClassMock([UIViewController class]);
  _authState = OCMStrictClassMock([OIDAuthState class]);
  OCMStub([_authState alloc]).andReturn(_authState);
  OCMStub([_authState initWithAuthorizationResponse:OCMOCK_ANY]).andReturn(_authState);
  _tokenResponse = OCMStrictClassMock([OIDTokenResponse class]);
  _tokenRequest = OCMStrictClassMock([OIDTokenRequest class]);
  _authorization = OCMStrictClassMock([GTMAppAuthFetcherAuthorization class]);
  OCMStub([_authorization authorizationFromKeychainForName:OCMOCK_ANY]).andReturn(_authorization);
  OCMStub([_authorization alloc]).andReturn(_authorization);
  OCMStub([_authorization initWithAuthState:OCMOCK_ANY]).andReturn(_authorization);
  OCMStub([_authorization saveAuthorization:OCMOCK_ANY toKeychainForName:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        self->_keychainSaved = self->_saveAuthorizationReturnValue;
        [invocation setReturnValue:&self->_saveAuthorizationReturnValue];
      });
  OCMStub([_authorization removeAuthorizationFromKeychainForName:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        self->_keychainRemoved = YES;
      });
  _user = OCMStrictClassMock([GIDGoogleUser class]);
  _authentication = OCMStrictClassMock([GIDAuthentication class]);
  _oidAuthorizationService = OCMStrictClassMock([OIDAuthorizationService class]);
  OCMStub([_oidAuthorizationService
      presentAuthorizationRequest:SAVE_TO_ARG_BLOCK(self->_savedAuthorizationRequest)
         presentingViewController:SAVE_TO_ARG_BLOCK(self->_savedPresentingViewController)
                         callback:COPY_TO_ARG_BLOCK(self->_savedAuthorizationCallback)]);
  OCMStub([self->_oidAuthorizationService
      performTokenRequest:SAVE_TO_ARG_BLOCK(self->_savedTokenRequest)
                 callback:COPY_TO_ARG_BLOCK(self->_savedTokenCallback)]);

  // Fakes
  _fetcherService = [[GIDFakeFetcherService alloc] init];
  _fakeMainBundle = [[GIDFakeMainBundle alloc] init];
  [_fakeMainBundle startFakingWithBundleId:kAppBundleId clientId:kClientId];
  [_fakeMainBundle fakeAllSchemesSupported];

  // Object under test
  [[NSUserDefaults standardUserDefaults] setBool:YES
                                          forKey:kAppHasRunBeforeKey];

  _signIn = [[GIDSignIn alloc] initPrivate];
  _configuration = [[GIDConfiguration alloc] initWithClientID:kClientId];
  _hint = nil;

  __weak GIDSignInTest *weakSelf = self;
  _callback = ^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
    GIDSignInTest *strongSelf = weakSelf;
    if (!user) {
      XCTAssertNotNil(error, @"should have an error if user is nil");
    }
    XCTAssertFalse(strongSelf->_callbackCalled, @"callback already called");
    strongSelf->_callbackCalled = YES;
    strongSelf->_authError = error;
  };

  [_signIn addObserver:self
            forKeyPath:NSStringFromSelector(@selector(currentUser))
               options:0
               context:kTestObserverContext];
}

- (void)tearDown {
  OCMVerifyAll(_authState);
  OCMVerifyAll(_tokenResponse);
  OCMVerifyAll(_tokenRequest);
  OCMVerifyAll(_authorization);
  OCMVerifyAll(_presentingViewController);
  OCMVerifyAll(_user);
  OCMVerifyAll(_authentication);
  OCMVerifyAll(_oidAuthorizationService);

  [_fakeMainBundle stopFaking];
  [super tearDown];

  [_signIn removeObserver:self
               forKeyPath:NSStringFromSelector(@selector(currentUser))
                  context:kTestObserverContext];
}

#pragma mark - Tests

- (void)testShareInstance {
  GIDSignIn *signIn1 = GIDSignIn.sharedInstance;
  GIDSignIn *signIn2 = GIDSignIn.sharedInstance;
  XCTAssertTrue(signIn1 == signIn2, @"shared instance must be singleton");
}

- (void)testRestorePreviousSignInNoRefresh_hasPreviousUser {
  [[[_authorization expect] andReturn:_authState] authState];
  OCMStub([_authState lastTokenResponse]).andReturn(_tokenResponse);
  OCMStub([_tokenResponse scope]).andReturn(nil);
  OCMStub([_tokenResponse additionalParameters]).andReturn(nil);
  OCMStub([_tokenResponse idToken]).andReturn(kFakeIDToken);
  OCMStub([_tokenResponse request]).andReturn(_tokenRequest);
  OCMStub([_tokenRequest additionalParameters]).andReturn(nil);

  id idTokenDecoded = OCMClassMock([OIDIDToken class]);
  OCMStub([idTokenDecoded alloc]).andReturn(idTokenDecoded);
  OCMStub([idTokenDecoded initWithIDTokenString:OCMOCK_ANY]).andReturn(idTokenDecoded);
  OCMStub([idTokenDecoded subject]).andReturn(kFakeGaiaID);

  [_signIn restorePreviousSignInNoRefresh];

  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
  XCTAssertEqual(_signIn.currentUser.userID, kFakeGaiaID);
}

- (void)testRestoredPreviousSignInNoRefresh_hasNoPreviousUser {
  [[[_authorization expect] andReturn:nil] authState];

  [_signIn restorePreviousSignInNoRefresh];

  [_authorization verify];
  XCTAssertNil(_signIn.currentUser);
}

- (void)testHasPreviousSignIn_HasBeenAuthenticated {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:YES]] isAuthorized];
  XCTAssertTrue([_signIn hasPreviousSignIn], @"should return |YES|");
  [_authorization verify];
  [_authState verify];
  XCTAssertFalse(_keychainRemoved, @"should not remove keychain");
  XCTAssertFalse(_callbackCalled, @"should not call delegate");
  XCTAssertNil(_authError, @"should have no error");
}

- (void)testHasPreviousSignIn_HasNotBeenAuthenticated {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:NO]] isAuthorized];
  XCTAssertFalse([_signIn hasPreviousSignIn], @"should return |NO|");
  [_authorization verify];
  [_authState verify];
  XCTAssertFalse(_keychainRemoved, @"should not remove keychain");
  XCTAssertFalse(_callbackCalled, @"should not call delegate");
}

- (void)testRestorePreviousSignInWhenSignedOut {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:NO]] isAuthorized];
  _callbackCalled = NO;
  _authError = nil;

  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called."];

  [_signIn restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user,
                                               NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNotNil(error, @"error should not have been nil");
    XCTAssertEqual(error.domain,
                   kGIDSignInErrorDomain,
                   @"error domain should have been the sign-in error domain.");
    XCTAssertEqual(error.code,
                   kGIDSignInErrorCodeHasNoAuthInKeychain,
                   @"error code should have been the 'NoAuthInKeychain' error code.");
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
  [_authorization verify];
  [_authState verify];
}

- (void)testOAuthLogin {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];
}

- (void)testOAuthLogin_RestoredSignIn {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:YES
               oldAccessToken:NO
                  modalCancel:NO];
}

- (void)testOAuthLogin_RestoredSignInOldAccessToken {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:YES
               oldAccessToken:YES
                  modalCancel:NO];
}

- (void)testOpenIDRealm {
  _configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                               serverClientID:nil
                                                 hostedDomain:nil
                                                  openIDRealm:kOpenIDRealm];

  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  NSDictionary<NSString *, NSString *> *params = _savedTokenRequest.additionalParameters;
  XCTAssertEqual(params[kOpenIDRealmKey], kOpenIDRealm, @"OpenID Realm should match.");
}

- (void)testOAuthLogin_LoginHint {
  _hint = kUserEmail;

  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  NSDictionary<NSString *, NSObject *> *params = _savedAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"login_hint"], kUserEmail, @"login hint should match");
}

- (void)testOAuthLogin_HostedDomain {
  _configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                               serverClientID:nil
                                                 hostedDomain:kHostedDomain
                                                  openIDRealm:nil];

  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  NSDictionary<NSString *, NSObject *> *params = _savedAuthorizationRequest.additionalParameters;
  XCTAssertEqualObjects(params[@"hd"], kHostedDomain, @"hosted domain should match");
}

- (void)testOAuthLogin_ConsentCanceled {
  [self OAuthLoginWithOptions:nil
                    authError:@"access_denied"
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_callbackCalled, @"should call delegate");
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
}

- (void)testOAuthLogin_ModalCanceled {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:YES];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_callbackCalled, @"should call delegate");
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
}

- (void)testOAuthLogin_KeychainError {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:YES
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(_keychainSaved, @"should save to keychain");
  XCTAssertTrue(_callbackCalled, @"should call delegate");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeKeychain);
}

- (void)testSignOut {
  // Sign in a user so that we can then sign them out.
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:YES
               oldAccessToken:NO
                  modalCancel:NO];

  XCTAssertNotNil(_signIn.currentUser);

  [_signIn signOut];
  XCTAssertNil(_signIn.currentUser, @"should not have a current user");
  XCTAssertTrue(_keychainRemoved, @"should remove keychain");
  XCTAssertTrue([_changedKeyPaths containsObject:NSStringFromSelector(@selector(currentUser))],
                @"should notify observers that signed in user changed");
}

- (void)testNotHandleWrongScheme {
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongSchemeURL]],
                 @"should not handle URL");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertFalse(_callbackCalled, @"should not call delegate");
}

- (void)testNotHandleWrongPath {
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongPathURL]], @"should not handle URL");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertFalse(_callbackCalled, @"should not call delegate");
}

#pragma mark - Tests - disconnectWithCallback:

// Verifies disconnect calls callback with no errors if access token is present.
- (void)testDisconnect_accessToken {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kAccessToken] accessToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCallback:^(NSError * _Nullable error) {
    if (error == nil) {
      [expectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kAccessToken hasCallback:YES];
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

// Verifies disconnect if access token is present.
- (void)testDisconnectNoCallback_accessToken {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kAccessToken] accessToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  [_signIn disconnectWithCallback:nil];
  [self verifyAndRevokeToken:kAccessToken hasCallback:NO];
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

// Verifies disconnect calls callback with no errors if refresh token is present.
- (void)testDisconnect_refreshToken {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:nil] accessToken];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kRefreshToken] refreshToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCallback:^(NSError * _Nullable error) {
    if (error == nil) {
      [expectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kRefreshToken hasCallback:YES];
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

// Verifies disconnect errors are passed along to the callback.
- (void)testDisconnect_errors {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kAccessToken] accessToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with an error"];
  [_signIn disconnectWithCallback:^(NSError * _Nullable error) {
    if (error != nil) {
      [expectation fulfill];
    }
  }];
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

// Verifies disconnect with errors
- (void)testDisconnectNoCallback_errors {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kAccessToken] accessToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  [_signIn disconnectWithCallback:nil];
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}


// Verifies disconnect calls callback with no errors and clears keychain if no tokens are present.
- (void)testDisconnect_noTokens {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:nil] accessToken];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:nil] refreshToken];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCallback:^(NSError * _Nullable error) {
    if (error == nil) {
      [expectation fulfill];
    }
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse([self isFetcherStarted], @"should not fetch");
  XCTAssertTrue(_keychainRemoved, @"keychain should be removed");
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

// Verifies disconnect clears keychain if no tokens are present.
- (void)testDisconnectNoCallback_noTokens {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:nil] accessToken];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:nil] refreshToken];
  [_signIn disconnectWithCallback:nil];
  XCTAssertFalse([self isFetcherStarted], @"should not fetch");
  XCTAssertTrue(_keychainRemoved, @"keychain should be removed");
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
}

- (void)testPresentingViewControllerException {
  _presentingViewController = nil;
  XCTAssertThrows([_signIn signInWithConfiguration:_configuration
                          presentingViewController:_presentingViewController
                                              hint:_hint
                                          callback:_callback]);
}

- (void)testClientIDMissingException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop
  BOOL threw = NO;
  @try {
    [_signIn signInWithConfiguration:configuration
            presentingViewController:_presentingViewController
                            callback:nil];
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
    [_signIn signInWithConfiguration:_configuration
            presentingViewController:_presentingViewController
                                hint:_hint
                            callback:_callback];
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

- (void)testEmmSupportRequestParameters {
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  NSString *systemName = [UIDevice currentDevice].systemName;
  if ([systemName isEqualToString:@"iPhone OS"]) {
    systemName = @"iOS";
  }
  NSString *expectedOSVersion = [NSString stringWithFormat:@"%@ %@",
      systemName, [UIDevice currentDevice].systemVersion];
  NSDictionary<NSString *, NSObject *> *authParams =
      _savedAuthorizationRequest.additionalParameters;
  NSDictionary<NSString *, NSString *> *tokenParams = _savedTokenRequest.additionalParameters;
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
  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:nil
      emmPasscodeInfoRequired:YES
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];
  NSDictionary<NSString *, NSString *> *tokenParams = _savedTokenRequest.additionalParameters;
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
  __block void (^completion)(void);
  NSDictionary<NSString *, NSString *> *callbackParams = @{ @"error" : @"EMM Specific Error" };
  [[[mockEMMErrorHandler expect] andReturnValue:@YES]
      handleErrorFromResponse:callbackParams completion:SAVE_TO_ARG_BLOCK(completion)];


  [self OAuthLoginWithOptions:nil
                    authError:callbackParams[@"error"]
                   tokenError:nil
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  [mockEMMErrorHandler verify];
  [mockEMMErrorHandler stopMocking];
  completion();

  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertTrue(_callbackCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeEMM);
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
  [[_authentication expect] handleTokenFetchEMMError:emmError
                                          completion:SAVE_TO_ARG_BLOCK(completion)];


  [self OAuthLoginWithOptions:nil
                    authError:nil
                   tokenError:emmError
      emmPasscodeInfoRequired:NO
                keychainError:NO
               restoredSignIn:NO
               oldAccessToken:NO
                  modalCancel:NO];

  NSError *handledError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                              code:kGIDSignInErrorCodeEMM
                                          userInfo:emmError.userInfo];
  completion(handledError);

  [self waitForExpectationsWithTimeout:1 handler:nil];

  [_authentication verify];
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertTrue(_callbackCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeEMM);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

#pragma mark - Helpers

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
- (void)verifyAndRevokeToken:(NSString *)token hasCallback:(BOOL)hasCallback {
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  NSURL *url = [self fetchedURL];
  XCTAssertEqualObjects([url scheme], @"https", @"scheme must match");
  XCTAssertEqualObjects([url host], @"accounts.google.com", @"host must match");
  XCTAssertEqualObjects([url path], @"/o/oauth2/revoke", @"path must match");
  OIDURLQueryComponent *queryComponent = [[OIDURLQueryComponent alloc] initWithURL:url];
  NSDictionary<NSString *, NSObject<NSCopying> *> *params = queryComponent.dictionaryValue;
  XCTAssertEqualObjects([params valueForKey:@"token"], token,
                        @"token parameter should match");
  // Emulate result back from server.
  [self didFetch:nil error:nil];
  if (hasCallback) {
    [self waitForExpectationsWithTimeout:1 handler:nil];
  }
  XCTAssertTrue(_keychainRemoved, @"should clear saved keychain name");
}

// The authorization flow with parameters to control which branches to take.
- (void)OAuthLoginWithOptions:(GIDSignInInternalOptions *)options
                    authError:(NSString *)authError
                   tokenError:(NSError *)tokenError
      emmPasscodeInfoRequired:(BOOL)emmPasscodeInfoRequired
                keychainError:(BOOL)keychainError
               restoredSignIn:(BOOL)restoredSignIn
               oldAccessToken:(BOOL)oldAccessToken
                  modalCancel:(BOOL)modalCancel {
  if (restoredSignIn) {
    // clearAndAuthenticateWithOptions
    [[[_authorization expect] andReturn:_authState] authState];
    BOOL isAuthorized = restoredSignIn ? YES : NO;
    [[[_authState expect] andReturnValue:[NSNumber numberWithBool:isAuthorized]] isAuthorized];
  }

  NSDictionary<NSString *, NSString *> *additionalParameters = emmPasscodeInfoRequired ?
      @{ @"emm_passcode_info_required" : @"1" } : nil;
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:additionalParameters
                                                         errorString:authError];

  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:[OIDTokenResponse fatIDToken]
                                    accessToken:restoredSignIn ? kAccessToken : nil
                                      expiresIn:oldAccessToken ? @(300) : nil
                                   tokenRequest:nil];

  OIDTokenRequest *tokenRequest = [[OIDTokenRequest alloc]
      initWithConfiguration:authResponse.request.configuration
                  grantType:OIDGrantTypeRefreshToken
          authorizationCode:nil
                redirectURL:nil
                   clientID:authResponse.request.clientID
               clientSecret:authResponse.request.clientSecret
                      scope:nil
               refreshToken:kRefreshToken
               codeVerifier:nil
       additionalParameters:tokenResponse.request.additionalParameters];

  if (restoredSignIn) {
    // maybeFetchToken
    [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
    [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
    if (oldAccessToken) {
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
      [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
      [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
      [[[_authState expect] andReturn:tokenRequest]
          tokenRefreshRequestWithAdditionalParameters:[OCMArg any]];
    }
  } else {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback called"];
    [_signIn signInWithConfiguration:_configuration
            presentingViewController:_presentingViewController
                                hint:_hint
                            callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
      [expectation fulfill];
      if (!user) {
        XCTAssertNotNil(error, @"should have an error if user is nil");
      }
      XCTAssertFalse(self->_callbackCalled, @"callback already called");
      self->_callbackCalled = YES;
      self->_authError = error;
    }];

    [_authorization verify];
    [_authState verify];

    XCTAssertNotNil(_savedAuthorizationRequest);
    XCTAssertNotNil(_savedAuthorizationCallback);
    XCTAssertEqual(_savedPresentingViewController, _presentingViewController);

    // maybeFetchToken
    if (!(authError || modalCancel)) {
      [[[_authState expect] andReturn:nil] lastTokenResponse];
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
      [[[_authState expect] andReturn:nil] lastTokenResponse];
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
    }

    // Simulate auth endpoint response
    if (modalCancel) {
      NSError *error = [NSError errorWithDomain:OIDGeneralErrorDomain
                                           code:OIDErrorCodeUserCanceledAuthorizationFlow
                                       userInfo:nil];
      _savedAuthorizationCallback(nil, error);
    } else {
      _savedAuthorizationCallback(authResponse, nil);
    }

    if (authError || modalCancel) {
      return;
    }
    [_authState verify];
  }

  if (restoredSignIn && oldAccessToken) {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called"];
    [_signIn restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user,
                                                 NSError * _Nullable error) {
      [expectation fulfill];
      XCTAssertNil(error, @"should have no error");
    }];
  }

  if (!restoredSignIn || (restoredSignIn && oldAccessToken)) {
    XCTAssertNotNil(_savedTokenRequest);
    XCTAssertNotNil(_savedTokenCallback);

    // OIDTokenCallback
    if (tokenError) {
      [[_authState expect] updateWithTokenResponse:nil error:tokenError];
    } else {
      [[_authState expect] updateWithTokenResponse:[OCMArg any] error:nil];
    }
  }

  if (tokenError) {
    _savedTokenCallback(nil, tokenError);
    return;
  }

  // DecodeIdTokenCallback
  [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];

  // SaveAuthCallback
  [[[_user stub] andReturn:_user] alloc];
  __block OIDAuthState *authState;
  __block GIDProfileData *profileData;

  if (keychainError) {
    _saveAuthorizationReturnValue = NO;
  } else {
    (void)[[[_user expect] andReturn:_user] initWithAuthState:SAVE_TO_ARG_BLOCK(authState)
                                                  profileData:SAVE_TO_ARG_BLOCK(profileData)];
  }

  if (restoredSignIn && !oldAccessToken) {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called"];
    [_signIn restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user,
                                                 NSError * _Nullable error) {
      [expectation fulfill];
      XCTAssertNil(error, @"should have no error");
    }];
  } else {
    // Simulate token endpoint response.
    _savedTokenCallback(tokenResponse, nil);
  }

  [_authState verify];
  if (keychainError) {
    return;
  }
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_keychainSaved, @"should save to keychain");
  XCTAssertNotNil(authState);
  // Check fat ID token decoding
  XCTAssertEqualObjects(profileData.name, kFatName);
  XCTAssertEqualObjects(profileData.givenName, kFatGivenName);
  XCTAssertEqualObjects(profileData.familyName, kFatFamilyName);
  XCTAssertTrue(profileData.hasImage);

  // If attempt to authenticate again, will reuse existing auth object.
  _callbackCalled = NO;
  _keychainRemoved = NO;
  _keychainSaved = NO;
  _authError = nil;
  [[[_user expect] andReturn:_authentication] authentication];
  [[[_user expect] andReturn:_authentication] authentication];
  __block GIDAuthenticationAction action;
  [[_authentication expect] doWithFreshTokens:SAVE_TO_ARG_BLOCK(action)];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called"];

  [_signIn restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user,
                                               NSError * _Nullable error) {
    [expectation fulfill];
    XCTAssertNil(error, @"should have no error");
  }];

  action(_authentication, nil);

  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(_keychainRemoved, @"should not remove keychain");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain again");
}


#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if (context == kTestObserverContext && object == _signIn) {
    [_changedKeyPaths addObject:keyPath];
  }
}

@end
