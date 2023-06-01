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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
@import FirebaseAppCheck;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

/// Identifier for queue where App Check work is performed.
static NSString *const kGIDAppCheckQueue = @"com.google.googlesignin.appCheckWorkerQueue";

/// A list of potential error codes returned from the Google Sign-In SDK during App Check.
typedef NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDAppCheckErrorCode) {
  /// `GIDAppCheck` has already performed the key generation and attestation steps.
  kGIDAppCheckAlreadyPrepared = 1,
};

@interface GIDAppCheck ()

@property(nonatomic, strong) FIRAppCheck *appCheck;
@property(nonatomic, strong) dispatch_queue_t workerQueue;

@end

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
    _appCheck = [FIRAppCheck appCheck];
    _workerQueue = dispatch_queue_create("com.google.googlesignin.appCheckWorkerQueue", nil);
  }
  return self;
}

- (void)prepareForAppAttestWithCompletion:(void (^)(FIRAppCheckToken * _Nullable,
                                                    NSError * _Nullable))completion {
  dispatch_async(self.workerQueue, ^{
    if (self.isPrepared) {
      NSLog(@"Already prepared for App Attest");
      NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                           code:kGIDAppCheckAlreadyPrepared
                                       userInfo:nil];
      completion(nil, error);
      return;
    }
    [self.appCheck limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                   NSError * _Nullable error) {
      if (token) {
        self->_prepared = YES;
        NSLog(@"Prepared for App Attest with token: %@", token);
        completion(token, nil);
        return;
      }
      if (error) {
        completion(nil, error);
        NSLog(@"Failed to prepare for App Attest: %@", error);
      }
    }];
  });
}

- (void)getLimitedUseTokenWithCompletion:
    (void (^)(FIRAppCheckToken * _Nullable, NSError * _Nullable))completion {
  dispatch_async(self.workerQueue, ^{
    [self.appCheck limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                   NSError * _Nullable error) {
      if (token) {
        self->_prepared = YES;
      }
      completion(token, error);
    }];
  });
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
