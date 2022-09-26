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
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class OIDAuthState;

// Internal methods for the class that are not part of the public API.
@interface GIDGoogleUser () <GTMAppAuthFetcherAuthorizationTokenRefreshDelegate>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// A string indicating support for Enterprise Mobility Management.
@property(nonatomic, readonly) NSString *emmSupport;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

// Create a object with an auth state, scopes, and profile data.
- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData;

// Update the auth state and profile data.
- (void)updateAuthState:(OIDAuthState *)authState
            profileData:(nullable GIDProfileData *)profileData;

@end

NS_ASSUME_NONNULL_END
