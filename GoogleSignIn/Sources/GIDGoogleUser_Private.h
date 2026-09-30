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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

@class GIDToken;
@class OIDAuthState;

NS_ASSUME_NONNULL_BEGIN

/// A completion block that takes a `GIDGoogleUser` or an error if the attempt to refresh tokens was unsuccessful.
typedef void (^GIDGoogleUserCompletion)(GIDGoogleUser *_Nullable user, NSError *_Nullable error);

/// An immutable snapshot of a user's access, refresh and ID tokens.
/// This value is replaced as a whole so that readers never see a mix of old and new tokens.
@interface GIDGoogleUserTokens : NSObject

@property(nonatomic, readonly) GIDToken *accessToken;
@property(nonatomic, readonly) GIDToken *refreshToken;
@property(nonatomic, readonly, nullable) GIDToken *idToken;

- (instancetype)initWithAccessToken:(GIDToken *)accessToken
                       refreshToken:(GIDToken *)refreshToken
                            idToken:(nullable GIDToken *)idToken NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

/// Internal methods for the class that are not part of the public API.
@interface GIDGoogleUser () <OIDAuthStateChangeDelegate>

/// A representation of the state of the OAuth session for this instance.
@property(nonatomic, readonly) OIDAuthState *authState;

/// The user's current tokens. Read once - accessing individual properties in sequence is not
/// recommended. Reading once ensures that each property is from the same update. Writes are
/// serialized by `@synchronized(self)`.
@property(atomic, strong, nullable) GIDGoogleUserTokens *tokens;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property(nonatomic, readwrite) id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer;
#pragma clang diagnostic pop

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// A string indicating support for Enterprise Mobility Management.
@property(nonatomic, readonly, nullable) NSString *emmSupport;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

// Create a object with an auth state, scopes, and profile data.
- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData;

// Update the auth state and profile data.
- (void)updateWithTokenResponse:(OIDTokenResponse *)tokenResponse
          authorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                    profileData:(nullable GIDProfileData *)profileData;

@end

NS_ASSUME_NONNULL_END
