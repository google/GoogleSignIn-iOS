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

// Parameters for the auth and token exchange endpoints.
NSString *const kAudienceParameter = @"audience";
// See b/11669751 .
NSString *const kOpenIDRealmParameter = @"openid.realm";
NSString *const kIncludeGrantedScopesParameter = @"include_granted_scopes";
NSString *const kLoginHintParameter = @"login_hint";
NSString *const kHostedDomainParameter = @"hd";
