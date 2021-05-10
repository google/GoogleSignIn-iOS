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

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDSignInInternalOptions

+ (instancetype)defaultOptions {
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = YES;
    options->_continuation = NO;
  }
  return options;
}

+ (instancetype)silentOptionsWithCallback:(GIDSignInCallback)callback {
  GIDSignInInternalOptions *options = [self defaultOptions];
  if (options) {
    options->_interactive = NO;
    options->_callback = callback;
  }
  return options;
}

+ (instancetype)optionsWithExtraParams:(NSDictionary *)extraParams {
  GIDSignInInternalOptions *options = [self defaultOptions];
  if (options) {
    options->_extraParams = [extraParams copy];
  }
  return options;
}

- (instancetype)optionsWithExtraParameters:(NSDictionary *)extraParams
                           forContinuation:(BOOL)continuation {
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = _interactive;
    options->_continuation = continuation;
    options->_extraParams = [extraParams copy];
  }
  return options;
}

@end

NS_ASSUME_NONNULL_END
