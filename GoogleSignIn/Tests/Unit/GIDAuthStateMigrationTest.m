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

#import "GoogleSignIn/Sources/GIDAuthStateMigration.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import OCMock;
#else
#import <AppAuth/AppAuth.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kTokenURL = @"https://host.com/example/token/url";
static NSString *const kCallbackPath = @"/callback/path";
static NSString *const kKeychainName = @"keychain_name";
static NSString *const kBundleID = @"com.google.GoogleSignInInternalSample.dev";
static NSString *const kClientID =
    @"223520599684-kg64hfn0h950oureqacja2fltg00msv3.apps.googleusercontent.com";
static NSString *const kDotReversedClientID =
    @"com.googleusercontent.apps.223520599684-kg64hfn0h950oureqacja2fltg00msv3";
static NSString *const kSavedFingerprint = @"com.google.GoogleSignInInternalSample.dev-"
    "223520599684-kg64hfn0h950oureqacja2fltg00msv3.apps.googleusercontent.com-email profile";
static NSString *const kSavedFingerprint_HostedDomain =
    @"com.google.GoogleSignInInternalSample.dev-"
    "223520599684-kg64hfn0h950oureqacja2fltg00msv3.apps.googleusercontent.com-email profile-"
    "hd=test.com";
static NSString *const kGTMOAuth2PersistenceString = @"param1=value1&param2=value2";
static NSString *const kAdditionalTokenRequestParametersPostfix = @"~~atrp";
static NSString *const kAdditionalTokenRequestParameters = @"param3=value3&param4=value4";
static NSString *const kFinalPersistenceString =
    @"param1=value1&param2=value2&param3=value3&param4=value4";
static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.223520599684-kg64hfn0h950oureqacja2fltg00msv3:/callback/path";

static NSString *const kMigrationCheckPerformedKey = @"GID_MigrationCheckPerformed";
static NSString *const kFingerprintService = @"fingerprint";

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthStateMigration ()

+ (nullable NSString *)passwordForService:(NSString *)service;

/// Returns a `GTMAuthSession` given the provided token URL.
///
/// This method enables using an instance of `GIDAuthStateMigration` that is created with a fake
/// `GTMKeychainStore` and thereby minimizes mocking.
- (nullable GTMAuthSession *)
    extractAuthSessionWithTokenURL:(NSURL *)tokenURL callbackPath:(NSString *)callbackPath;

@end

@interface GIDAuthStateMigrationTest : XCTestCase
@end

@implementation GIDAuthStateMigrationTest {
  id _mockUserDefaults;
  id _mockGTMAppAuthFetcherAuthorization;
  id _mockGIDAuthStateMigration;
  id _mockGTMKeychainStore;
  id _mockKeychainHelper;
  id _mockNSBundle;
  id _mockGIDSignInCallbackSchemes;
  id _mockGTMOAuth2Compatibility;
}

- (void)setUp {
  [super setUp];

  _mockUserDefaults = OCMClassMock([NSUserDefaults class]);
  _mockGTMAppAuthFetcherAuthorization = OCMStrictClassMock([GTMAuthSession class]);
  _mockGIDAuthStateMigration = OCMStrictClassMock([GIDAuthStateMigration class]);
  _mockGTMKeychainStore = OCMStrictClassMock([GTMKeychainStore class]);
  _mockKeychainHelper = OCMProtocolMock(@protocol(GTMKeychainHelper));
  _mockNSBundle = OCMStrictClassMock([NSBundle class]);
  _mockGIDSignInCallbackSchemes = OCMStrictClassMock([GIDSignInCallbackSchemes class]);
  _mockGTMOAuth2Compatibility = OCMStrictClassMock([GTMOAuth2Compatibility class]);
}

- (void)tearDown {
  [_mockUserDefaults verify];
  [_mockUserDefaults stopMocking];
  [_mockGTMAppAuthFetcherAuthorization verify];
  [_mockGTMAppAuthFetcherAuthorization stopMocking];
  [_mockGIDAuthStateMigration verify];
  [_mockGIDAuthStateMigration stopMocking];
  [_mockGTMKeychainStore verify];
  [_mockGTMKeychainStore stopMocking];
  [_mockKeychainHelper verify];
  [_mockKeychainHelper stopMocking];
  [_mockNSBundle verify];
  [_mockNSBundle stopMocking];
  [_mockGIDSignInCallbackSchemes verify];
  [_mockGIDSignInCallbackSchemes stopMocking];
  [_mockGTMOAuth2Compatibility verify];
  [_mockGTMOAuth2Compatibility stopMocking];

  [super tearDown];
}

#pragma mark - Tests

