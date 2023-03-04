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

@class GIDGoogleUser;
@class GTMSessionFetcher;

NS_ASSUME_NONNULL_BEGIN

/// Class used in testing EMM error handling in `GIDEMMSupportTest`.
@interface GIDTestWorker : NSObject

/// Creates an instance with a Google user.
///
/// Ensure that the `GIDGoogleUser` has some way to return an `authorizer` of time `GTMAuthSession`
/// with its delegate set to `GIDEMMSupport`.
- (instancetype)initWithGoogleUser:(nonnull GIDGoogleUser *)googleUser
                           fetcher:(nonnull GTMSessionFetcher *)fetcher;

/// Fails the work encapsulated by this type with the given error.
- (void)failWorkWithCompletion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
