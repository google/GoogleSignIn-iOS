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

#import "GoogleSignIn/Sources/GIDProfileDataFetcher/API/GIDProfileDataFetcher.h"

@class GIDProfileData;

NS_ASSUME_NONNULL_BEGIN

/// The block which provides the response for user info request.
///
/// @param profileData The `GIDProfileData` object returned if succeeded.
/// @param error The error returned if failed.
typedef void (^GIDProfileDataFetcherFakeResponseProvider)(GIDProfileData *_Nullable profileData,
                                                          NSError *_Nullable error);

/// The block to set up the response value.
///
/// @param responseProvider The block which provides the response.
typedef void (^GIDProfileDataFetcherTestBlock)(GIDProfileDataFetcherFakeResponseProvider
                                               responseProvider);

@interface GIDFakeProfileDataFetcher : NSObject <GIDProfileDataFetcher>

/// Set the test block which provides the response value.
- (void)setTestBlock:(GIDProfileDataFetcherTestBlock)block;

@end

NS_ASSUME_NONNULL_END
