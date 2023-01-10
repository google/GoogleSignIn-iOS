/*
 * Copyright 2023 Google LLC
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

@class OIDAuthState;
@class OIDIDToken;
@class GIDProfileData;

NS_ASSUME_NONNULL_BEGIN

@protocol GIDProfileDataFetcher <NSObject>

/// Fetches the latest `GIDProfileData` object.
///
/// This method either extracts profile data from `OIDIDToken` in `OIDAuthState` or fetches it
/// from the UserInfo endpoint.
///
/// @param authState The state of the current OAuth session.
/// @param completion The block that is called on completion asynchronously.
- (void)fetchProfileDataWithAuthState:(OIDAuthState *)authState
                           completion:(void (^)(GIDProfileData *_Nullable profileData,
                                                NSError *_Nullable error))completion;

/// Fetches a `GIDProfileData` object from an ID token.
///
/// This method returns  a `GIDProfileData` object if the ID token is a fat one. Otherwise, returns
/// nil.
///
/// @param idToken The ID token.
- (nullable GIDProfileData *)fetchProfileDataWithIDToken:(OIDIDToken *)idToken;

@end

NS_ASSUME_NONNULL_END
