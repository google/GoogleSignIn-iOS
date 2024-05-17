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

#import "GoogleSignIn/Sources/GIDCallbackQueue.h"

@class OIDAuthState;
@class GIDProfileData;

/// The callback queue used for authentication flow.
@interface GIDAuthFlow : GIDCallbackQueue

/// A representation of the state of the OAuth session for this instance.
@property(nonatomic, strong, nullable) OIDAuthState *authState;

/// The error thrown from the OAuth session encountered for this instance.
@property(nonatomic, strong, nullable) NSError *error;

@property(nonatomic, copy, nullable) NSString *emmSupport;
@property(nonatomic, nullable) GIDProfileData *profileData;



@end
