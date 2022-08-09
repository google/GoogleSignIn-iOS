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

NS_ASSUME_NONNULL_BEGIN

@class GIDAuthentication;
@class GIDConfiguration;
@class GIDToken;
@class GIDProfileData;

/// This class represents a user account.
@interface GIDGoogleUser : NSObject <NSSecureCoding>

/// The Google user ID.
@property(nonatomic, readonly, nullable) NSString *userID;

/// Representation of basic profile data for the user.
@property(nonatomic, readonly, nullable) GIDProfileData *profile;

/// The authentication object for the user.
@property(nonatomic, readonly) GIDAuthentication *authentication;

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

@end

NS_ASSUME_NONNULL_END