- (void)testMigrateIfNeeded_NoPreviousMigration {
  [[[_mockUserDefaults stub] andReturn:_mockUserDefaults] standardUserDefaults];
  [[[_mockUserDefaults expect] andReturnValue:@NO] boolForKey:kMigrationCheckPerformedKey];
  [[_mockUserDefaults expect] setBool:YES forKey:kMigrationCheckPerformedKey];

  [[_mockGTMKeychainStore expect] saveAuthSession:OCMOCK_ANY error:OCMArg.anyObjectRef];

  [self setUpCommonExtractAuthorizationMocksWithFingerPrint:kSavedFingerprint];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                            keychainName:kKeychainName
                          isFreshInstall:NO];
}

- (void)testMigrateIfNeeded_HasPreviousMigration {
  [[[_mockUserDefaults stub] andReturn:_mockUserDefaults] standardUserDefaults];
  [[[_mockUserDefaults expect] andReturnValue:@YES] boolForKey:kMigrationCheckPerformedKey];
  [[_mockUserDefaults reject] setBool:YES forKey:kMigrationCheckPerformedKey];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                            keychainName:kKeychainName
                          isFreshInstall:NO];
}

- (void)testMigrateIfNeeded_KeychainFailure {
  [[[_mockUserDefaults stub] andReturn:_mockUserDefaults] standardUserDefaults];
  [[[_mockUserDefaults expect] andReturnValue:@NO] boolForKey:kMigrationCheckPerformedKey];

  NSError *keychainSaveError = [NSError new];
  OCMStub([_mockGTMKeychainStore saveAuthSession:OCMOCK_ANY error:[OCMArg setTo:keychainSaveError]]);

  [self setUpCommonExtractAuthorizationMocksWithFingerPrint:kSavedFingerprint];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                            keychainName:kKeychainName
                          isFreshInstall:NO];
}

- (void)testMigrateIfNeeded_isFreshInstall {
  [[[_mockUserDefaults stub] andReturn:_mockUserDefaults] standardUserDefaults];
  [[[_mockUserDefaults expect] andReturnValue:@NO]
      boolForKey:kMigrationCheckPerformedKey];
  [[_mockUserDefaults expect] setBool:YES forKey:kMigrationCheckPerformedKey];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                            keychainName:kKeychainName
                          isFreshInstall:YES];
}

- (void)testExtractAuthorization {
  [self setUpCommonExtractAuthorizationMocksWithFingerPrint:kSavedFingerprint];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  GTMAuthSession *authorization =
      [migration extractAuthSessionWithTokenURL:[NSURL URLWithString:kTokenURL]
                                   callbackPath:kCallbackPath];

  XCTAssertNotNil(authorization);
}

- (void)testExtractAuthorization_HostedDomain {
  [self setUpCommonExtractAuthorizationMocksWithFingerPrint:kSavedFingerprint_HostedDomain];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_mockGTMKeychainStore];
  GTMAuthSession *authorization =
      [migration extractAuthSessionWithTokenURL:[NSURL URLWithString:kTokenURL]
                                   callbackPath:kCallbackPath];

  XCTAssertNotNil(authorization);
}

#pragma mark - Helpers

// Generate the service name for the stored additional token request parameters string.
- (NSString *)additionalTokenRequestParametersKeyFromFingerprint:(NSString *)fingerprint {
  return [NSString stringWithFormat:@"%@%@", fingerprint, kAdditionalTokenRequestParametersPostfix];
}

- (void)setUpCommonExtractAuthorizationMocksWithFingerPrint:(NSString *)fingerprint {
  [[[_mockGIDAuthStateMigration expect] andReturn:fingerprint]
      passwordForService:kFingerprintService];
  (void)[[[_mockKeychainHelper expect] andReturn:kGTMOAuth2PersistenceString]
      passwordForService:fingerprint error:OCMArg.anyObjectRef];
  [[[_mockGTMKeychainStore expect] andReturn:_mockKeychainHelper] keychainHelper];
  [[[_mockNSBundle expect] andReturn:_mockNSBundle] mainBundle];
  [[[_mockNSBundle expect] andReturn:kBundleID] bundleIdentifier];
  [[[_mockGIDSignInCallbackSchemes expect] andReturn:_mockGIDSignInCallbackSchemes] alloc];
  (void)[[[_mockGIDSignInCallbackSchemes expect] andReturn:_mockGIDSignInCallbackSchemes]
      initWithClientIdentifier:kClientID];
  [[[_mockGIDSignInCallbackSchemes expect] andReturn:kDotReversedClientID] clientIdentifierScheme];
  [[[_mockGIDAuthStateMigration expect] andReturn:kAdditionalTokenRequestParameters]
      passwordForService:[self additionalTokenRequestParametersKeyFromFingerprint:fingerprint]];
}

@end

NS_ASSUME_NONNULL_END
