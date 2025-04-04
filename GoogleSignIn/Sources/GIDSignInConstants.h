/*
 * Copyright 2025 Google LLC
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

#pragma mark - Parameters in the callback URL coming back from browser.
extern NSString *const kAuthorizationCodeKeyName;
extern NSString *const kOAuth2ErrorKeyName;
extern NSString *const kOAuth2AccessDenied;
extern NSString *const kEMMPasscodeInfoRequiredKeyName;

/// Error string for user cancelations.
extern NSString *const kUserCanceledError;

/// Minimum time to expiration for a restored access token.
extern const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire;
/// Parameters for the auth and token exchange endpoints.
extern NSString *const kAudienceParameter;
extern NSString *const kOpenIDRealmParameter;

extern NSString *const kBasicProfileEmailKey;
extern NSString *const kBasicProfilePictureKey;
extern NSString *const kBasicProfileNameKey;
extern NSString *const kBasicProfileGivenNameKey;
extern NSString *const kBasicProfileFamilyNameKey;

extern NSString *const kTokenURLTemplate;
extern NSString *const kUserInfoURLTemplate;
extern const NSTimeInterval kFetcherMaxRetryInterval;
extern NSErrorDomain const kGIDSignInErrorDomain;
extern NSString *const kKeychainError;
extern NSString *const kGTMAppAuthKeychainName;

/// The EMM support version
extern NSString *const kEMMVersion;

/// Browser callback path
extern NSString *const kBrowserCallbackPath;

extern NSString *const kAudienceParameter;
extern NSString *const kOpenIDRealmParameter;
extern NSString *const kIncludeGrantedScopesParameter;
extern NSString *const kLoginHintParameter;
extern NSString *const kHostedDomainParameter;

@interface GIDSignInConstants : NSObject

@end

NS_ASSUME_NONNULL_END
