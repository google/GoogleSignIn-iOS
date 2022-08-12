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

#import <Foundation/Foundation.h>

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^GIDAuthenticationCompletion)(OIDAuthState *_Nullable authState,
                                            NSError *_Nullable error);

// Internal methods for the class that are not part of the public API.
@interface GIDAuthentication : NSObject<GTMAppAuthFetcherAuthorizationTokenRefreshDelegate>

// A representation of the state of the OAuth session for this instance.
@property(nonatomic, readonly) OIDAuthState *authState;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// A string indicating support for Enterprise Mobility Management.
@property(nonatomic, readonly) NSString *emmSupport;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState;

// Gets a new authorizer for `GTLService`, `GTMSessionFetcher`, or `GTMHTTPFetcher`.
- (id<GTMFetcherAuthorizationProtocol>)fetcherAuthorizer;

// Get a OIDAuthState which contains a valid access token and a valid ID token, refreshing it first
// if at least one token has expired or is about to expire.
//
// @param completion A completion block that takes a `OIDAuthState` or an error if the attempt
//     to refresh tokens was unsuccessful.  The block will be called asynchronously on the main
//     queue.
- (void)doWithFreshTokens:(GIDAuthenticationCompletion)completion;

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
