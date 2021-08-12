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

#import "GoogleSignIn/Sources/GIDScopes.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDSignInInternalOptions

+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:
                           (nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                       callback:(GIDSignInCallback)callback {
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = YES;
    options->_continuation = NO;
    options->_configuration = configuration;
    options->_presentingViewController = presentingViewController;
    options->_loginHint = loginHint;
    options->_callback = callback;
    options->_scopes = [GIDScopes scopesWithBasicProfile:@[]];
  }
  return options;
}

+ (instancetype)silentOptionsWithCallback:(GIDSignInCallback)callback {
  GIDSignInInternalOptions *options = [self defaultOptionsWithConfiguration:nil
                                                   presentingViewController:nil
                                                                  loginHint:nil
                                                                   callback:callback];
  if (options) {
    options->_interactive = NO;
  }
  return options;
}

- (instancetype)optionsWithExtraParameters:(NSDictionary *)extraParams
                           forContinuation:(BOOL)continuation {
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = _interactive;
    options->_continuation = continuation;
    options->_configuration = _configuration;
    options->_presentingViewController = _presentingViewController;
    options->_loginHint = _loginHint;
    options->_callback = _callback;
    options->_scopes = _scopes;
    options->_extraParams = [extraParams copy];
  }
  return options;
}

@end

NS_ASSUME_NONNULL_END
