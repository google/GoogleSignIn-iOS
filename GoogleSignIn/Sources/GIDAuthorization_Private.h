/*
 * Copyright 2025 Google LLC
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
#import <TargetConditionals.h>
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthorization.h"

@class GIDConfiguration;
@class GTMKeychainStore;
@class GIDSignInInternalOptions;
@class GIDAuthorizationFlow;
@protocol GIDAuthorizationFlowCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthorization ()

/// Private initializer taking a `GTMKeychainStore`.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore;

/// Private initializer taking a `GTMKeychainStore` and a `GIDConfiguration`.
///
/// If `keychainStore` or `configuration` are nil, then a default is generated.
- (instancetype)initWithKeychainStore:(nullable GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration;

/// Private initializer taking a `GTMKeychainStore`, `GIDConfiguration` and a `GIDAuthorizationFlowCoordinator`.
///
/// If `keychainStore` or `configuration` are nil, then a default is generated. If a nil
/// `GIDAuthorizationFlowCoordinator` conforming instance is provided, then one will be created during the authorization flow.
- (instancetype)initWithKeychainStore:(nullable GTMKeychainStore *)keychainStore
                        configuration:(nullable GIDConfiguration *)configuration
         authorizationFlowCoordinator:(nullable id<GIDAuthorizationFlowCoordinator>)authFlow;

//#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// /// Private initializer taking a `GTMKeychainStore` and `GIDAppCheckProvider`.
//- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
//                             appCheck:(GIDAppCheck *)appCheck
//API_AVAILABLE(ios(14));
//#endif // TARGET_OS_IOS || !TARGET_OS_MACCATALYST

/// Authenticates in with the provided options.
- (void)signInWithOptions:(GIDSignInInternalOptions *)options;

/// Asserts that the current `GIDConfiguration` contains a a client ID.
///
/// Throws an exception if no client ID is found in the configuration.
- (void)assertValidParameters;

/// Asserts that the current `GIDSignInInternalOptions` has a valid presenting controller.
///
/// Throws an exception if the current options do not contain a presenting controller.
- (void)assertValidPresentingController;

/// The current configuration used for authorization.
@property(nonatomic, nullable) GIDConfiguration *currentConfiguration;

/// Keychain manager for GTMAppAuth
@property(nonatomic, readwrite) GTMKeychainStore *keychainStore;

/// Options used when sign-in flows are resumed via the handling of a URL.
///
/// Options are set when a sign-in flow is begun via `signInWithOptions:` when the options passed don't represent a sign in
/// continuation.
@property(nonatomic, nullable) GIDSignInInternalOptions *currentOptions;

/// The `GIDAuthorizationFlowCoordinator` conforming type managing the authorization flow.
@property(nonatomic, readwrite) id<GIDAuthorizationFlowCoordinator> authFlow;

@end

NS_ASSUME_NONNULL_END
