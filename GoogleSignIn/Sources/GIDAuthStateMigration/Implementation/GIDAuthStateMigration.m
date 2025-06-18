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

// Keychain account used to store additional state in SDKs previous to v5, including GPPSignIn.
static NSString *const kOldKeychainAccount = @"GooglePlus";

// The value used for the kSecAttrGeneric key by GTMAppAuth and GTMOAuth2.
static NSString *const kGenericAttribute = @"OAuth";

// Keychain service name used to store the last used fingerprint value.
static NSString *const kFingerprintService = @"fingerprint";

@interface GIDAuthStateMigration ()

@property (nonatomic, strong) GTMKeychainStore *keychainStore;

@end

@implementation GIDAuthStateMigration

- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore {
  self = [super init];
  if (self) {
    _keychainStore = keychainStore;
  }
  return self;
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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
#if TARGET_OS_OSX
    [defaults setBool:YES forKey:kDataProtectedMigrationCheckPerformedKey];
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    [defaults setBool:YES forKey:kGTMAppAuthMigrationCheckPerformedKey];
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
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults boolForKey:kDataProtectedMigrationCheckPerformedKey]) {
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
  [defaults setBool:YES forKey:kDataProtectedMigrationCheckPerformedKey];
}

#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// Migrate from GPPSignIn 1.x or GIDSignIn 1.0 - 4.x to the GTMAppAuth storage introduced in
// GIDSignIn 5.0.
- (void)performGIDMigrationIfNeededWithTokenURL:(NSURL *)tokenURL
                                   callbackPath:(NSString *)callbackPath {
  // See if we've performed the migration check previously.
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults boolForKey:kGTMAppAuthMigrationCheckPerformedKey]) {
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
  [defaults setBool:YES forKey:kGTMAppAuthMigrationCheckPerformedKey];
}

// Returns a |GTMAuthSession| object containing any old auth state or |nil| if none
// was found or the migration failed.
- (nullable GTMAuthSession *)extractAuthSessionWithTokenURL:(NSURL *)tokenURL
                                               callbackPath:(NSString *)callbackPath {
  // Retrieve the last used fingerprint.
  NSString *fingerprint = [GIDAuthStateMigration passwordForService:kFingerprintService];
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
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
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
  NSString *scheme =
      [[[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:clientID] clientIdentifierScheme];
  NSString *redirectURI = [NSString stringWithFormat:@"%@:%@", scheme, callbackPath];

  // Retrieve the additional token request parameters value.
  NSString *additionalTokenRequestParametersService =
      [NSString stringWithFormat:@"%@~~atrp", fingerprint];
  NSString *additionalTokenRequestParameters =
      [GIDAuthStateMigration passwordForService:additionalTokenRequestParametersService];

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

// Returns the password string for a given service string stored by an old version of the SDK or
// |nil| if no matching keychain item was found.
+ (nullable NSString *)passwordForService:(NSString *)service {
  if (!service.length) {
    return nil;
  }
  CFDataRef result = NULL;
  NSDictionary<id, id> *query = @{
    (id)kSecClass : (id)kSecClassGenericPassword,
    (id)kSecAttrGeneric : kGenericAttribute,
    (id)kSecAttrAccount : kOldKeychainAccount,
    (id)kSecAttrService : service,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne,
  };
  OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
  NSData *passwordData;
  if (status == noErr && [(__bridge NSData *)result length] > 0) {
    passwordData = [(__bridge NSData *)result copy];
  }
  if (result != NULL) {
    CFRelease(result);
  }
  if (!passwordData) {
    return nil;
  }
  NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
  return password;
}
#endif // TARGET_OS_OSX

@end

NS_ASSUME_NONNULL_END
