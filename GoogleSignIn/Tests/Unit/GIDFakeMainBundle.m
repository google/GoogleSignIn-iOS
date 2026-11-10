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

#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"

static NSString *const kCFBundleURLTypesKey = @"CFBundleURLTypes";

static NSString *const kCFBundleURLSchemesKey = @"CFBundleURLSchemes";

// Info.plist config keys
static NSString *const kConfigClientIDKey = @"GIDClientID";
static NSString *const kConfigServerClientIDKey = @"GIDServerClientID";
static NSString *const kConfigHostedDomainKey = @"GIDHostedDomain";
static NSString *const kConfigOpenIDRealmKey = @"GIDOpenIDRealm";

@implementation GIDFakeMainBundle {
  NSString *_clientId;
}

- (instancetype)initWithClientID:(NSString *)clientID {
  self = [super initWithBundleIdentifier:nil
                          infoDictionary:@{kConfigClientIDKey : clientID}];
  if (self) {
    _clientId = [clientID copy];
  }
  return self;
}

#pragma mark - Utilities

/**
 * @fn reversedClientId
 * @return The reversed version of _clientID.
 */
- (NSString *)reversedClientId {
  NSArray *clientIdComponents = [_clientId.lowercaseString componentsSeparatedByString:@"."];
  NSArray *reversedClientIdComponents = [clientIdComponents reverseObjectEnumerator].allObjects;
  NSString *reversedClientId = [reversedClientIdComponents componentsJoinedByString:@"."];
  return reversedClientId;
}

/**
 * @fn stringByFlippingCasesInString:
 * @param original The string to flip cases for.
 * @return A string with A-Z replaced by a-z and a-z replaced by A-Z.
 */
- (NSString *)stringByFlippingCasesInString:(NSString *)original {
  const unichar A = 'A';
  const unichar Z = 'Z';
  const unichar a = 'a';
  const unichar z = 'z';
  NSMutableString *flipped = [NSMutableString string];
  for (unsigned int i = 0; i < original.length; i++) {
    unichar c = [original characterAtIndex:i];
    if (A <= c && c <= Z) {
      c += a - A;
    } else if (a <= c && c <= z) {
      c -= a - A;
    }
    [flipped appendString:[NSString stringWithFormat:@"%c", c]];
  }
  return flipped;
}

#pragma mark - URL Schemes

- (void)fakeAllSchemesSupported {
  NSArray<NSDictionary<NSString *, id> *> *urlTypes = @[
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
  [self setObject:urlTypes forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeAllSchemesSupportedAndMerged {
  NSArray<NSDictionary<NSString *, id> *> *urlTypes = @[
    @{
      kCFBundleURLSchemesKey : @[
        [self reversedClientId]
      ]
    },
  ];
  [self setObject:urlTypes forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeAllSchemesSupportedWithCasesMangled {
  NSString *caseFlippedReverseClientId =
      [self stringByFlippingCasesInString:[self reversedClientId]];
  NSArray<NSDictionary<NSString *, id> *> *urlTypes = @[
    @{
      kCFBundleURLSchemesKey : @[ caseFlippedReverseClientId ]
    }
  ];
  [self setObject:urlTypes forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeMissingClientIdScheme {
  [self fakeMissingAllSchemes];
}

- (void)fakeMissingAllSchemes {
  [self setObject:nil forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeOtherSchemes {
  NSArray<NSDictionary<NSString *, id> *> *urlTypes = @[
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    }
  ];
  [self setObject:urlTypes forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeOtherSchemesAndAllSchemes {
  NSArray<NSDictionary<NSString *, id> *> *urlTypes = @[
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    },
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
  [self setObject:urlTypes forInfoDictionaryKey:kCFBundleURLTypesKey];
}

- (void)fakeWithClientID:(id)clientID
          serverClientID:(id)serverClientID
            hostedDomain:(id)hostedDomain
             openIDRealm:(id)openIDRealm {
  [self setObject:clientID forInfoDictionaryKey:kConfigClientIDKey];
  [self setObject:serverClientID forInfoDictionaryKey:kConfigServerClientIDKey];
  [self setObject:hostedDomain forInfoDictionaryKey:kConfigHostedDomainKey];
  [self setObject:openIDRealm forInfoDictionaryKey:kConfigOpenIDRealmKey];
}

@end
