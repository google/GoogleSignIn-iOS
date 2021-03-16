// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleSignIn/Tests/Unit/GIDAuthentication+Testing.h"

@implementation GIDAuthentication (Testing)

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[GIDAuthentication class]]) {
    return NO;
  }
  return [self isEqualToAuthentication:(GIDAuthentication *)object];
}

- (BOOL)isEqualToAuthentication:(GIDAuthentication *)other {
  return [self.clientID isEqual:other.clientID] &&
      [self.accessToken isEqual:other.accessToken] &&
      [self.accessTokenExpirationDate isEqual:other.accessTokenExpirationDate] &&
      [self.refreshToken isEqual:other.refreshToken] &&
      (self.idToken == other.idToken || [self.idToken isEqual:other.idToken]) &&
      (self.idTokenExpirationDate == other.idTokenExpirationDate ||
          [self.idTokenExpirationDate isEqual:other.idTokenExpirationDate]);
}

// Not the hash implemention you want to use on prod, but just to match |isEqual:| here.
- (NSUInteger)hash {
  return [self.clientID hash] ^ [self.accessToken hash] ^ [self.accessTokenExpirationDate hash] ^
      [self.refreshToken hash] ^ [self.idToken hash] ^ [self.idTokenExpirationDate hash];
}

@end

