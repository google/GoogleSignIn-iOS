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

#import "GoogleSignIn/Tests/Unit/GIDFakeSignIn.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"

#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>

static NSString * const kClientId = @"FakeClientID";
static NSString * const kScope = @"FakeScope";

@implementation GIDFakeSignIn

- (instancetype) init {
  self = [super initPrivate];
  if (self) {
    self.clientID = kClientId;
    self.scopes = [NSArray arrayWithObject:kScope];
  }
  return self;
}

- (void)startMocking {
  __weak id weakSelf = self;
  [GULSwizzler swizzleClass:[GIDSignIn class]
                   selector:@selector(sharedInstance)
            isClassSelector:YES
                  withBlock:^{ return weakSelf; }];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)stopMocking {
  [GULSwizzler unswizzleClass:[GIDSignIn class]
                     selector:@selector(sharedInstance)
              isClassSelector:YES];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
}

@end
