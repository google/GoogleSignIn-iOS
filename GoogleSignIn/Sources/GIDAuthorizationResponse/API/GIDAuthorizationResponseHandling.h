/*
 * Copyright 2024 Google LLC
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

@class GIDAuthFlow;
@class GIDConfiguration;
@class OIDAuthorizationResponse;

NS_ASSUME_NONNULL_BEGIN

/// A list of potential current flow names.
typedef NS_ENUM(NSInteger, GIDFlowName) {
  /// The Sign In flow.
  GIDFlowNameSignIn = 0,
  /// The Verify flow.
  GIDFlowNameVerifyAccountDetail = 1,
};

@protocol GIDAuthorizationResponseHandling

/// Initializes a new instance of the `GIDAuthorizationResponseHandling` class with the provided fields.
///
/// @param authorizationResponse The authorization response to be processed.
/// @param emmSupport The EMM support version.
/// @param flowName The name of the current flow.
/// @param configuration The configuration.
/// @param error The error thrown if there's no authorization response.
/// @return A new initialized instance of the `GIDAuthorizationResponseHandling` class.
- (instancetype)
    initWithAuthorizationResponse:(nullable OIDAuthorizationResponse *)authorizationResponse
                       emmSupport:(nullable NSString *)emmSupport
                         flowName:(enum GIDFlowName)flowName
                    configuration:(nullable GIDConfiguration *)configuration
                            error:(nullable NSError *)error;

/// Fetches the access token if necessary as part of the auth flow.
///
/// @param authFlow The auth flow to either fetch tokens or error.
- (void)maybeFetchToken:(GIDAuthFlow *)authFlow;

/// Processes the authorization response and returns an auth flow.
///
/// @return An instance of `GIDAuthFlow`.
- (GIDAuthFlow *)generateAuthFlowFromAuthorizationResponse;

@end

NS_ASSUME_NONNULL_END
