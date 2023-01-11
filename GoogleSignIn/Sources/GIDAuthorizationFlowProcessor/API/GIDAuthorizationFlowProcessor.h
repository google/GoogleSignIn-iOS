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

@class GIDSignInInternalOptions;
@class OIDAuthorizationResponse;

NS_ASSUME_NONNULL_BEGIN

/// The protocol to control the authorization flow.
@protocol GIDAuthorizationFlowProcessor <NSObject>

/// The state of the authorization flow.
@property(nonatomic, readonly, getter=isStarted) BOOL start;

/// Starts the authorization flow.
///
/// This method sends authorization request to AppAuth `OIDAuthorizationService` and gets back the
/// response or an error.
///
/// @param options The `GIDSignInInternalOptions` object to provide serverClientID, hostedDomain,
///     clientID, scopes, loginHint and extraParams.
/// @param emmSupport The EMM support info string.
/// @param completion The block that is called on completion asynchronously.
///      authorizationResponse The response from `OIDAuthorizationService`.
///      error The error from `OIDAuthorizationService`.
- (void)startWithOptions:(GIDSignInInternalOptions *)options
              emmSupport:(nullable NSString *)emmSupport
              completion:(void (^)(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                   NSError *_Nullable error))completion;

/// Handles the custom URL scheme opened by SFSafariViewController and returns control to the
/// client on iOS 10.
///
/// @param url The redirect URL invoked by the server.
/// @return YES if the passed URL matches the expected redirect URL and was consumed, NO otherwise.
- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)url;

/// Cancels the authorization flow.
- (void)cancelAuthenticationFlow;

@end

NS_ASSUME_NONNULL_END
