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

NS_ASSUME_NONNULL_BEGIN

@class GIDAuthentication;
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

/// For Google Apps hosted accounts, the domain of the user.
@property(nonatomic, readonly, nullable) NSString *hostedDomain;

/// The client ID of the home server.
@property(nonatomic, readonly, nullable) NSString *serverClientID;

/// An OAuth2 authorization code for the home server.
@property(nonatomic, readonly, nullable) NSString *serverAuthCode;

/// The OpenID2 realm of the home server.
@property(nonatomic, readonly, nullable) NSString *openIDRealm;


@end

NS_ASSUME_NONNULL_END
