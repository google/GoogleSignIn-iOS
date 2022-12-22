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

#import "GoogleSignIn/Sources/GIDHTTPFetcher/API/GIDHTTPFetcher.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^GIDHTTPFetcherFakeResponse)(NSData *_Nullable data, NSError *_Nullable error);

typedef void (^GIDHTTPFetcherTestBlock)(GIDHTTPFetcherFakeResponse response);

@interface GIDFakeHTTPFetcher : NSObject <GIDHTTPFetcher>

/// Set the test block which provides the response value.
- (void)setTestBlock:(GIDHTTPFetcherTestBlock)block;

/// The saved url when `fetchURL:withComment:completion:` is invoked.
- (nullable NSURL *)requestURL;

@end

NS_ASSUME_NONNULL_END
