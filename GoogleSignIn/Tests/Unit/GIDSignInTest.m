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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
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

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
#import <AppAuth/OIDAuthorizationService+IOS.h>
#elif TARGET_OS_OSX
#import <AppAuth/OIDAuthorizationService+Mac.h>
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

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
static NSString * const kServerClientId = @"FakeServerClientID";
static NSString * const kLanguage = @"FakeLanguage";
static NSString * const kScope = @"FakeScope";
static NSString * const kScope2 = @"FakeScope2";
static NSString * const kAuthCode = @"FakeAuthCode";
static NSString * const kKeychainName = @"auth";
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

static NSString *const kGrantedScope = @"grantedScope";
static NSString *const kNewScope = @"newScope";

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
// This category is used to allow the test to swizzle a private method.
@interface UIViewController (Testing)

// This private method provides access to the window. It's declared here to avoid a warning about
// an unrecognized selector in the test.
- (UIWindow *)_window;

@end
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

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

  // Mock |GTMAuthSession|.
  id _authorization;

  // Mock |GTMKeychainStore|.
  id _keychainStore;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  // Mock |UIViewController|.
  id _presentingViewController;
#elif TARGET_OS_OSX
  // Mock |NSWindow|.
  id _presentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

  // Mock for |GIDGoogleUser|.
  id _user;

  // Mock for |OIDAuthorizationService|
  id _oidAuthorizationService;

  // Parameter saved from delegate call.
  NSError *_authError;

  // Whether callback block has been called.
  BOOL _completionCalled;

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

  // The completion to be used when testing |GIDSignIn|.
  GIDSignInCompletion _completion;

  // The saved authorization request.
  OIDAuthorizationRequest *_savedAuthorizationRequest;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  // The saved presentingViewController from the authorization request.
  UIViewController *_savedPresentingViewController;
#elif TARGET_OS_OSX
  // The saved presentingWindow from the authorization request.
  NSWindow *_savedPresentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

  // The saved authorization callback.
  OIDAuthorizationCallback _savedAuthorizationCallback;

  // The saved token request.
  OIDTokenRequest *_savedTokenRequest;

  // The saved token request callback.
  OIDTokenCallback _savedTokenCallback;

  // Status returned by saveAuthorization:toKeychainForName:
  BOOL _saveAuthorizationReturnValue;
}
@end

