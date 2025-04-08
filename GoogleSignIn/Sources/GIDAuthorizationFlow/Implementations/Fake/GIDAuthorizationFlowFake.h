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
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/API/GIDAuthorizationFlowCoordinator.h"

@class GIDConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthorizationFlowFake : NSObject <GIDAuthorizationFlowCoordinator>

@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GIDProfileData *profileData;
@property(nonatomic, strong, nullable) GIDSignInInternalOptions *options;
@property(nonatomic, strong, nullable) GIDGoogleUser *googleUser;
@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentUserAgentSession;
@property(nonatomic, copy, nullable) NSString *emmSupport;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, strong, nullable) GIDConfiguration *configuration;
@property(nonatomic, strong, nullable) OIDServiceConfiguration *serviceConfiguration;

@end

NS_ASSUME_NONNULL_END
