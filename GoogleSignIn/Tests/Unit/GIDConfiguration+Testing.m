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

#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

NSString *const kServerClientID = @"fakeServerClientID";
NSString *const kOpenIDRealm = @"fakeOpenIDRealm";

@implementation GIDConfiguration (Testing)

// TODO(petea): consider moving -isEqual* to the base class and implementing -hash as well.
- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[GIDConfiguration class]]) {
    return NO;
  }
  return [self isEqualToConfiguration:(GIDConfiguration *)object];
}

- (BOOL)isEqualToConfiguration:(GIDConfiguration *)other {
  // Nullable properties get an extra check to cover the nil case.
  return [self.clientID isEqual:other.clientID] &&
      ([self.serverClientID isEqual:other.serverClientID] ||
          self.serverClientID == other.serverClientID) &&
      ([self.hostedDomain isEqual:other.hostedDomain] ||
          self.hostedDomain == other.hostedDomain) &&
      ([self.openIDRealm isEqual:other.openIDRealm] ||
          self.openIDRealm == other.openIDRealm);
}

// Not the hash implemention you want to use on prod, but just to match |isEqual:| here.
- (NSUInteger)hash {
  return [self.clientID hash] ^ [self.serverClientID hash] ^ [self.hostedDomain hash] ^
      [self.openIDRealm hash];
}

+ (instancetype)testInstance {
  return [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                     serverClientID:kServerClientID
                                       hostedDomain:kHostedDomain
                                        openIDRealm:kOpenIDRealm];
}

@end
