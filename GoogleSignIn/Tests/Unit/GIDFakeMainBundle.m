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

#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>

static NSString *const kCFBundleURLTypesKey = @"CFBundleURLTypes";

static NSString *const kCFBundleURLSchemesKey = @"CFBundleURLSchemes";

// Info.plist config keys
static NSString *const kConfigClientIDKey = @"GIDClientID";
static NSString *const kConfigServerClientIDKey = @"GIDServerClientID";
static NSString *const kConfigHostedDomainKey = @"GIDHostedDomain";
static NSString *const kConfigOpenIDRealmKey = @"GIDOpenIDRealm";

@implementation GIDFakeMainBundle {
  NSString *_clientId;

  // Represents the Info.plist keys to fake.
  NSArray *_fakedKeys;

  // Represents the values for any Info.plist keys to be faked.
  NSMutableDictionary *_fakeConfig;
}

- (void)startFakingWithClientID:(NSString *)clientId {
  _clientId = clientId;

  _fakedKeys = @[ kCFBundleURLTypesKey,
                  kConfigClientIDKey,
                  kConfigServerClientIDKey,
                  kConfigHostedDomainKey,
                  kConfigOpenIDRealmKey ];
  
  _fakeConfig = [@{ @"GIDClientID" : clientId } mutableCopy];

  [GULSwizzler swizzleClass:[NSBundle class]
                   selector:@selector(objectForInfoDictionaryKey:)
            isClassSelector:NO
                  withBlock:^id(id _self, NSString *key) {
    if ([self->_fakedKeys containsObject:key]) {
      return self->_fakeConfig[key];
    } else {
      @throw [NSException exceptionWithName:@"Requested unexpected info.plist key."
                                     reason:nil
                                   userInfo:nil];
    }
  }];
}

- (void)stopFaking {
  [GULSwizzler unswizzleClass:[NSBundle class]
                     selector:@selector(objectForInfoDictionaryKey:)
              isClassSelector:NO];
  _fakeConfig = nil;
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
  _fakeConfig[kCFBundleURLTypesKey] = @[
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
}

- (void)fakeAllSchemesSupportedAndMerged {
  _fakeConfig[kCFBundleURLTypesKey] = @[
    @{
      kCFBundleURLSchemesKey : @[
        [self reversedClientId]
      ]
    },
  ];
}

- (void)fakeAllSchemesSupportedWithCasesMangled {
  NSString *caseFlippedReverseClientId =
      [self stringByFlippingCasesInString:[self reversedClientId]];
  _fakeConfig[kCFBundleURLTypesKey] = @[
    @{
      kCFBundleURLSchemesKey : @[ caseFlippedReverseClientId ]
    }
  ];
}

- (void)fakeMissingClientIdScheme {
  [self fakeMissingAllSchemes];
}

- (void)fakeMissingAllSchemes {
  _fakeConfig[kCFBundleURLTypesKey] = nil;
}

- (void)fakeOtherSchemes {
  _fakeConfig[kCFBundleURLTypesKey] = @[
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    }
  ];
}

- (void)fakeOtherSchemesAndAllSchemes {
  _fakeConfig[kCFBundleURLTypesKey] = @[
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    },
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
}

- (void)fakeWithClientID:(id)clientID
          serverClientID:(id)serverClientID
            hostedDomain:(id)hostedDomain
             openIDRealm:(id)openIDRealm {
  _fakeConfig[kConfigClientIDKey] = clientID;
  _fakeConfig[kConfigServerClientIDKey] = serverClientID;
  _fakeConfig[kConfigHostedDomainKey] = hostedDomain;
  _fakeConfig[kConfigOpenIDRealmKey] = openIDRealm;
}

@end
