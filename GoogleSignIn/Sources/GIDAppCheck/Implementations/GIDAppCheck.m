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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAppCheckError.h"

@import FirebaseAppCheck;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NSErrorDomain const kGIDAppCheckErrorDomain = @"com.google.GIDAppCheck";
NSString *const kGIDAppCheckPreparedKey = @"com.google.GIDAppCheckPreparedKey";

typedef void (^GIDAppCheckCompletion)(FIRAppCheckToken * _Nullable,NSError * _Nullable);

@interface GIDAppCheck ()

@property(nonatomic, strong) id<GIDAppCheckTokenFetcher> tokenFetcher;
@property(nonatomic, strong) dispatch_queue_t workerQueue;
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(atomic, strong) NSMutableArray<GIDAppCheckCompletion> *prepareCompletions;
@property(atomic) BOOL preparing;

@end

@implementation GIDAppCheck

- (instancetype)initWithAppCheckTokenFetcher:(nullable id<GIDAppCheckTokenFetcher>)tokenFetcher
                                userDefaults:(nullable NSUserDefaults *)userDefaults {
  if (self = [super init]) {
    _tokenFetcher = tokenFetcher ?: [FIRAppCheck appCheck];
    _userDefaults = userDefaults ?: [NSUserDefaults standardUserDefaults];
    _workerQueue = dispatch_queue_create("com.google.googlesignin.GIDAppCheckWorkerQueue", nil);
    _prepareCompletions = [NSMutableArray array];
    _preparing = NO;
  }
  return self;
}

- (BOOL)isPrepared {
  return [self.userDefaults boolForKey:kGIDAppCheckPreparedKey];
}

- (void)prepareForAppCheckWithCompletion:(nullable GIDAppCheckCompletion)completion {
  if (completion) {
    @synchronized (self.prepareCompletions) {
      [self.prepareCompletions addObject:completion];
    }
  }

  @synchronized (self) {
    if (self.preparing) {
      return;
    }

    self.preparing = YES;
  }

  dispatch_async(self.workerQueue, ^{
    if ([self isPrepared]) {
      NSError *error = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                           code:kGIDAppCheckAlreadyPrepared
                                       userInfo:nil];
      @synchronized (self) {
        for (GIDAppCheckCompletion savedCompletion in self.prepareCompletions) {
          savedCompletion(nil, error);
        }

        [self.prepareCompletions removeAllObjects];
        self.preparing = NO;

        return;
      }
    }

    [self.tokenFetcher limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                       NSError * _Nullable error) {
      @synchronized (self) {
        NSError *maybeError = error;
        if (!token && !maybeError) {
          maybeError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                           code:kGIDAppCheckUnexpectedError
                                       userInfo:nil];
        }

        if (!maybeError) {
          [self.userDefaults setBool:YES forKey:kGIDAppCheckPreparedKey];
        }

        for (GIDAppCheckCompletion savedCompletion in self.prepareCompletions) {
          savedCompletion(token, maybeError);
        }

        [self.prepareCompletions removeAllObjects];
        self.preparing = NO;
      }
    }];
  });
}

- (void)getLimitedUseTokenWithCompletion:(nullable GIDAppCheckCompletion)completion {
  dispatch_async(self.workerQueue, ^{
    [self.tokenFetcher limitedUseTokenWithCompletion:^(FIRAppCheckToken * _Nullable token,
                                                       NSError * _Nullable error) {
      if (token) {
        [self.userDefaults setBool:YES forKey:kGIDAppCheckPreparedKey];
      }
      if (completion) {
        completion(token, error);
      }
    }];
  });
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
