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

/// The block which provides the response for the method
/// fetchURLRequest:withAuthorizer:withComment:completion:`.
///
/// @param data The NSData returned if succeed,
/// @param error The error returned if failed.
typedef void(^GIDHTTPFetcherFakeResponseHandlerBlock)(NSData *_Nullable data,
                                                      NSError *_Nullable error);

/// The block to set up data based on the input request for the method
/// fetchURLRequest:withAuthorizer:withComment:completion:`.
///
/// @param request The request from input.
/// @param response The block which handles the response.
typedef void (^GIDHTTPFetcherTestBlock)(NSURLRequest *request,
                                        GIDHTTPFetcherFakeResponseHandlerBlock response);

@interface GIDFakeHTTPFetcher : NSObject <GIDHTTPFetcher>

/// Set the test block which provides the response value.
- (void)setTestBlock:(GIDHTTPFetcherTestBlock)block;

@end

NS_ASSUME_NONNULL_END
