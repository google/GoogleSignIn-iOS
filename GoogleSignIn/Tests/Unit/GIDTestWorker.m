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

#import "GIDTestWorker.h"
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import "GoogleSignIn/Sources/GIDEMMSupport.h"

@interface GIDTestWorker ()

@property(nonatomic, strong) GTMSessionFetcher *fetcher;

@end

@implementation GIDTestWorker

- (instancetype)initWithFetcher:(nonnull GTMSessionFetcher *)fetcher {
  self = [super init];
  if (self) {
    _fetcher = fetcher;
  }
  return self;
}

- (void)failWorkWithCompletion:(void (^)(NSError *_Nullable))completion {
  [self.fetcher beginFetchWithCompletionHandler:^(NSData * _Nullable data,
                                                  NSError * _Nullable error) {
    completion(error);
  }];
}

@end
