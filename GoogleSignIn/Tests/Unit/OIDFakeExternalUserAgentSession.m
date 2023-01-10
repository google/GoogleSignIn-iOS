// Copyright 2023 Google LLC
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

#import "GoogleSignIn/Tests/Unit/OIDFakeExternalUserAgentSession.h"

@implementation OIDFakeExternalUserAgentSession

- (instancetype)init {
  self = [super init];
  if (self) {
    self.resumeExternalUserAgentFlow = YES;
  }
  return self;
}

- (void)cancel {
  // no op.
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL {
  return self.resumeExternalUserAgentFlow;
}

- (void)cancelWithCompletion:(nullable void (^)(void))completion {
  NSAssert(NO, @"Not implemented.");
}


- (void)failExternalUserAgentFlowWithError:(nonnull NSError *)error {
  NSAssert(NO, @"Not implemented.");
}

@end
