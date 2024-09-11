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

#import "GoogleSignIn/Sources/GIDRestrictedScopesRegistry.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDRestrictedScopesRegistry

- (instancetype)init {
  self = [super init];
  if (self) {
    _restrictedScopes = [NSSet setWithObjects:kAccountDetailTypeAgeOver18Scope, nil];
    _scopeToClassMapping = @{
      kAccountDetailTypeAgeOver18Scope: [GIDVerifyAccountDetail class],
    };
  }
  return self;
}

- (BOOL)isScopeRestricted:(NSString *)scope {
  return [self.restrictedScopes containsObject:scope];
}

- (NSDictionary<NSString *, Class> *)restrictedScopesToClassMappingInSet:(NSSet<NSString *> *)scopes {
  NSMutableDictionary<NSString *, Class> *mapping = [NSMutableDictionary dictionary];
  for (NSString *scope in scopes) {
    if ([self isScopeRestricted:scope]) {
      Class handlingClass = self.scopeToClassMapping[scope];
      mapping[scope] = handlingClass;
    }
  }
  return [mapping copy];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
