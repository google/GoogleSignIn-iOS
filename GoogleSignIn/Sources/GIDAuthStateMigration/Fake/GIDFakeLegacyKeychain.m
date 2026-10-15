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

#import "GoogleSignIn/Sources/GIDAuthStateMigration/Fake/GIDFakeLegacyKeychain.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDFakeLegacyKeychain {
  NSMutableDictionary<NSString *, NSString *> *_passwordsByService;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _passwordsByService = [NSMutableDictionary dictionary];
  }
  return self;
}

- (nullable NSString *)passwordForService:(NSString *)service {
  return _passwordsByService[service];
}

- (void)setPassword:(nullable NSString *)password forService:(NSString *)service {
  if (password) {
    _passwordsByService[service] = [password copy];
  } else {
    [_passwordsByService removeObjectForKey:service];
  }
}

@end

NS_ASSUME_NONNULL_END
