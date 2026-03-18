/*
 * Copyright 2025 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDClaim.h"

NSString * const kAuthTimeClaimName = @"auth_time";

// Private interface to declare the internal initializer
@interface GIDClaim ()

- (instancetype)initWithName:(NSString *)name
                   essential:(BOOL)essential NS_DESIGNATED_INITIALIZER;

@end

@implementation GIDClaim

// Private designated initializer
- (instancetype)initWithName:(NSString *)name essential:(BOOL)essential {
  self = [super init];
  if (self) {
    _name = [name copy];
    _essential = essential;
  }
  return self;
}

#pragma mark - Factory Methods

+ (instancetype)authTimeClaim {
  return [[self alloc] initWithName:kAuthTimeClaimName essential:NO];
}

+ (instancetype)essentialAuthTimeClaim {
  return [[self alloc] initWithName:kAuthTimeClaimName essential:YES];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  // 1. Check if the other object is the same instance in memory.
  if (self == object) {
    return YES;
  }

  // 2. Check if the other object is not a GIDTokenClaim instance.
  if (![object isKindOfClass:[GIDClaim class]]) {
    return NO;
  }

  // 3. Compare the properties that define equality.
  GIDClaim *other = (GIDClaim *)object;
  return [self.name isEqualToString:other.name] &&
         self.isEssential == other.isEssential;
}

- (NSUInteger)hash {
  // The hash value should be based on the same properties used in isEqual:
  return self.name.hash ^ @(self.isEssential).hash;
}

@end
