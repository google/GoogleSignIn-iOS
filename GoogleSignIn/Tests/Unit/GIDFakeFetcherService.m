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

#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"

#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"

@implementation GIDFakeFetcherService {
  NSMutableArray *_fetchers;
}

@synthesize delegateQueue;
@synthesize callbackQueue;
@synthesize reuseSession;

- (instancetype)init {
  self = [super init];
  if (self) {
    _fetchers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (BOOL)fetcherShouldBeginFetching:(GTMSessionFetcher *)fetcher {
  return YES;
}

- (void)fetcherDidCreateSession:(GTMSessionFetcher *)fetcher {
}

- (void)fetcherDidBeginFetching:(GTMSessionFetcher *)fetcher {
}

- (void)fetcherDidStop:(GTMSessionFetcher *)fetcher {
}

- (BOOL)isDelayingFetcher:(GTMSessionFetcher *)fetcher {
  return NO;
}

- (GTMSessionFetcher *)fetcherWithRequest:(NSURLRequest *)request {
  GIDFakeFetcher *fetcher = [[GIDFakeFetcher alloc] initWithRequest:request];
  [_fetchers addObject:fetcher];
  return fetcher;
}

- (NSURLSession *)session {
  return nil;
}

- (NSURLSession *)sessionForFetcherCreation {
  return nil;
}

- (id<NSURLSessionDelegate>)sessionDelegate {
  return nil;
}

- (NSArray *)fetchers {
  return _fetchers;
}

- (NSDate *)stoppedAllFetchersDate {
  return nil;
}

@end
