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

#ifdef SWIFT_PACKAGE
@import GTMSessionFetcherCore;
#else
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#endif

// A fake |GTMHTTPFetcherService| for testing.
@interface GIDFakeFetcherService : NSObject<GTMSessionFetcherServiceProtocol>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
/// Creates an instance of this fake with an authorizer.
- (instancetype)initWithAuthorizer:(id<GTMFetcherAuthorizationProtocol>)authorizer;
#pragma clang diagnostic pop

/// Returns the list of |GPPFakeFetcher| objects that have been created.
- (NSArray *)fetchers;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
/// The instance to use for authorizing requeests.
@property (nonatomic, strong) id<GTMFetcherAuthorizationProtocol> authorizer;
#pragma clang diagnostic pop

@end
