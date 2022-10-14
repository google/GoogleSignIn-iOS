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

@interface GIDGoogleUser (Testing)

- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToGoogleUser:(GIDGoogleUser *)other;
- (NSUInteger)hash;

@end

// The old format GIDGoogleUser contains a GIDAuthentication.
// Note: remove this class when GIDGoogleUser no longer support old encoding.
@interface GIDGoogleUserOldFormat : GIDGoogleUser

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData;

@end
