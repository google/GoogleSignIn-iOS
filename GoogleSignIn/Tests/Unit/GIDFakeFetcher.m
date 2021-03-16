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

#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"

typedef void (^FetchCompletionHandler)(NSData *, NSError *);

@implementation GIDFakeFetcher {
  FetchCompletionHandler _handler;
  NSURL *_requestURL;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
  self = [super initWithRequest:request configuration:nil];
  if (self) {
    _requestURL = [[request URL] copy];
  }
  return self;
}


- (void)beginFetchWithDelegate:(id)delegate didFinishSelector:(SEL)finishedSEL {
  [NSException raise:@"NotImplementedException" format:@"Implement this method if it is used"];
}

- (void)beginFetchWithCompletionHandler:(FetchCompletionHandler)handler {
  if (_handler) {
    [NSException raise:NSInvalidArgumentException format:@"Attempted start fetch again"];
  }
  _handler = [handler copy];
}

- (NSURL *)requestURL {
  return _requestURL;
}

- (void)didFinishWithData:(NSData *)data error:(NSError *)error {
  FetchCompletionHandler handler = _handler;
  _handler = nil;
  handler(data, error);
}

@end
