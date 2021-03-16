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

#import <UIKit/UIKit.h>

#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>

static NSString *const kCFBundleURLTypesKey = @"CFBundleURLTypes";

static NSString *const kCFBundleURLSchemesKey = @"CFBundleURLSchemes";

@implementation GIDFakeMainBundle {
  // Represents the CFBundleURLTypes of the mocked app bundle's info.plist.
  __block NSArray *_fakeSupportedSchemes;

  NSString *_clientId;
  NSString *_bundleId;
}

- (void)startFakingWithBundleId:(NSString *)bundleId clientId:(NSString *)clientId {
  _bundleId = bundleId;
  _clientId = clientId;

  [GULSwizzler swizzleClass:[NSBundle class]
                   selector:@selector(objectForInfoDictionaryKey:)
            isClassSelector:NO
                  withBlock:^(id _self, NSString *key) {
    if ([key isEqual:kCFBundleURLTypesKey]) {
      return self->_fakeSupportedSchemes;
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
  _fakeSupportedSchemes = nil;
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
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[ _bundleId ]
    },
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
}

- (void)fakeAllSchemesSupportedAndMerged {
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[
        _bundleId,
        [self reversedClientId]
      ]
    },
  ];
}

- (void)fakeAllSchemesSupportedWithCasesMangled {
  NSString *caseFlippedBundleId =
      [self stringByFlippingCasesInString:_bundleId];
  NSString *caseFlippedReverseClientId =
      [self stringByFlippingCasesInString:[self reversedClientId]];
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[ caseFlippedBundleId ]
    },
    @{
      kCFBundleURLSchemesKey : @[ caseFlippedReverseClientId ]
    }
  ];
}

- (void)fakeMissingClientIdScheme {
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[ _bundleId ]
    }
  ];
}

- (void)fakeMissingAllSchemes {
  _fakeSupportedSchemes = nil;
}

- (void)fakeOtherSchemes {
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    }
  ];
}

- (void)fakeOtherSchemesAndAllSchemes {
  _fakeSupportedSchemes = @[
    @{
      kCFBundleURLSchemesKey : @[ _bundleId ]
    },
    @{
      kCFBundleURLSchemesKey : @[ @"junk" ]
    },
    @{
      kCFBundleURLSchemesKey : @[ [self reversedClientId] ]
    }
  ];
}

@end