@implementation GIDSignInTest

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  _isEligibleForEMM = [UIDevice currentDevice].systemVersion.integerValue >= 9;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  _saveAuthorizationReturnValue = YES;

  // States
  _completionCalled = NO;
  _keychainSaved = NO;
  _keychainRemoved = NO;

  // Mocks
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  _presentingViewController = OCMStrictClassMock([UIViewController class]);
#elif TARGET_OS_OSX
  _presentingWindow = OCMStrictClassMock([NSWindow class]);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
  _authState = OCMStrictClassMock([OIDAuthState class]);
  OCMStub([_authState alloc]).andReturn(_authState);
  OCMStub([_authState initWithAuthorizationResponse:OCMOCK_ANY]).andReturn(_authState);
  _tokenResponse = OCMStrictClassMock([OIDTokenResponse class]);
  _tokenRequest = OCMStrictClassMock([OIDTokenRequest class]);
  _authorization = OCMStrictClassMock([GTMAuthSession class]);
  _keychainStore = OCMStrictClassMock([GTMKeychainStore class]);
  OCMStub(
    [_keychainStore retrieveAuthSessionWithItemName:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andReturn(_authorization);
  OCMStub([_keychainStore retrieveAuthSessionWithError:nil]).andReturn(_authorization);
  OCMStub([_authorization alloc]).andReturn(_authorization);
  OCMStub([_authorization initWithAuthState:OCMOCK_ANY]).andReturn(_authorization);
  OCMStub(
    [_keychainStore removeAuthSessionWithError:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainRemoved = YES;
  });
  _user = OCMStrictClassMock([GIDGoogleUser class]);
  _oidAuthorizationService = OCMStrictClassMock([OIDAuthorizationService class]);
  OCMStub([_oidAuthorizationService
      presentAuthorizationRequest:SAVE_TO_ARG_BLOCK(self->_savedAuthorizationRequest)
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
           presentingViewController:SAVE_TO_ARG_BLOCK(self->_savedPresentingViewController)
#elif TARGET_OS_OSX
           presentingWindow:SAVE_TO_ARG_BLOCK(self->_savedPresentingWindow)
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                         callback:COPY_TO_ARG_BLOCK(self->_savedAuthorizationCallback)]);
  OCMStub([self->_oidAuthorizationService
      performTokenRequest:SAVE_TO_ARG_BLOCK(self->_savedTokenRequest)
                 callback:COPY_TO_ARG_BLOCK(self->_savedTokenCallback)]);

  // Fakes
  _fetcherService = [[GIDFakeFetcherService alloc] init];
  _fakeMainBundle = [[GIDFakeMainBundle alloc] init];
  [_fakeMainBundle startFakingWithClientID:kClientId];
  [_fakeMainBundle fakeAllSchemesSupported];

  // Object under test
  [[NSUserDefaults standardUserDefaults] setBool:YES
                                          forKey:kAppHasRunBeforeKey];

  _signIn = [[GIDSignIn alloc] initWithKeychainStore:_keychainStore];
  _hint = nil;

  __weak GIDSignInTest *weakSelf = self;
  _completion = ^(GIDSignInResult *_Nullable signInResult, NSError * _Nullable error) {
    GIDSignInTest *strongSelf = weakSelf;
    if (!signInResult) {
      XCTAssertNotNil(error, @"should have an error if the signInResult is nil");
    }
    XCTAssertFalse(strongSelf->_completionCalled, @"callback already called");
    strongSelf->_completionCalled = YES;
    strongSelf->_authError = error;
  };
}

- (void)tearDown {
  OCMVerifyAll(_authState);
  OCMVerifyAll(_tokenResponse);
  OCMVerifyAll(_tokenRequest);
  OCMVerifyAll(_authorization);
  OCMVerifyAll(_user);
  OCMVerifyAll(_oidAuthorizationService);

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  OCMVerifyAll(_presentingViewController);
#elif TARGET_OS_OSX
  OCMVerifyAll(_presentingWindow);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST


  [_fakeMainBundle stopFaking];
  [super tearDown];
}

#pragma mark - Tests

- (void)testShareInstance {
  GIDSignIn *signIn1 = GIDSignIn.sharedInstance;
  GIDSignIn *signIn2 = GIDSignIn.sharedInstance;
  XCTAssertTrue(signIn1 == signIn2, @"shared instance must be singleton");
}

- (void)testInitPrivate {
  GIDSignIn *signIn = [[GIDSignIn alloc] initPrivate];
  XCTAssertNotNil(signIn.configuration);
  XCTAssertEqual(signIn.configuration.clientID, kClientId);
  XCTAssertNil(signIn.configuration.serverClientID);
  XCTAssertNil(signIn.configuration.hostedDomain);
  XCTAssertNil(signIn.configuration.openIDRealm);
}

- (void)testInitPrivate_noConfig {
  [_fakeMainBundle fakeWithClientID:nil
                     serverClientID:nil
                       hostedDomain:nil
                        openIDRealm:nil];
  GIDSignIn *signIn = [[GIDSignIn alloc] initPrivate];
  XCTAssertNil(signIn.configuration);
}

- (void)testInitPrivate_fullConfig {
  [_fakeMainBundle fakeWithClientID:kClientId
                     serverClientID:kServerClientId
                       hostedDomain:kFakeHostedDomain
                        openIDRealm:kOpenIDRealm];
  GIDSignIn *signIn = [[GIDSignIn alloc] initPrivate];
  XCTAssertNotNil(signIn.configuration);
  XCTAssertEqual(signIn.configuration.clientID, kClientId);
  XCTAssertEqual(signIn.configuration.serverClientID, kServerClientId);
  XCTAssertEqual(signIn.configuration.hostedDomain, kFakeHostedDomain);
  XCTAssertEqual(signIn.configuration.openIDRealm, kOpenIDRealm);
}

- (void)testInitPrivate_invalidConfig {
  [_fakeMainBundle fakeWithClientID:@[ @"bad", @"config", @"values" ]
                     serverClientID:nil
                       hostedDomain:nil
                        openIDRealm:nil];
  GIDSignIn *signIn = [[GIDSignIn alloc] initPrivate];
  XCTAssertNil(signIn.configuration);
}

- (void)testRestorePreviousSignInNoRefresh_hasPreviousUser {
  [[[_authorization stub] andReturn:_authState] authState];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [[_authorization expect] setDelegate:OCMOCK_ANY];
#endif // TARGET_OS_IOS || !TARGET_OS_MACCATALYST
  OCMStub([_authState lastTokenResponse]).andReturn(_tokenResponse);
  OCMStub([_authState refreshToken]).andReturn(kRefreshToken);
  [[_authState expect] setStateChangeDelegate:OCMOCK_ANY];

  id idTokenDecoded = OCMClassMock([OIDIDToken class]);
  OCMStub([idTokenDecoded alloc]).andReturn(idTokenDecoded);
  OCMStub([idTokenDecoded initWithIDTokenString:OCMOCK_ANY]).andReturn(idTokenDecoded);
  OCMStub([idTokenDecoded subject]).andReturn(kFakeGaiaID);
  
  // Mock generating a GIDConfiguration when initializing GIDGoogleUser.
  OIDAuthorizationResponse *authResponse =
      [OIDAuthorizationResponse testInstanceWithAdditionalParameters:nil
                                                         errorString:nil];
  
  OCMStub([_authState lastAuthorizationResponse]).andReturn(authResponse);
  OCMStub([_tokenResponse idToken]).andReturn(kFakeIDToken);
  OCMStub([_tokenResponse request]).andReturn(_tokenRequest);
  OCMStub([_tokenRequest additionalParameters]).andReturn(nil);
  OCMStub([_tokenResponse accessToken]).andReturn(kAccessToken);
  OCMStub([_tokenResponse accessTokenExpirationDate]).andReturn(nil);
  
  [_signIn restorePreviousSignInNoRefresh];

  [idTokenDecoded verify];
  XCTAssertEqual(_signIn.currentUser.userID, kFakeGaiaID);

  [idTokenDecoded stopMocking];
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
  XCTAssertFalse(_completionCalled, @"should not call delegate");
  XCTAssertNil(_authError, @"should have no error");
}

- (void)testHasPreviousSignIn_HasNotBeenAuthenticated {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:NO]] isAuthorized];
  XCTAssertFalse([_signIn hasPreviousSignIn], @"should return |NO|");
  [_authorization verify];
  [_authState verify];
  XCTAssertFalse(_keychainRemoved, @"should not remove keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

- (void)testRestorePreviousSignInWhenSignedOut {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:NO]] isAuthorized];
  _completionCalled = NO;
  _authError = nil;

  XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should be called."];

  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser *_Nullable user,
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

