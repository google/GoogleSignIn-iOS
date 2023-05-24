/*
 * Copyright 2023 Google LLC
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

#import "GoogleSignIn/Sources/GIDAppCheck.h"
@import FirebaseAppCheck;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDAppCheck

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static GIDAppCheck *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] initPrivate];
  });
  return sharedInstance;
}

- (instancetype)initPrivate {
  if (self = [super init]) {
    _prepared = NO;
  }
  return self;
}

- (void)prepareForAppAttest {
  // TODO: Make this threadsafe (mdmathias, 2023.05.23)
  if (self.isPrepared) {
    NSLog(@"Already prepared for App Attest");
    return;
  }

  FIRAppCheck *appCheck = [FIRAppCheck appCheck];
  [appCheck limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                            NSError * _Nullable error) {
    if (token) {
      self->_prepared = YES;
      NSLog(@"Prepared for App Attest with token: %@", token);
      return;
    }
    if (error) {
      NSLog(@"Failed to prepare for App Attest: %@", error);
    }
  }];
}

- (void)getLimitedUseTokenWithCompletion:
    (void (^)(FIRAppCheckToken * _Nullable, NSError * _Nullable))completion {
  FIRAppCheck *appCheck = [FIRAppCheck appCheck];
  [appCheck limitedUseTokenWithCompletion:completion];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
