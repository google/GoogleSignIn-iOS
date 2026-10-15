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

#import "GoogleSignIn/Sources/GIDAuthStateMigration/GIDAuthStateMigration.h"

#import "GoogleSignIn/Sources/GIDAuthStateMigration/Implementation/GIDLegacyKeychainImpl.h"
#import "GoogleSignIn/Sources/GIDBundle/Implementation/NSBundle+GIDBundle.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// User preference key to detect whether or not the migration to GTMAppAuth has been performed.
static NSString *const kGTMAppAuthMigrationCheckPerformedKey = @"GID_MigrationCheckPerformed";

// User preference key to detect whether or not the data protected migration has been performed.
static NSString *const kDataProtectedMigrationCheckPerformedKey =
                                                      @"GID_DataProtectedMigrationCheckPerformed";

// Keychain service name used to store the last used fingerprint value.
static NSString *const kFingerprintService = @"fingerprint";

@interface GIDAuthStateMigration ()

@property (nonatomic, strong) GTMKeychainStore *keychainStore;

@end

@implementation GIDAuthStateMigration {
  id<GIDLegacyKeychain> _legacyKeychain;
  // The user defaults in which the migration-check flags are recorded.
  NSUserDefaults *_userDefaults;
  // The bundle whose identifier fingerprints legacy auth state.
  id<GIDBundle> _bundle;
}

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                       legacyKeychain:(id<GIDLegacyKeychain>)legacyKeychain
                         userDefaults:(NSUserDefaults *)userDefaults
                               bundle:(id<GIDBundle>)bundle {
  self = [super init];
  if (self) {
    _keychainStore = keychainStore;
    _legacyKeychain = legacyKeychain;
    _userDefaults = userDefaults;
    _bundle = bundle;
  }
  return self;
}

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                         userDefaults:(NSUserDefaults *)userDefaults
                               bundle:(id<GIDBundle>)bundle {
  return [self initWithKeychainStore:keychainStore
                      legacyKeychain:[[GIDLegacyKeychainImpl alloc] init]
                        userDefaults:userDefaults
                              bundle:bundle];
}

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore {
  return [self initWithKeychainStore:keychainStore
                        userDefaults:[NSUserDefaults standardUserDefaults]
                              bundle:[NSBundle mainBundle]];
}

- (instancetype)init {
  GTMKeychainStore *keychainStore = [[GTMKeychainStore alloc] initWithItemName:@"auth"];
  return [self initWithKeychainStore:keychainStore];
}

- (void)migrateIfNeededWithTokenURL:(NSURL *)tokenURL
                       callbackPath:(NSString *)callbackPath
                     isFreshInstall:(BOOL)isFreshInstall {
  // If this is a fresh install, take no action and mark the migration checks as having been
  // performed.
  if (isFreshInstall) {
#if TARGET_OS_OSX
    [_userDefaults setBool:YES forKey:kDataProtectedMigrationCheckPerformedKey];
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    [_userDefaults setBool:YES forKey:kGTMAppAuthMigrationCheckPerformedKey];
#endif // TARGET_OS_OSX
    return;
  }

#if TARGET_OS_OSX
  [self performDataProtectedMigrationIfNeeded];
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [self performGIDMigrationIfNeededWithTokenURL:tokenURL
                                   callbackPath:callbackPath];
#endif // TARGET_OS_OSX
}

#if TARGET_OS_OSX
// Migrate from the fileBasedKeychain to dataProtectedKeychain with GTMAppAuth 5.0.
- (void)performDataProtectedMigrationIfNeeded {
  // See if we've performed the migration check previously.
  if ([_userDefaults boolForKey:kDataProtectedMigrationCheckPerformedKey]) {
    return;
  }

  GTMKeychainAttribute *fileBasedKeychain = [GTMKeychainAttribute useFileBasedKeychain];
  NSSet *attributes = [NSSet setWithArray:@[fileBasedKeychain]];
  GTMKeychainStore *keychainStoreLegacy =
      [[GTMKeychainStore alloc] initWithItemName:self.keychainStore.itemName
                              keychainAttributes:attributes];
  GTMAuthSession *authSession = [keychainStoreLegacy retrieveAuthSessionWithError:nil];
  // If migration was successful, save our migrated state to the keychain.
  if (authSession) {
    NSError *err;
    [self.keychainStore saveAuthSession:authSession error:&err];
    [keychainStoreLegacy removeAuthSessionWithError:nil];
  }

  // Mark the migration check as having been performed.
  [_userDefaults setBool:YES forKey:kDataProtectedMigrationCheckPerformedKey];
}