- (void)testNotRestorePreviousSignInWhenSignedOutAndCompletionIsNil {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:NO]] isAuthorized];

  [_signIn restorePreviousSignInWithCompletion:nil];

  XCTAssertNil(_signIn.currentUser);
}

- (void)testRestorePreviousSignInWhenCompletionIsNil {
  [[[_authorization expect] andReturn:_authState] authState];
  [[_keychainStore expect] saveAuthSession:OCMOCK_ANY error:[OCMArg anyObjectRef]];
  [[[_authState expect] andReturnValue:[NSNumber numberWithBool:YES]] isAuthorized];

  OIDTokenResponse *tokenResponse =
      [OIDTokenResponse testInstanceWithIDToken:[OIDTokenResponse fatIDToken]
                                    accessToken:kAccessToken
                                      expiresIn:nil
                                   refreshToken:kRefreshToken
                                   tokenRequest:nil];

  [[[_authState stub] andReturn:tokenResponse] lastTokenResponse];

  // TODO: Create a real GIDGoogleUser to verify the signed in user value(#306).
  [[[_user stub] andReturn:_user] alloc];
  (void)[[[_user expect] andReturn:_user] initWithAuthState:OCMOCK_ANY
                                                profileData:OCMOCK_ANY];
  XCTAssertNil(_signIn.currentUser);

  [_signIn restorePreviousSignInWithCompletion:nil];

  XCTAssertNotNil(_signIn.currentUser);
}

