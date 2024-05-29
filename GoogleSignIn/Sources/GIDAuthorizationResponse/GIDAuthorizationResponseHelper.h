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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/API/GIDAuthorizationResponseHandling.h"

@class GIDAuthFlow;
@class GIDConfiguration;
@class OIDAuthorizationResponse;

NS_ASSUME_NONNULL_BEGIN

/// A helper class to process the authorization response.
@interface GIDAuthorizationResponseHelper : NSObject

/// The response handler used to process the authorization response.
@property (nonatomic, readonly) id<GIDAuthorizationResponseHandling> responseHandler;

/// Initializes a new instance of the `GIDAuthorizationResponseHelper` class with the provided field.
///
/// @param responseHandler The response handler with the authorization response to process.
/// @return A new initialized instance of the `GIDAuthorizationResponseHelper` class.
- (instancetype)
initWithAuthorizationResponseHandler:(id<GIDAuthorizationResponseHandling>)responseHandler;

/// Fetches the access token if necessary using the response handler as part of the auth flow.
///
/// @param authFlow The auth flow to either fetch tokens or error.
- (void)fetchTokenWithAuthFlow:(GIDAuthFlow *)authFlow;


/// Processes the initialized authorization response and returns a filled `GIDAuthFlow` instance.
///
/// @return An instance of `GIDAuthFlow`  to either fetch tokens or error.
- (GIDAuthFlow *)fetchAuthFlowFromProcessedResponse;

@end

NS_ASSUME_NONNULL_END
