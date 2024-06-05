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

#import "GoogleSignIn/Sources/GIDSignInConstants.h"

NSString *const kAuthorizationURLTemplate = @"https://%@/o/oauth2/v2/auth";
NSString *const kTokenURLTemplate = @"https://%@/token";
NSString *const kBrowserCallbackPath = @"/oauth2callback";

NSString *const kAudienceParameter = @"audience";
NSString *const kOpenIDRealmParameter = @"openid.realm";
NSString *const kIncludeGrantedScopesParameter = @"include_granted_scopes";
NSString *const kLoginHintParameter = @"login_hint";
NSString *const kHostedDomainParameter = @"hd";

NSString *const kOAuth2ErrorKeyName = @"error";
NSString *const kOAuth2AccessDenied = @"access_denied";
NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

NSString *const kUserCanceledSignInError = @"The user canceled the sign-in flow.";
NSString *const kUserCanceledVerifyError = @"The user canceled the verification flow.";

const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;
