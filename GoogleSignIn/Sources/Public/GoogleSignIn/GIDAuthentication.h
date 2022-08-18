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

// We have to import GTMAppAuth because forward declaring the protocol does
// not generate the `fetcherAuthorizer` method below for Swift.
#ifdef SWIFT_PACKAGE
@import GTMAppAuth;
#else
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#endif

@class GIDAuthentication;

NS_ASSUME_NONNULL_BEGIN

/// A callback block that takes a `GIDAuthentication` or an error if the attempt to refresh tokens
/// was unsuccessful.
typedef void (^GIDAuthenticationAction)(GIDAuthentication *_Nullable authentication,
                                        NSError *_Nullable error);

/// This class represents the OAuth 2.0 entities needed for sign-in.
@interface GIDAuthentication : NSObject <NSSecureCoding>

/// The client ID associated with the authentication.
@property(nonatomic, readonly) NSString *clientID;

/// The OAuth2 access token to access Google services.
@property(nonatomic, readonly) NSString *accessToken;

/// The estimated expiration date of the access token.
@property(nonatomic, readonly) NSDate *accessTokenExpirationDate;

/// The OAuth2 refresh token to exchange for new access tokens.
@property(nonatomic, readonly) NSString *refreshToken;

/// An OpenID Connect ID token that identifies the user. Send this token to your server to
/// authenticate the user there. For more information on this topic, see
/// https://developers.google.com/identity/sign-in/ios/backend-auth
@property(nonatomic, readonly, nullable) NSString *idToken;

/// The estimated expiration date of the ID token.
@property(nonatomic, readonly, nullable) NSDate *idTokenExpirationDate;

/// Gets a new authorizer for `GTLService`, `GTMSessionFetcher`, or `GTMHTTPFetcher`.
///
/// @return A new authorizer
- (id<GTMFetcherAuthorizationProtocol>)fetcherAuthorizer;

/// Get a valid access token and a valid ID token, refreshing them first if they have expired or are
/// about to expire.
///
/// @param action A callback block that takes a `GIDAuthentication` or an error if the attempt to
///     refresh tokens was unsuccessful.  The block will be called asynchronously on the main queue.
- (void)doWithFreshTokens:(GIDAuthenticationAction)action;

@end


NS_ASSUME_NONNULL_END
