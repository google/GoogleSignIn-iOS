/*
 * Copyright 2025 Google LLC
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

/**
 * A protocol for serializing an `NSDictionary` into a JSON string.
 */
@protocol GIDJSONSerializer <NSObject>

/**
 * Serializes the given dictionary into a `JSON` string.
 *
 * @param jsonObject The dictionary to be serialized.
 * @param error A pointer to an `NSError` object to be populated upon failure.
 * @return A `JSON` string representation of the dictionary, or `nil` if an error occurs.
 */
- (nullable NSString *)stringWithJSONObject:(NSDictionary<NSString *, id> *)jsonObject
                                      error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
