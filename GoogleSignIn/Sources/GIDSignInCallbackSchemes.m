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

#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

#import "GoogleSignIn/Sources/GIDBundle/Implementation/NSBundle+GIDBundle.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDSignInCallbackSchemes {
  NSString *_clientIdentifier;
  // The bundle whose Info.plist declares the host app's URL schemes.
  id<GIDBundle> _bundle;
}

/**
 * @fn relevantURLSchemesInBundle:
 * @brief Extracts CFBundleURLSchemes from a bundle's Info.plist.
 * @param bundle The bundle whose Info.plist declares the URL schemes.
 * @return An array of lowercase NSString *'s representing the URL schemes the bundle has declared
 *     support for.
 * @remarks Branched from google3/googlemac/iPhone/Firebase/Source/GGLBundleUtil.m
 */
+ (NSArray<NSString *> *)relevantURLSchemesInBundle:(id<GIDBundle>)bundle {
  NSMutableArray<NSString *> *result = [NSMutableArray array];
  NSArray<NSDictionary<NSString *, id> *> *urlTypes =
      [bundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  for (NSDictionary *urlType in urlTypes) {
    NSArray *urlTypeSchemes = urlType[@"CFBundleURLSchemes"];
    for (NSString *urlTypeScheme in urlTypeSchemes) {
      [result addObject:urlTypeScheme.lowercaseString];
    }
  }
  return result;
}

- (instancetype)initWithClientIdentifier:(NSString *)clientIdentifier
                                  bundle:(id<GIDBundle>)bundle {
  self = [super init];
  if (self) {
    _clientIdentifier = [clientIdentifier copy];
    _bundle = bundle;
  }
  return self;
}

- (instancetype)initWithClientIdentifier:(NSString *)clientIdentifier {
  return [self initWithClientIdentifier:clientIdentifier bundle:[NSBundle mainBundle]];
}

- (NSString *)clientIdentifierScheme {
  NSArray *clientIdentifierParts = [_clientIdentifier componentsSeparatedByString:@"."];
  NSString *reversedClientIdentifier =
      [[clientIdentifierParts reverseObjectEnumerator].allObjects componentsJoinedByString:@"."];
  return reversedClientIdentifier.lowercaseString;
}

- (NSArray<NSString *> *)allSchemes {
  NSMutableArray<NSString *> *schemes = [NSMutableArray array];
  NSString *clientIdentifierScheme = [self clientIdentifierScheme];
  if (clientIdentifierScheme) {
    [schemes addObject:clientIdentifierScheme];
  }
  return schemes;
}

- (NSMutableArray<NSString *> *)unsupportedSchemes {
  NSMutableArray *unsupportedSchemes = [NSMutableArray arrayWithArray:[self allSchemes]];
  NSArray<NSString *> *supportedSchemes = [[self class] relevantURLSchemesInBundle:_bundle];
  [unsupportedSchemes removeObjectsInArray:supportedSchemes];
  return unsupportedSchemes;
}

- (BOOL)URLSchemeIsCallbackScheme:(NSURL *)URL {
  NSString *incomingURLScheme = URL.scheme.lowercaseString;
  for (NSString *scheme in [self allSchemes]) {
    if ([incomingURLScheme isEqual:scheme]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
