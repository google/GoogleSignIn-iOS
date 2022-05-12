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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthentication.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Internal methods for the class that are not part of the public API.
@interface GIDAuthentication () <GTMAppAuthFetcherAuthorizationTokenRefreshDelegate>

// A representation of the state of the OAuth session for this instance.
@property(nonatomic, readonly) OIDAuthState *authState;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// A string indicating support for Enterprise Mobility Management.
@property(nonatomic, readonly) NSString *emmSupport;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// Gets a new set of URL parameters that also contains EMM-related URL parameters if needed.
+ (NSDictionary *)parametersWithParameters:(NSDictionary *)parameters
                                emmSupport:(nullable NSString *)emmSupport
                    isPasscodeInfoRequired:(BOOL)isPasscodeInfoRequired;

// Gets a new set of URL parameters that contains updated EMM-related URL parameters if needed.
+ (NSDictionary *)updatedEMMParametersWithParameters:(NSDictionary *)parameters;

// Handles potential EMM error from token fetch response.
+ (void)handleTokenFetchEMMError:(nullable NSError *)error
                      completion:(void (^)(NSError *_Nullable))completion;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@end

NS_ASSUME_NONNULL_END
