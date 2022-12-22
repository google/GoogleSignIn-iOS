/*
 * Copyright 2022 Google LLC
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

typedef void (^GIDProfileDataFetcherFakeResponse)(GIDProfileData *_Nullable profileData,
                                                  NSError *_Nullable error);

typedef void (^GIDProfileDataFetcherTestBlock)(GIDProfileDataFetcherFakeResponse response);

@interface GIDFakeProfileDataFetcher : NSObject <GIDProfileDataFetcher>

/// Set the test block which provides the response value.
- (void)setTestBlock:(GIDProfileDataFetcherTestBlock)block;

@end

NS_ASSUME_NONNULL_END

