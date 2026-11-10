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

#import "GoogleSignIn/Sources/GIDBundle/API/GIDBundle.h"

NS_ASSUME_NONNULL_BEGIN

/// An in-memory `GIDBundle` for tests. Tests populate it with the Info.plist values and bundle
/// identifier the code under test reads.
@interface GIDFakeBundle : NSObject <GIDBundle>

/// The bundle identifier to report. Defaults to nil.
@property(nonatomic, copy, nullable) NSString *bundleIdentifier;

/// Creates a bundle that reports `bundleIdentifier` and whose Info.plist holds the entries of
/// `infoDictionary`.
- (instancetype)initWithBundleIdentifier:(nullable NSString *)bundleIdentifier
                          infoDictionary:(NSDictionary<NSString *, id> *)infoDictionary
    NS_DESIGNATED_INITIALIZER;

/// Creates a bundle with no identifier and an empty Info.plist.
- (instancetype)init;

/// Sets (or, with nil, removes) the value returned by `-objectForInfoDictionaryKey:` for `key`.
- (void)setObject:(nullable id)object forInfoDictionaryKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
