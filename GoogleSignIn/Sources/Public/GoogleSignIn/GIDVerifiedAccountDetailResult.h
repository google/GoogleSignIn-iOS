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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

#import "GIDVerifiedAccountDetailHandling.h"

NS_ASSUME_NONNULL_BEGIN

@class GIDVerifiableAccountDetail;
@class GIDToken;
@class OIDAuthState;
@class OIDTokenResponse;

/// A helper object that contains the result of a verification flow.
/// This will pass back the necessary tokens to the requesting party.
@interface GIDVerifiedAccountDetailResult : NSObject <GIDVerifiedAccountDetailHandling>

/// The access token object holding the string and expiration.
@property(nonatomic, copy, readonly, nullable) GIDToken *accessToken;
/// The refresh token object holding the string and expiration.
@property(nonatomic, copy, readonly, nullable) GIDToken *refreshToken;
/// A list of verified account details.
@property(nonatomic, copy, readonly) NSArray<GIDVerifiableAccountDetail *>
    *verifiedAccountDetails;
/// The auth state to use to refresh tokens.
@property(nonatomic, readonly) OIDAuthState *verifiedAuthState;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
