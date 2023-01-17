/*
 * Copyright 2023 Google LLC
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

@class OIDAuthorizationRequest;
@class GIDSignInInternalOptions;

NS_ASSUME_NONNULL_BEGIN

/// The util class for authorization process.
@interface GIDAuthorizationUtil : NSObject

/// Creates the request to AppAuth to start the authorization flow.
///
/// @param options The `GIDSignInInternalOptions` object to provide serverClientID, hostedDomain,
///     clientID, scopes, loginHint and extraParams.
/// @param emmSupport The EMM support info string.
+ (OIDAuthorizationRequest *)
    authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
                         emmSupport:(nullable NSString *)emmSupport;

/// Unions granted scopes with new scopes or returns an error if the new scopes are the subset of
/// the granted scopes.
///
/// @param scopes The existing scopes.
/// @param newScopes The new scopes to add.
/// @param error The reference to the error.
/// @return The array of all scopes or nil if there is an error.
+ (nullable NSArray<NSString *> *)
    resolvedScopesFromGrantedScoped:(NSArray<NSString *> *)scopes
                      withNewScopes:(NSArray<NSString *> *)newScopes
                              error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
