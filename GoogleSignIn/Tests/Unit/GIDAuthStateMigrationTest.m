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

#import "GoogleSignIn/Sources/GIDAuthStateMigration/Fake/GIDFakeLegacyKeychain.h"
#import "GoogleSignIn/Sources/GIDAuthStateMigration/GIDAuthStateMigration.h"
#import "GoogleSignIn/Sources/GIDBundle/Fake/GIDFakeBundle.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#if TARGET_OS_OSX
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#endif // TARGET_OS_OSX

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuthTestHelpers;
#else
#import <AppAuth/AppAuth.h>
// GTMKeychainHelperFake is only available through the GTMAppAuthTestHelpers SwiftPM product.
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

static NSString *const kGTMAppAuthMigrationCheckPerformedKey = @"GID_MigrationCheckPerformed";
static NSString *const kDataProtectedMigrationCheckPerformedKey =
                                                      @"GID_DataProtectedMigrationCheckPerformed";
static NSString *const kFingerprintService = @"fingerprint";
static NSString *const kUserDefaultsSuiteName = @"GIDAuthStateMigrationTestSuite";

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthStateMigration ()

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
  // Suite-scoped user defaults injected into the migration under test.
  NSUserDefaults *_userDefaults;
  // Stands in for the pre-5.0 keychain items.
  GIDFakeLegacyKeychain *_legacyKeychain;
  // In-memory keychain backing |_keychainStore|.
  GTMKeychainHelperFake *_keychainHelper;
  // The store the migration writes the migrated session to.
  GTMKeychainStore *_keychainStore;
  // The bundle injected into the migration under test.
  GIDFakeBundle *_bundle;
#if TARGET_OS_OSX
  id _realLegacyGTMKeychainStore;
#endif // TARGET_OS_OSX
}

- (void)setUp {
  [super setUp];

  _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
  [_userDefaults removePersistentDomainForName:kUserDefaultsSuiteName];
  _bundle = [[GIDFakeBundle alloc] initWithBundleIdentifier:kBundleID infoDictionary:@{}];
  _legacyKeychain = [[GIDFakeLegacyKeychain alloc] init];
  _keychainHelper = [[GTMKeychainHelperFake alloc] initWithKeychainAttributes:[NSSet set]];
  _keychainStore = [[GTMKeychainStore alloc] initWithItemName:kKeychainName
                                               keychainHelper:_keychainHelper];
#if TARGET_OS_OSX
  GTMKeychainAttribute *fileBasedKeychain = [GTMKeychainAttribute useFileBasedKeychain];
  NSSet *attributes = [NSSet setWithArray:@[fileBasedKeychain]];
  _realLegacyGTMKeychainStore = [[GTMKeychainStore alloc] initWithItemName:kKeychainName
                                                        keychainAttributes:attributes];
#endif // TARGET_OS_OSX
}

- (void)tearDown {
  [_userDefaults removePersistentDomainForName:kUserDefaultsSuiteName];
#if TARGET_OS_OSX
  [_realLegacyGTMKeychainStore removeAuthSessionWithError:nil];
#endif // TARGET_OS_OSX

  [super tearDown];
}

#pragma mark - Tests

#if TARGET_OS_OSX
- (void)testMigrateIfNeeded_NoPreviousMigration_DataProtectedMigration {
  // set the auth session that will be migrated
  OIDAuthState *authState = [OIDAuthState testInstance];
  GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];
  NSError *err;
  [_realLegacyGTMKeychainStore saveAuthSession:authSession error:&err];
  XCTAssertNil(err);

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:NO];

  XCTAssertNotNil([_keychainStore retrieveAuthSessionWithError:NULL]);
  XCTAssertTrue([_userDefaults boolForKey:kDataProtectedMigrationCheckPerformedKey]);
  // verify that the auth session was removed during migration
  XCTAssertNil([_realLegacyGTMKeychainStore retrieveAuthSessionWithError:nil]);
}

- (void)testMigrateIfNeeded_KeychainFailure_DataProtectedMigration {
  OIDAuthState *authState = [OIDAuthState testInstance];
  GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];
  NSError *err;
  [_realLegacyGTMKeychainStore saveAuthSession:authSession error:&err];
  XCTAssertNil(err);
  NSError *keychainSaveError = [NSError errorWithDomain:@"com.google.GIDAuthStateMigrationTest"
                                                   code:1
                                               userInfo:nil];
  _keychainHelper.setPasswordError = keychainSaveError;

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:NO];
  XCTAssertNil([_keychainStore retrieveAuthSessionWithError:NULL]);
  XCTAssertTrue([_userDefaults boolForKey:kDataProtectedMigrationCheckPerformedKey]);
  XCTAssertNil([_realLegacyGTMKeychainStore retrieveAuthSessionWithError:nil]);
}

