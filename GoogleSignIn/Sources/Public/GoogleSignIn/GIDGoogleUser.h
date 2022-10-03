/*
 * Copyright 2022 Google LLC
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
// not generate the `fetcherAuthorizer` property below for Swift.
#ifdef SWIFT_PACKAGE
@import GTMAppAuth;
#else
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#endif

@class GIDConfiguration;
@class GIDGoogleUser;
@class GIDToken;
@class GIDProfileData;

NS_ASSUME_NONNULL_BEGIN

/// A completion block that takes a `GIDGoogleUser` or an error if the attempt to refresh tokens was unsuccessful.
typedef void (^GIDGoogleUserCompletion)(GIDGoogleUser *_Nullable user, NSError *_Nullable error);

/// This class represents a user account.
@interface GIDGoogleUser : NSObject <NSSecureCoding>

/// The Google user ID.
@property(nonatomic, readonly, nullable) NSString *userID;

/// Representation of basic profile data for the user.
@property(nonatomic, readonly, nullable) GIDProfileData *profile;

/// The API scopes granted to the app in an array of `NSString`.
@property(nonatomic, readonly, nullable) NSArray<NSString *> *grantedScopes;

/// The configuration that was used to sign in this user.
@property(nonatomic, readonly) GIDConfiguration *configuration;

/// The OAuth2 access token to access Google services.
@property(nonatomic, readonly) GIDToken *accessToken;

/// The OAuth2 refresh token to exchange for new access tokens.
@property(nonatomic, readonly) GIDToken *refreshToken;

/// An OpenID Connect ID token that identifies the user.
///
/// Send this token to your server to authenticate the user there. For more information on this topic,
/// see https://developers.google.com/identity/sign-in/ios/backend-auth.
@property(nonatomic, readonly, nullable) GIDToken *idToken;

/// The authorizer for `GTLService`, `GTMSessionFetcher`, or `GTMHTTPFetcher`.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property(nonatomic, readonly) id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer;
#pragma clang diagnostic pop

/// Get a valid access token and a valid ID token, refreshing them first if they have expired or are about to expire.
///
/// @param completion A completion block that takes a `GIDGoogleUser` or an error if the attempt to refresh tokens was
///     unsuccessful.  The block will be called asynchronously on the main queue.
- (void)doWithFreshTokens:(GIDGoogleUserCompletion)completion;

@end

NS_ASSUME_NONNULL_END
