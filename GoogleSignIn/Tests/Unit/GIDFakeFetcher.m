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
#ifdef SWIFT_PACKAGE
@import GTMAppAuth;
#else
#import <GTMAppAuth/GTMAuthState.h>
#endif

typedef void (^FetchCompletionHandler)(NSData *, NSError *);

@interface GIDFakeFetcher ()

@property(nonatomic, strong, nullable) NSError *fetcherError;

@end

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (instancetype)initWithRequest:(NSURLRequest *)request
                     authorizer:(id<GTMFetcherAuthorizationProtocol>)authorizer {
#pragma clang diagnostic pop
  self = [self initWithRequest:request];
  if (self) {
    self.authorizer = authorizer;
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
  [self authorizeRequest];
  handler(nil, self.fetcherError);
}

- (void)authorizeRequest {
  NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:self.request.URL];
  [self.authorizer authorizeRequest:mutableRequest completionHandler:^(NSError * _Nullable error) {
    self.fetcherError = error;
  }];
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