- (void)testOAuthLogin {
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO];
}

- (void)testOAuthLogin_RestoredSignIn {
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:YES
                     oldAccessToken:NO
                        modalCancel:NO];
}

- (void)testOAuthLogin_RestoredSignInOldAccessToken {
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:YES
                     oldAccessToken:YES
                        modalCancel:NO];
}

- (void)testOAuthLogin_AdditionalScopes {
  NSString *expectedScopeString;

  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO
                useAdditionalScopes:YES
                   additionalScopes:nil];

  expectedScopeString = [@[ @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_savedAuthorizationRequest.scope, expectedScopeString);

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO
                useAdditionalScopes:YES
                   additionalScopes:@[ kScope ]];

  expectedScopeString = [@[ kScope, @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_savedAuthorizationRequest.scope, expectedScopeString);

  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO
                useAdditionalScopes:YES
                   additionalScopes:@[ kScope, kScope2 ]];

  expectedScopeString = [@[ kScope, kScope2, @"email", @"profile" ] componentsJoinedByString:@" "];
  XCTAssertEqualObjects(_savedAuthorizationRequest.scope, expectedScopeString);
}

- (void)testAddScopes {
  // Restore the previous sign-in account. This is the preparation for adding scopes.
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });
  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:YES
                     oldAccessToken:NO
                        modalCancel:NO];

  XCTAssertNotNil(_signIn.currentUser);

  id profile = OCMStrictClassMock([GIDProfileData class]);
  OCMStub([profile email]).andReturn(kUserEmail);
  
  // Mock for the method `addScopes`.
  GIDConfiguration *configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                                serverClientID:nil
                                                                  hostedDomain:nil
                                                                   openIDRealm:kOpenIDRealm];
  OCMStub([_user configuration]).andReturn(configuration);
  OCMStub([_user profile]).andReturn(profile);
  OCMStub([_user grantedScopes]).andReturn(@[kGrantedScope]);

  [self OAuthLoginWithAddScopesFlow:YES
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO];

  NSArray<NSString *> *grantedScopes;
  NSString *grantedScopeString = _savedAuthorizationRequest.scope;

  if (grantedScopeString) {
    grantedScopeString = [grantedScopeString stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
    // Tokenize with space as a delimiter.
    NSMutableArray<NSString *> *parsedScopes =
        [[grantedScopeString componentsSeparatedByString:@" "] mutableCopy];
    // Remove empty strings.
    [parsedScopes removeObject:@""];
    grantedScopes = [parsedScopes copy];
  }
  
  NSArray<NSString *> *expectedScopes = @[kNewScope, kGrantedScope];
  XCTAssertEqualObjects(grantedScopes, expectedScopes);

  [_user verify];
  [profile verify];
  [profile stopMocking];
}

- (void)testOpenIDRealm {
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                      serverClientID:nil
                                                        hostedDomain:nil
                                                         openIDRealm:kOpenIDRealm];

  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
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

  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
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
  _signIn.configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                                      serverClientID:nil
                                                        hostedDomain:kHostedDomain
                                                         openIDRealm:nil];

  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
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
  [self OAuthLoginWithAddScopesFlow:NO
                          authError:@"access_denied"
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
}

- (void)testOAuthLogin_ModalCanceled {
  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:NO
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:YES];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeCanceled);
}

- (void)testOAuthLogin_KeychainError {
  // This error is going be overidden by `-[GIDSignIn errorWithString:code:]`
  // We just need to fill in the error so that happens.
  NSError *keychainError = [NSError errorWithDomain:@"com.googleSignIn.throwAway"
                                               code:1
                                           userInfo:nil];
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:[OCMArg setTo:keychainError]]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });
  [self OAuthLoginWithAddScopesFlow:NO
                          authError:nil
                         tokenError:nil
            emmPasscodeInfoRequired:NO
                      keychainError:YES
                     restoredSignIn:NO
                     oldAccessToken:NO
                        modalCancel:NO];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(_keychainSaved, @"should save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeKeychain);
}

