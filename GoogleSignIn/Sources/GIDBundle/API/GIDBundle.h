/*
 * Copyright 2026 Google LLC
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

/// The subset of `NSBundle` that Google Sign-In reads at runtime.
///
/// The SDK depends on this protocol rather than on `NSBundle` directly so that the host app's
/// `Info.plist` can be substituted in tests. `NSBundle` conforms; see `NSBundle+GIDBundle.h`.
@protocol GIDBundle <NSObject>

/// The receiver's bundle identifier, if any.
@property(nonatomic, readonly, copy, nullable) NSString *bundleIdentifier;

/// Returns the value associated with `key` in the receiver's information property list.
- (nullable id)objectForInfoDictionaryKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
