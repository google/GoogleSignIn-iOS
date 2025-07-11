// Copyright 2024 Google LLC
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

#import <XCTest/XCTest.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/GIDRestrictedScopesRegistry.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

@interface GIDRestrictedScopesRegistryTest : XCTestCase
@end

@implementation GIDRestrictedScopesRegistryTest

- (void)testIsScopeRestricted {
  GIDRestrictedScopesRegistry *registry = [[GIDRestrictedScopesRegistry alloc] init];
  BOOL isRestricted = [registry isScopeRestricted:@"some_scope"];
  XCTAssertFalse(isRestricted);
}

- (void)testRestrictedScopesToClassMappingInSet {
  GIDRestrictedScopesRegistry *registry = [[GIDRestrictedScopesRegistry alloc] init];
  NSSet<NSString *> *scopes = [NSSet setWithObjects:@"some_scope", @"some_other_scope", nil];
  NSDictionary<NSString *, Class> *mapping = [registry restrictedScopesToClassMappingInSet:scopes];
  
  XCTAssertEqual(mapping.count, 0);
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
