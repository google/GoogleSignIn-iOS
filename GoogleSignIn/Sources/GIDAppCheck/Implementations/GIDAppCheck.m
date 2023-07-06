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

#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/GIDAppCheck/API/GIDAppCheckProvider.h"
#import "GoogleSignIn/Sources/GIDAppCheckTokenFetcher/Implementations/FIRAppCheck+GIDAppCheckTokenFetcher.h"

@import FirebaseAppCheck;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

/// Identifier for queue where App Check work is performed.
static NSString *const kGIDAppCheckQueue = @"com.google.googlesignin.appCheckWorkerQueue";

@interface GIDAppCheck ()

@property(nonatomic, strong) id<GIDAppCheckTokenFetcher> tokenFetcher;
@property(nonatomic, strong) dispatch_queue_t workerQueue;
@property(atomic, getter=isPrepared) BOOL prepared;

@end

@implementation GIDAppCheck

- (instancetype)initWithAppCheckTokenFetcher:(nullable id<GIDAppCheckTokenFetcher>)tokenFetcher {
  if (self = [super init]) {
    _prepared = NO;
    _tokenFetcher = tokenFetcher ?: [FIRAppCheck appCheck];
    _workerQueue = dispatch_queue_create("com.google.googlesignin.appCheckWorkerQueue", nil);
  }
  return self;
}

- (void)prepareForAppCheckWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable,
                                                            NSError * _Nullable))completion {
  dispatch_async(self.workerQueue, ^{
    if ([self isPrepared]) {
      NSLog(@"Already prepared for App Attest");
      NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                           code:kGIDAppCheckAlreadyPrepared
                                       userInfo:nil];
      if (completion) {
        completion(nil, error);
      }
      return;
    }
    [self.tokenFetcher limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                       NSError * _Nullable error) {
      if (token) {
        self.prepared = YES;
        NSLog(@"Prepared for App Attest with token: %@", token);
        if (completion) {
          completion(token, nil);
        }
        return;
      }
      if (error) {
        NSLog(@"Failed to prepare for App Attest: %@", error);
        if (completion) {
          completion(nil, error);
        }
        return;
      }
      if (completion) {
        NSError *noError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                               code:kGIDAppCheckUnexpectedError
                                           userInfo:nil];
        completion(nil, noError);
      }
    }];
  });
}

- (void)getLimitedUseTokenWithCompletion:
    (nullable void (^)(FIRAppCheckToken * _Nullable, NSError * _Nullable))completion {
  dispatch_async(self.workerQueue, ^{
    [self.tokenFetcher limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                       NSError * _Nullable error) {
      if (token) {
        self.prepared = YES;
      }
      if (completion) {
        completion(token, error);
      }
    }];
  });
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
