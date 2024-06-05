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

/// The URL template for the authorization endpoint.
extern NSString *const kAuthorizationURLTemplate;

/// The URL template for the token endpoint.
extern NSString *const kTokenURLTemplate;

/// Expected path in the URL scheme to be handled.
extern NSString *const kBrowserCallbackPath;

/// The name of the audience parameter for the auth and token exchange endpoints.
extern NSString *const kAudienceParameter;

/// The name of the open ID realm parameter for the auth and token exchange endpoints.
extern NSString *const kOpenIDRealmParameter;

/// The name of the include granted scopes parameter for the auth and token exchange endpoints.
extern NSString *const kIncludeGrantedScopesParameter;

/// The name of the login hint parameter for the auth and token exchange endpoints.
extern NSString *const kLoginHintParameter;

/// The name of the hosted domain parameter for the auth and token exchange endpoints.
extern NSString *const kHostedDomainParameter;

/// The name of the error key that occurred during the authorization or token exchange process.
extern NSString *const kOAuth2ErrorKeyName;

/// The value of the error key when the user cancels the authorization or token exchange process.
extern NSString *const kOAuth2AccessDenied;

/// The name of the key that indicates whether a passocde is required for EMM.
extern NSString *const kEMMPasscodeInfoRequiredKeyName;

/// The error string for user cancelation in the sign-in flow.
extern NSString *const kUserCanceledSignInError;

/// The error string for user cancelation in the verify flow.
extern NSString *const kUserCanceledVerifyError;

/// Minimum time to expiration for a restored access token.
extern const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire;