#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)testMigrateIfNeeded_NoPreviousMigration_GTMAppAuthMigration {
  [self seedLegacyAuthStateWithFingerprint:kSavedFingerprint];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:NO];

  XCTAssertNotNil([_keychainStore retrieveAuthSessionWithError:NULL]);
  XCTAssertTrue([_userDefaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]);
}

- (void)testMigrateIfNeeded_KeychainFailure_GTMAppAuthMigration {
  [self seedLegacyAuthStateWithFingerprint:kSavedFingerprint];
  NSError *keychainSaveError = [NSError errorWithDomain:@"com.google.GIDAuthStateMigrationTest"
                                                   code:1
                                               userInfo:nil];
  _keychainHelper.setPasswordError = keychainSaveError;

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:NO];

  XCTAssertNil([_keychainStore retrieveAuthSessionWithError:NULL]);
  XCTAssertTrue([_userDefaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]);
}

- (void)testExtractAuthorization {
  [self seedLegacyAuthStateWithFingerprint:kSavedFingerprint];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  GTMAuthSession *authorization =
      [migration extractAuthSessionWithTokenURL:[NSURL URLWithString:kTokenURL]
                                   callbackPath:kCallbackPath];

  XCTAssertNotNil(authorization);
  XCTAssertEqualObjects(
      authorization.authState.lastTokenResponse.request.additionalParameters[@"param3"],
      @"value3");
}

- (void)testExtractAuthorization_HostedDomain {
  [self seedLegacyAuthStateWithFingerprint:kSavedFingerprint_HostedDomain];

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  GTMAuthSession *authorization =
      [migration extractAuthSessionWithTokenURL:[NSURL URLWithString:kTokenURL]
                                   callbackPath:kCallbackPath];

  XCTAssertNotNil(authorization);
  XCTAssertEqualObjects(
      authorization.authState.lastTokenResponse.request.additionalParameters[@"param3"],
      @"value3");
}

- (void)testExtractAuthorization_NoFingerprint {
  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  GTMAuthSession *authorization =
      [migration extractAuthSessionWithTokenURL:[NSURL URLWithString:kTokenURL]
                                   callbackPath:kCallbackPath];

  XCTAssertNil(authorization);
  XCTAssertNil([_keychainStore retrieveAuthSessionWithError:NULL]);
}
#endif // TARGET_OS_OSX

- (void)testMigrateIfNeeded_HasPreviousMigration {
#if TARGET_OS_OSX
  [_userDefaults setBool:YES forKey:kDataProtectedMigrationCheckPerformedKey];
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [_userDefaults setBool:YES forKey:kGTMAppAuthMigrationCheckPerformedKey];
#endif // TARGET_OS_OSX

  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:NO];

#if TARGET_OS_OSX
  XCTAssertTrue([_userDefaults boolForKey:kDataProtectedMigrationCheckPerformedKey]);
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  XCTAssertTrue([_userDefaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]);
#endif // TARGET_OS_OSX
}

- (void)testMigrateIfNeeded_isFreshInstall {
  GIDAuthStateMigration *migration =
      [[GIDAuthStateMigration alloc] initWithKeychainStore:_keychainStore
                                            legacyKeychain:_legacyKeychain
                                              userDefaults:_userDefaults
                                                    bundle:_bundle];
  [migration migrateIfNeededWithTokenURL:[NSURL URLWithString:kTokenURL]
                            callbackPath:kCallbackPath
                          isFreshInstall:YES];

#if TARGET_OS_OSX
  XCTAssertTrue([_userDefaults boolForKey:kDataProtectedMigrationCheckPerformedKey]);
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  XCTAssertTrue([_userDefaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]);
#endif // TARGET_OS_OSX
}



#pragma mark - Helpers

// Generate the service name for the stored additional token request parameters string.
- (NSString *)additionalTokenRequestParametersKeyFromFingerprint:(NSString *)fingerprint {
  return [NSString stringWithFormat:@"%@%@", fingerprint, kAdditionalTokenRequestParametersPostfix];
}

// Seeds the legacy keychain items that a pre-5.0 authorization with `fingerprint` would have
// stored.
- (void)seedLegacyAuthStateWithFingerprint:(NSString *)fingerprint {
  [_legacyKeychain setPassword:fingerprint forService:kFingerprintService];
  XCTAssertTrue([_keychainHelper setPassword:kGTMOAuth2PersistenceString
                                  forService:fingerprint
                                       error:NULL]);
  [_legacyKeychain
      setPassword:kAdditionalTokenRequestParameters
       forService:[self additionalTokenRequestParametersKeyFromFingerprint:fingerprint]];
}

@end

NS_ASSUME_NONNULL_END
