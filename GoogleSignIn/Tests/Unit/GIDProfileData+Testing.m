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

#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"

#import "GoogleSignIn/Sources/GIDProfileData_Private.h"

NSString *const kEmail = @"nobody@gmail.com";
NSString *const kName = @"Nobody Here";
NSString *const kGivenName = @"Nobody";
NSString *const kFamilyName = @"Here";
NSString *const kImageURL = @"http://no.domain/empty";

@implementation GIDProfileData (Testing)

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[GIDProfileData class]]) {
    return NO;
  }
  return [self isEqualToProfileData:(GIDProfileData *)object];
}

- (BOOL)isEqualToProfileData:(GIDProfileData *)other {
  return [self.email isEqual:other.email] &&
      [self.name isEqual:other.name] &&
      [self.givenName isEqual:other.givenName] &&
      [self.familyName isEqual:other.familyName] &&
      // Not something you want to use in production. Should compare _imageURL instead.
      [[self imageURLWithDimension:0].absoluteString isEqual:
          [other imageURLWithDimension:0].absoluteString];
}

// Not the hash implemention you want to use on prod, but just to match |isEqual:| here.
- (NSUInteger)hash {
  return [self.email hash] ^
      [self.name hash] ^
      [self.givenName hash] ^
      [self.familyName hash] ^
      [[self imageURLWithDimension:0] hash];
}

+ (instancetype)testInstance {
  return [self testInstanceWithImageURL:kImageURL];
}

+ (instancetype)testInstanceWithImageURL:(NSString *)imageURL {
  return [[GIDProfileData alloc] initWithEmail:kEmail
                                          name:kName
                                     givenName:kGivenName
                                    familyName:kFamilyName
                                      imageURL:[NSURL URLWithString:imageURL]];
}

@end
