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

NS_ASSUME_NONNULL_BEGIN

@protocol GIDDataFetcher <NSObject>

/// Fetches the data from an URL.
///
/// @param URL The endpoint to fetch data.
/// @param comment The comment for logging purpose.
/// @param completion The block that is called on completion asynchronously.
- (void)fetchURL:(NSURL *)URL
     withComment:(NSString *)comment
      completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END