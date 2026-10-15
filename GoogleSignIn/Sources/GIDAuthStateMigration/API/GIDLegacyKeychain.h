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

/// Reads the keychain items written by Google Sign-In versions before 5.0 (and by GPPSignIn).
@protocol GIDLegacyKeychain <NSObject>

/// Returns the password stored for `service`, or nil if there is none.
- (nullable NSString *)passwordForService:(NSString *)service;

@end

NS_ASSUME_NONNULL_END