#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// Migrate from GPPSignIn 1.x or GIDSignIn 1.0 - 4.x to the GTMAppAuth storage introduced in
// GIDSignIn 5.0.
- (void)performGIDMigrationIfNeededWithTokenURL:(NSURL *)tokenURL
                                   callbackPath:(NSString *)callbackPath {
  // See if we've performed the migration check previously.
  if ([_userDefaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]) {
    return;
  }

  // Attempt migration
  GTMAuthSession *authSession =
      [self extractAuthSessionWithTokenURL:tokenURL callbackPath:callbackPath];

  // If migration was successful, save our migrated state to the keychain.
  if (authSession) {
    NSError *err;
    [self.keychainStore saveAuthSession:authSession error:&err];
  }

  // Mark the migration check as having been performed.
  [_userDefaults setBool:YES forKey:kGTMAppAuthMigrationCheckPerformedKey];
}

// Returns a |GTMAuthSession| object containing any old auth state or |nil| if none
// was found or the migration failed.
- (nullable GTMAuthSession *)extractAuthSessionWithTokenURL:(NSURL *)tokenURL
                                               callbackPath:(NSString *)callbackPath {
  // Retrieve the last used fingerprint.
  NSString *fingerprint = [_legacyKeychain passwordForService:kFingerprintService];
  if (!fingerprint) {
    return nil;
  }

  // Retrieve the GTMOAuth2 persistence string.
  NSError *passwordError;
  NSString *GTMOAuth2PersistenceString =
      [self.keychainStore.keychainHelper passwordForService:fingerprint error:&passwordError];
  if (passwordError) {
    return nil;
  }

  // Parse the fingerprint.
  NSString *bundleID = _bundle.bundleIdentifier;
  NSString *pattern =
      [NSString stringWithFormat:@"^%@-(.+)-(?:email|profile|https:\\/\\/).*$", bundleID];
  NSError *error;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
  NSRange matchRange = NSMakeRange(0, fingerprint.length);
  NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fingerprint
                                                            options:0
                                                              range:matchRange];
  if ([matches count] != 1) {
    return nil;
  }

  // Extract the client ID from the fingerprint.
  NSString *clientID = [fingerprint substringWithRange:[matches[0] rangeAtIndex:1]];

  // Generate the redirect URI from the extracted client ID.
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:clientID bundle:_bundle];
  NSString *scheme = [schemes clientIdentifierScheme];
  NSString *redirectURI = [NSString stringWithFormat:@"%@:%@", scheme, callbackPath];

  // Retrieve the additional token request parameters value.
  NSString *additionalTokenRequestParametersService =
      [NSString stringWithFormat:@"%@~~atrp", fingerprint];
  NSString *additionalTokenRequestParameters =
      [_legacyKeychain passwordForService:additionalTokenRequestParametersService];

  // Generate a persistence string that includes additional token request parameters if present.
  NSString *persistenceString = GTMOAuth2PersistenceString;
  if (additionalTokenRequestParameters) {
    persistenceString = [NSString stringWithFormat:@"%@&%@",
                         GTMOAuth2PersistenceString,
                         additionalTokenRequestParameters];
  }

  // Use |GTMOAuth2Compatibility| to generate a |GTMAuthSession| from the
  // persistence string, redirect URI, client ID, and token endpoint URL.
  GTMAuthSession *authSession =
      [GTMOAuth2Compatibility authSessionForPersistenceString:persistenceString
                                                     tokenURL:tokenURL
                                                  redirectURI:redirectURI
                                                     clientID:clientID
                                                 clientSecret:nil
                                                        error:nil];

  return authSession;
}
#endif // TARGET_OS_OSX

@end

NS_ASSUME_NONNULL_END
