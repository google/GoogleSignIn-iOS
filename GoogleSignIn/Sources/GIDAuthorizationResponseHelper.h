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
  GIDFlowNameVerify = 1,
};

/// A helper class to process the authorization response.
@interface GIDAuthorizationResponseHelper : NSObject

/// The authorization response to process.
@property(nonatomic, readonly) OIDAuthorizationResponse *authorizationResponse;

/// The EMM support version.
@property(nonatomic, readwrite, nullable) NSString *emmSupport;

/// The name of the current flow.
@property(nonatomic, readonly) GIDFlowName flowName;

/// The configuration for the current flow.
@property(nonatomic, readwrite) GIDConfiguration *configuration;

/// Initializes a new instance of the `GIDAuthorizationResponseHelper` class with the provided fields.
///
/// @param authorizationResponse The authorization response to be processed.
/// @param emmSupport The EMM support version.
/// @param flowName The name of the current flow.
/// @param configuration The configuration.
/// @return A new initialized instance of the `GIDAuthorizationResponseHelper` class.
- (instancetype)
    initWithAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                       emmSupport:(nullable NSString *)emmSupport
                         flowName:(GIDFlowName)flowName
                    configuration:(nullable GIDConfiguration *)configuration;

/// Processes the authorization response and returns an auth flow.
///
/// @param error The error thrown if there's no authorization response.
/// @return An instance of `GIDAuthFlow`.
- (GIDAuthFlow *)processWithError:(NSError *)error;

/// Fetches the access token if necessary as part of the auth flow.
///
/// @param authFlow The auth flow to either fetch tokens or error.
- (void)maybeFetchToken:(GIDAuthFlow *)authFlow;

@end

NS_ASSUME_NONNULL_END
