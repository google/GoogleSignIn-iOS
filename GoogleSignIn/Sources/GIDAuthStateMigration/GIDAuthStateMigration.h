/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "GoogleSignIn/Sources/GIDBundle/API/GIDBundle.h"

@class GTMKeychainStore;
@class GTMAuthSession;

NS_ASSUME_NONNULL_BEGIN

/// A class providing migration support for auth state saved by older versions of the SDK.
@interface GIDAuthStateMigration : NSObject

/// Creates an instance of this migration type with the keychain storage wrapper it will use, the
/// user defaults in which it records that a migration check has run, and the bundle whose
/// identifier was used to fingerprint legacy auth state.
///
/// `bundle` must report the identifier of the app that wrote the legacy keychain entries, which in
/// production is `NSBundle.mainBundle`. With any other identifier the fingerprint never matches and
/// the migration silently finds nothing.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                         userDefaults:(NSUserDefaults *)userDefaults
                               bundle:(id<GIDBundle>)bundle NS_DESIGNATED_INITIALIZER;

/// Same as above, using `[NSUserDefaults standardUserDefaults]` and `[NSBundle mainBundle]`.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore;

/// Perform necessary migrations from legacy auth state storage to most recent GTMAppAuth version.
- (void)migrateIfNeededWithTokenURL:(NSURL *)tokenURL
                       callbackPath:(NSString *)callbackPath
                     isFreshInstall:(BOOL)isFreshInstall;

@end

NS_ASSUME_NONNULL_END
