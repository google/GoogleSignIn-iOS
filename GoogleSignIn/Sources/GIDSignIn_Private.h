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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

NS_ASSUME_NONNULL_BEGIN

@class GIDGoogleUser;
@class GIDSignInInternalOptions;

// Private |GIDSignIn| methods that are used internally in this SDK and other Google SDKs.
@interface GIDSignIn ()

// Private initializer for |GIDSignIn|.
- (instancetype)initPrivate;

// Authenticates with extra options.
- (void)signInWithOptions:(GIDSignInInternalOptions *)options;

// Restores a previously authenticated user from the keychain synchronously without refreshing
// the access token or making a userinfo request. The currentUser.profile will be nil unless
// the profile data can be extracted from the ID token.
//
// @return NO if there is no user restored from the keychain.
- (BOOL)restorePreviousSignInNoRefresh;

@end

NS_ASSUME_NONNULL_END
