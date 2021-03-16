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

#import "GoogleSignIn/Tests/Unit/GIDGoogleUser+Testing.h"

#import "GoogleSignIn/Tests/Unit/GIDAuthentication+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"

@implementation GIDGoogleUser (Testing)

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[GIDGoogleUser class]]) {
    return NO;
  }
  return [self isEqualToGoogleUser:(GIDGoogleUser *)object];
}

- (BOOL)isEqualToGoogleUser:(GIDGoogleUser *)other {
  return [self.authentication isEqual:other.authentication] &&
      [self.userID isEqual:other.userID] &&
      [self.serverAuthCode isEqual:other.serverAuthCode] &&
      [self.profile isEqual:other.profile] &&
      [self.hostedDomain isEqual:other.hostedDomain];
}

// Not the hash implemention you want to use on prod, but just to match |isEqual:| here.
- (NSUInteger)hash {
  return [self.authentication hash] ^ [self.userID hash] ^ [self.serverAuthCode hash] ^
      [self.profile hash] ^ [self.hostedDomain hash];
}

@end
