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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <AppCheckCore/GACAppCheck.h>
#import <AppCheckCore/GACAppCheckSettings.h>
#import <AppCheckCore/GACAppCheckToken.h>
#import <AppCheckCore/GACAppAttestProvider.h>

#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAppCheckError.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

NSErrorDomain const kGIDAppCheckErrorDomain = @"com.google.GIDAppCheck";
NSString *const kGIDAppCheckPreparedKey = @"com.google.GIDAppCheckPreparedKey";
static NSString *const kGIDConfigClientIDKey = @"GIDClientID";
static NSString *const kGIDAppAttestServiceName = @"GoogleSignIn-iOS";
static NSString *const kGIDAppAttestResourceNameFormat = @"oauthClients/%@";
static NSString *const kGIDAppAttestBaseURL = @"https://firebaseappcheck.googleapis.com/v1beta";

typedef void (^GIDAppCheckPrepareCompletion)(NSError * _Nullable);
typedef void (^GIDAppCheckTokenCompletion)(id<GACAppCheckTokenProtocol> _Nullable,
                                           NSError * _Nullable);

@interface GIDAppCheck ()

@property(nonatomic, strong) GACAppCheck *appCheck;
@property(nonatomic, strong) dispatch_queue_t workerQueue;
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(atomic, strong) NSMutableArray<GIDAppCheckPrepareCompletion> *prepareCompletions;
@property(atomic) BOOL preparing;

@end

@implementation GIDAppCheck

- (instancetype)init {
  if (self = [super init]) {
    _appCheck = [[GACAppCheck alloc] initWithServiceName:kGIDConfigClientIDKey
                                            resourceName:[GIDAppCheck appAttestResourceName]
                                        appCheckProvider:[GIDAppCheck standardAppCheckProvider]
                                                settings:[[GACAppCheckSettings alloc] init]
                                           tokenDelegate:nil
                                     keychainAccessGroup:nil];

    _userDefaults = [NSUserDefaults standardUserDefaults];
    _workerQueue = dispatch_queue_create("com.google.googlesignin.GIDAppCheckWorkerQueue", nil);
    _prepareCompletions = [NSMutableArray array];
    _preparing = NO;
  }
}

- (instancetype)initWithAppCheckProvider:(id<GACAppCheckProvider>)appCheckProvider
                            userDefaults:(NSUserDefaults *)userDefaults {
  if (self = [super init]) {
    _appCheck = [[GACAppCheck alloc] initWithServiceName:kGIDConfigClientIDKey
                                            resourceName:[GIDAppCheck appAttestResourceName]
                                        appCheckProvider:appCheckProvider
                                                settings:[[GACAppCheckSettings alloc] init]
                                           tokenDelegate:nil
                                     keychainAccessGroup:nil];

    _userDefaults = userDefaults;
    _workerQueue = dispatch_queue_create("com.google.googlesignin.GIDAppCheckWorkerQueue", nil);
    _prepareCompletions = [NSMutableArray array];
    _preparing = NO;
  }
  return self;
}

- (BOOL)isPrepared {
  return [self.userDefaults boolForKey:kGIDAppCheckPreparedKey];
}

- (void)prepareForAppCheckWithCompletion:(nullable GIDAppCheckPrepareCompletion)completion {
  if (completion) {
    @synchronized (self) {
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
    NSArray * __block callbacks;

    if ([self isPrepared]) {
      NSArray *callbacks;
      @synchronized (self) {
        callbacks = [self.prepareCompletions copy];
        [self.prepareCompletions removeAllObjects];
        self.preparing = NO;
      }

      for (GIDAppCheckPrepareCompletion savedCompletion in callbacks) {
        savedCompletion(nil);
      }
      return;
    }

    [self.appCheck getLimitedUseTokenWithCompletion:^(id<GACAppCheckTokenProtocol> _Nullable token,
                                                      NSError * _Nullable error) {
      NSError * __block maybeError = error;
      @synchronized (self) {
        if (!token && !error) {
          maybeError = [NSError errorWithDomain:kGIDAppCheckErrorDomain
                                           code:kGIDAppCheckUnexpectedError
                                       userInfo:nil];
        }

        if (token) {
          [self.userDefaults setBool:YES forKey:kGIDAppCheckPreparedKey];
        }

        callbacks = [self.prepareCompletions copy];
        [self.prepareCompletions removeAllObjects];
        self.preparing = NO;
      }


      for (GIDAppCheckPrepareCompletion savedCompletion in callbacks) {
        savedCompletion(maybeError);
      }
    }];
  });
}

- (void)getLimitedUseTokenWithCompletion:(nullable GIDAppCheckTokenCompletion)completion {
  dispatch_async(self.workerQueue, ^{
    [self.appCheck getLimitedUseTokenWithCompletion:^(id<GACAppCheckTokenProtocol> _Nullable token,
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

+ (NSString *)appAttestResourceName {
  NSString *clientID = [NSBundle.mainBundle objectForInfoDictionaryKey:kGIDConfigClientIDKey];
  return [NSString stringWithFormat:kGIDAppAttestResourceNameFormat, clientID];
}

+ (id<GACAppCheckProvider>)standardAppCheckProvider {
  return [[GACAppAttestProvider alloc] initWithServiceName:kGIDAppAttestServiceName
                                              resourceName:[GIDAppCheck appAttestResourceName]
                                                   baseURL:kGIDAppAttestBaseURL
                                                    APIKey:nil
                                       keychainAccessGroup:nil
                                                limitedUse:YES
                                              requestHooks:nil];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
