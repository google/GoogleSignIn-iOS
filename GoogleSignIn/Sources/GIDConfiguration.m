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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

// The key for the clientID property to be used with NSSecureCoding.
static NSString *const kClientIDKey = @"clientID";

// The key for the serverClientID property to be used with NSSecureCoding.
static NSString *const kServerClientIDKey = @"serverClientID";

// The key for the hostedDomain property to be used with NSSecureCoding.
static NSString *const kHostedDomainKey = @"hostedDomain";

// The key for the openIDRealm property to be used with NSSecureCoding.
static NSString *const kOpenIDRealmKey = @"openIDRealm";

// Info.plist config keys
static NSString *const kConfigClientIDKey = @"GIDClientID";
static NSString *const kConfigServerClientIDKey = @"GIDServerClientID";
static NSString *const kConfigHostedDomainKey = @"GIDHostedDomain";
static NSString *const kConfigOpenIDRealmKey = @"GIDOpenIDRealm";

NS_ASSUME_NONNULL_BEGIN

@implementation GIDConfiguration

- (instancetype)initWithClientID:(NSString *)clientID {
  return [self initWithClientID:clientID
                 serverClientID:nil
                   hostedDomain:nil
                    openIDRealm:nil];
}

- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID {
  return [self initWithClientID:clientID
                 serverClientID:serverClientID
                   hostedDomain:nil
                    openIDRealm:nil];
}

- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID
                    hostedDomain:(nullable NSString *)hostedDomain
                     openIDRealm:(nullable NSString *)openIDRealm {
  self = [super init];
  if (self) {
    _clientID = [clientID copy];
    _serverClientID = [serverClientID copy];
    _hostedDomain = [hostedDomain copy];
    _openIDRealm = [openIDRealm copy];
  }
  return self;
}

// Try to retrieve a configuration value from an |NSBundle|'s Info.plist for a given key.
+ (nullable NSString *)configValueFromBundle:(NSBundle *)bundle forKey:(NSString *)key {
  NSString *value;
  id configValue = [bundle objectForInfoDictionaryKey:key];
  if ([configValue isKindOfClass:[NSString class]]) {
    value = configValue;
  }
  return value;
}

+ (nullable instancetype)configurationFromBundle:(NSBundle *)bundle {
  // Retrieve any valid config parameters from the bundle's Info.plist.
  NSString *clientID = [self configValueFromBundle:bundle forKey:kConfigClientIDKey];
  NSString *serverClientID = [self configValueFromBundle:bundle
                                                  forKey:kConfigServerClientIDKey];
  NSString *hostedDomain = [self configValueFromBundle:bundle forKey:kConfigHostedDomainKey];
  NSString *openIDRealm = [self configValueFromBundle:bundle forKey:kConfigOpenIDRealmKey];

  // If we have at least a client ID, try to construct a configuration.
  if (clientID) {
    return [[self alloc] initWithClientID:clientID
                           serverClientID:serverClientID
                             hostedDomain:hostedDomain
                              openIDRealm:openIDRealm];
  }

  return nil;
}

// Extend NSObject's default description for easier debugging.
- (NSString *)description {
  return [NSString stringWithFormat:
      @"<%@: %p, clientID: %@, serverClientID: %@, hostedDomain: %@, openIDRealm: %@>",
      NSStringFromClass([self class]),
      self,
      _clientID,
      _serverClientID,
      _hostedDomain,
      _openIDRealm];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  // Instances of this class are immutable so return a reference to the original per NSCopying docs.
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  NSString *clientID = [coder decodeObjectOfClass:[NSString class] forKey:kClientIDKey];
  NSString *serverClientID = [coder decodeObjectOfClass:[NSString class] forKey:kServerClientIDKey];
  NSString *hostedDomain = [coder decodeObjectOfClass:[NSString class] forKey:kHostedDomainKey];
  NSString *openIDRealm = [coder decodeObjectOfClass:[NSString class] forKey:kOpenIDRealmKey];

  // We must have a client ID.
  if (!clientID) {
    return nil;
  }

  return [self initWithClientID:clientID
                 serverClientID:serverClientID
                   hostedDomain:hostedDomain
                    openIDRealm:openIDRealm];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_clientID forKey:kClientIDKey];
  [coder encodeObject:_serverClientID forKey:kServerClientIDKey];
  [coder encodeObject:_hostedDomain forKey:kHostedDomainKey];
  [coder encodeObject:_openIDRealm forKey:kOpenIDRealmKey];
}

@end

NS_ASSUME_NONNULL_END
