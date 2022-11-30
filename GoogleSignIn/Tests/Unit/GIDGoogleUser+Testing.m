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

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/GIDAuthentication.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDToken.h"

#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"

// Key constants used for encode and decode.
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kAuthentication = @"authentication";

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
  return [self.userID isEqual:other.userID] &&
      [self.profile isEqual:other.profile] &&
      [self.configuration isEqual:other.configuration] &&
      [self.idToken isEqual:other.idToken] &&
      [self.refreshToken isEqual:other.refreshToken] &&
      [self.accessToken isEqual:other.accessToken];
}

// Not the hash implemention you want to use on prod, but just to match |isEqual:| here.
- (NSUInteger)hash {
  return [self.userID hash] ^ [self.configuration hash] ^ [self.profile hash] ^
      [self.idToken hash] ^ [self.refreshToken hash] ^ [self.accessToken hash];
}

@end

@implementation GIDGoogleUserOldFormat {
  GIDAuthentication *_authentication;
  GIDProfileData *_profile;
}

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData {
  self = [super initWithAuthState:authState profileData:profileData];
  if (self) {
    _authentication = [[GIDAuthentication alloc] initWithAuthState:authState];
    _profile = profileData;
  }
  return self;
}

#pragma mark - NSSecureCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:_authentication forKey:kAuthentication];
}

@end
