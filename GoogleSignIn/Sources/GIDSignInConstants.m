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

#import "GIDSignInConstants.h"

NSString *const kAuthorizationCodeKeyName = @"code";
NSString *const kOAuth2ErrorKeyName = @"error";
NSString *const kOAuth2AccessDenied = @"access_denied";
NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

NSString *const kUserCanceledError = @"The user canceled the sign-in flow.";

const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;
NSString *const kAudienceParameter = @"audience";
NSString *const kOpenIDRealmParameter = @"openid.realm";

NSString *const kBasicProfileEmailKey = @"email";
NSString *const kBasicProfilePictureKey = @"picture";
NSString *const kBasicProfileNameKey = @"name";
NSString *const kBasicProfileGivenNameKey = @"given_name";
NSString *const kBasicProfileFamilyNameKey = @"family_name";

NSString *const kTokenURLTemplate = @"https://%@/token";
NSString *const kUserInfoURLTemplate = @"https://%@/oauth2/v3/userinfo?access_token=%@";

// TODO: Uncomment this once removed from `GIDSignIn.h`
//NSErrorDomain const kGIDSignInErrorDomain = @"com.google.GIDSignIn";

const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

NSString *const kKeychainError = @"keychain error";
NSString *const kGTMAppAuthKeychainName = @"auth";

@implementation GIDSignInConstants

@end