- (void)testSignOut {
#if TARGET_OS_IOS || !TARGET_OS_MACCATALYST
//  OCMStub([_authorization authState]).andReturn(_authState);
#endif // TARGET_OS_IOS || !TARGET_OS_MACCATALYST
  OCMStub([_authorization fetcherService]).andReturn(_fetcherService);
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  // Sign in a user so that we can then sign them out.
  [self OAuthLoginWithAddScopesFlow:NO
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

  OCMVerify([_keychainStore removeAuthSessionWithError:OCMArg.anyObjectRef]);
}

- (void)testNotHandleWrongScheme {
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongSchemeURL]],
                 @"should not handle URL");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

- (void)testNotHandleWrongPath {
  XCTAssertFalse([_signIn handleURL:[NSURL URLWithString:kWrongPathURL]], @"should not handle URL");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertFalse(_completionCalled, @"should not call delegate");
}

#pragma mark - Tests - disconnectWithCallback:

// Verifies disconnect calls callback with no errors if access token is present.
- (void)testDisconnect_accessToken {
  [[[_authorization expect] andReturn:_authState] authState];
  [[[_authState expect] andReturn:_tokenResponse] lastTokenResponse];
  [[[_tokenResponse expect] andReturn:kAccessToken] accessToken];
  [[[_authorization expect] andReturn:_fetcherService] fetcherService];
  XCTestExpectation *accessTokenExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError * _Nullable error) {
    if (error == nil) {
      [accessTokenExpectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kAccessToken
                 hasCallback:YES
      waitingForExpectations:@[accessTokenExpectation]];
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
  [_signIn disconnectWithCompletion:nil];
  [self verifyAndRevokeToken:kAccessToken hasCallback:NO waitingForExpectations:@[]];
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
  XCTestExpectation *refreshTokenExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError * _Nullable error) {
    if (error == nil) {
      [refreshTokenExpectation fulfill];
    }
  }];
  [self verifyAndRevokeToken:kRefreshToken
                 hasCallback:YES
      waitingForExpectations:@[refreshTokenExpectation]];
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
  XCTestExpectation *errorExpectation =
      [self expectationWithDescription:@"Callback called with an error"];
  [_signIn disconnectWithCompletion:^(NSError * _Nullable error) {
    if (error != nil) {
      [errorExpectation fulfill];
    }
  }];
  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  [self waitForExpectations:@[errorExpectation] timeout:1];
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
  [_signIn disconnectWithCompletion:nil];
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
  XCTestExpectation *noTokensExpectation =
      [self expectationWithDescription:@"Callback called with nil error"];
  [_signIn disconnectWithCompletion:^(NSError * _Nullable error) {
    if (error == nil) {
      [noTokensExpectation fulfill];
    }
  }];
  [self waitForExpectations:@[noTokensExpectation] timeout:1];
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
  [_signIn disconnectWithCompletion:nil];
  XCTAssertFalse([self isFetcherStarted], @"should not fetch");
  XCTAssertTrue(_keychainRemoved, @"keychain should be removed");
  [_authorization verify];
  [_authState verify];
  [_tokenResponse verify];
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
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
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
  OCMStub(
    [_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]
  ).andDo(^(NSInvocation *invocation) {
    self->_keychainSaved = self->_saveAuthorizationReturnValue;
  });

  [self OAuthLoginWithAddScopesFlow:NO
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


  [self OAuthLoginWithAddScopesFlow:NO
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
  XCTAssertTrue(_completionCalled, @"should call delegate");
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
  id emmSupport = OCMStrictClassMock([GIDEMMSupport class]);
  [[emmSupport expect] handleTokenFetchEMMError:emmError
                                     completion:SAVE_TO_ARG_BLOCK(completion)];

  [self OAuthLoginWithAddScopesFlow:NO
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

  [emmSupport verify];
  XCTAssertFalse(_keychainSaved, @"should not save to keychain");
  XCTAssertTrue(_completionCalled, @"should call delegate");
  XCTAssertNotNil(_authError, @"should have error");
  XCTAssertEqualObjects(_authError.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(_authError.code, kGIDSignInErrorCodeEMM);
  XCTAssertNil(_signIn.currentUser, @"should not have current user");
}

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

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
  XCTAssertEqualObjects([params valueForKey:kSDKVersionLoggingParameter], GIDVersion(),
                        @"SDK version logging parameter should match");
  XCTAssertEqualObjects([params valueForKey:kEnvironmentLoggingParameter], GIDEnvironment(),
                        @"Environment logging parameter should match");
  // Emulate result back from server.
  [self didFetch:nil error:nil];
  XCTAssertTrue(_keychainRemoved, @"should clear saved keychain name");
  if (hasCallback) {
    [self waitForExpectations:expectations timeout:1];
  }
}

- (void)OAuthLoginWithAddScopesFlow:(BOOL)addScopesFlow
                          authError:(NSString *)authError
                         tokenError:(NSError *)tokenError
            emmPasscodeInfoRequired:(BOOL)emmPasscodeInfoRequired
                      keychainError:(BOOL)keychainError
                     restoredSignIn:(BOOL)restoredSignIn
                     oldAccessToken:(BOOL)oldAccessToken
                        modalCancel:(BOOL)modalCancel {
  [self OAuthLoginWithAddScopesFlow:addScopesFlow
                          authError:authError
                         tokenError:tokenError
            emmPasscodeInfoRequired:emmPasscodeInfoRequired
                      keychainError:keychainError
                     restoredSignIn:restoredSignIn
                     oldAccessToken:oldAccessToken
                        modalCancel:modalCancel
                useAdditionalScopes:NO
                   additionalScopes:nil];
}

// The authorization flow with parameters to control which branches to take.
- (void)OAuthLoginWithAddScopesFlow:(BOOL)addScopesFlow
                          authError:(NSString *)authError
                         tokenError:(NSError *)tokenError
            emmPasscodeInfoRequired:(BOOL)emmPasscodeInfoRequired
                      keychainError:(BOOL)keychainError
                     restoredSignIn:(BOOL)restoredSignIn
                     oldAccessToken:(BOOL)oldAccessToken
                        modalCancel:(BOOL)modalCancel
                useAdditionalScopes:(BOOL)useAdditionalScopes
                   additionalScopes:(NSArray *)additionalScopes {
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
                                   refreshToken:kRefreshToken
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
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      // Corresponds to EMM support
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
      [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
      [[[_authState expect] andReturn:tokenRequest]
          tokenRefreshRequestWithAdditionalParameters:[OCMArg any]];
    }
  } else {
    XCTestExpectation *newAccessTokenExpectation =
        [self expectationWithDescription:@"Callback called"];
    GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                       NSError * _Nullable error) {
      [newAccessTokenExpectation fulfill];
      if (signInResult) {
        XCTAssertEqualObjects(signInResult.serverAuthCode, kServerAuthCode);
      } else {
        XCTAssertNotNil(error, @"Should have an error if the signInResult is nil");
      }
      XCTAssertFalse(self->_completionCalled, @"callback already called");
      self->_completionCalled = YES;
      self->_authError = error;
    };
    if (addScopesFlow) {
      [_signIn addScopes:@[kNewScope]
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
        presentingViewController:_presentingViewController
#elif TARGET_OS_OSX
        presentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
              completion:completion];
    } else {
      if (useAdditionalScopes) {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
        [_signIn signInWithPresentingViewController:_presentingViewController
#elif TARGET_OS_OSX
        [_signIn signInWithPresentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       hint:_hint
                           additionalScopes:additionalScopes
                                 completion:completion];
      } else {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
        [_signIn signInWithPresentingViewController:_presentingViewController
#elif TARGET_OS_OSX
        [_signIn signInWithPresentingWindow:_presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       hint:_hint
                                 completion:completion];
      }
    }

    [_authorization verify];
    [_authState verify];

    XCTAssertNotNil(_savedAuthorizationRequest);
    NSDictionary<NSString *, NSObject *> *params = _savedAuthorizationRequest.additionalParameters;
    XCTAssertEqualObjects(params[@"include_granted_scopes"], @"true");
    XCTAssertEqualObjects(params[kSDKVersionLoggingParameter], GIDVersion());
    XCTAssertEqualObjects(params[kEnvironmentLoggingParameter], GIDEnvironment());
    XCTAssertNotNil(_savedAuthorizationCallback);
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    XCTAssertEqual(_savedPresentingViewController, _presentingViewController);
#elif TARGET_OS_OSX
    XCTAssertEqual(_savedPresentingWindow, _presentingWindow);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

    // maybeFetchToken
    if (!(authError || modalCancel)) {
      [[[_authState expect] andReturn:nil] lastTokenResponse];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      // Corresponds to EMM support
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
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
    XCTestExpectation *callbackShouldBeCalledExpectation =
        [self expectationWithDescription:@"Callback should be called"];
    [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user,
                                                   NSError * _Nullable error) {
      [callbackShouldBeCalledExpectation fulfill];
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
  __block OIDAuthState *authState;
  __block OIDTokenResponse *updatedTokenResponse;
  __block OIDAuthorizationResponse *updatedAuthorizationResponse;
  __block GIDProfileData *profileData;

  if (keychainError) {
    _saveAuthorizationReturnValue = NO;
  } else {
    if (addScopesFlow) {
      [[[_authState expect] andReturn:authResponse] lastAuthorizationResponse];
      [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
      [[_user expect] updateWithTokenResponse:SAVE_TO_ARG_BLOCK(updatedTokenResponse)
                        authorizationResponse:SAVE_TO_ARG_BLOCK(updatedAuthorizationResponse)
                                  profileData:SAVE_TO_ARG_BLOCK(profileData)];
    } else {
      [[[_user expect] andReturn:_user] alloc];
      (void)[[[_user expect] andReturn:_user] initWithAuthState:SAVE_TO_ARG_BLOCK(authState)
                                                    profileData:SAVE_TO_ARG_BLOCK(profileData)];
    }
  }
  
  // CompletionCallback - mock server auth code parsing
  if (!keychainError) {
    [[[_authState expect] andReturn:tokenResponse] lastTokenResponse];
  }

  if (restoredSignIn && !oldAccessToken) {
    XCTestExpectation *restoredSignInExpectation = [self expectationWithDescription:@"Callback should be called"];
    [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user,
                                                   NSError * _Nullable error) {
      [restoredSignInExpectation fulfill];
      XCTAssertNil(error, @"should have no error");
    }];
  } else {
    // Simulate token endpoint response.
    _savedTokenCallback(tokenResponse, nil);
  }

  if (keychainError) {
    return;
  }
  [self waitForExpectationsWithTimeout:1 handler:nil];
  
  [_authState verify];
  
  XCTAssertTrue(_keychainSaved, @"should save to keychain");
  if (addScopesFlow) {
    XCTAssertNotNil(updatedTokenResponse);
    XCTAssertNotNil(updatedAuthorizationResponse);
  } else {
    XCTAssertNotNil(authState);
  }
  // Check fat ID token decoding
  XCTAssertEqualObjects(profileData.name, kFatName);
  XCTAssertEqualObjects(profileData.givenName, kFatGivenName);
  XCTAssertEqualObjects(profileData.familyName, kFatFamilyName);
  XCTAssertTrue(profileData.hasImage);

  // If attempt to authenticate again, will reuse existing auth object.
  _completionCalled = NO;
  _keychainRemoved = NO;
  _keychainSaved = NO;
  _authError = nil;

  __block GIDGoogleUserCompletion completion;
  [[_user expect] refreshTokensIfNeededWithCompletion:SAVE_TO_ARG_BLOCK(completion)];

  XCTestExpectation *restorePreviousSignInExpectation =
      [self expectationWithDescription:@"Callback should be called"];

  [_signIn restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user,
                                                 NSError * _Nullable error) {
    [restorePreviousSignInExpectation fulfill];
    XCTAssertNil(error, @"should have no error");
  }];

  completion(_user, nil);

  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(_keychainRemoved, @"should not remove keychain");
  XCTAssertFalse(_keychainSaved, @"should not save to keychain again");
  
  if (restoredSignIn) {
    // Ignore the return value
    OCMVerify((void)[_keychainStore retrieveAuthSessionWithError:OCMArg.anyObjectRef]);
    OCMVerify([_keychainStore saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef]);
  }
}

@end
