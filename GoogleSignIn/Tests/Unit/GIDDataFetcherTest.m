// Copyright 2022 Google LLC
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

#import "GoogleSignIn/Sources/GIDDataFetcher/Implementations/GIDDataFetcher.h"

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import OCMock;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kTestURL = @"testURL.com";
static NSString * const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 212;

@interface GIDDataFetcherTest : XCTestCase {
  GIDDataFetcher *_dataFetcher;
  
  // Mock |GTMAppAuthFetcherAuthorization|.
  id _authorization;
  
  // Fake fetcher service to emulate network requests.
  GIDFakeFetcherService *_fakeFetcherService;
}

@end

@implementation GIDDataFetcherTest

- (void)setUp {
  [super setUp];
  _dataFetcher = [[GIDDataFetcher alloc] init];
  _fakeFetcherService = [[GIDFakeFetcherService alloc] init];
  
  _authorization = OCMStrictClassMock([GTMAppAuthFetcherAuthorization class]);
  OCMStub([_authorization alloc]).andReturn(_authorization);
  OCMStub([_authorization initWithAuthState:OCMOCK_ANY]).andReturn(_authorization);
  OCMStub([_authorization fetcherService]).andReturn(_fakeFetcherService);
}

- (void)tearDown {
  _authorization = nil;
  [super tearDown];
}

- (void)testFetchData_success {
  NSURL *url = [NSURL URLWithString:kTestURL];
  OIDAuthState *authState = [OIDAuthState testInstance];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with no error"];

  [_dataFetcher startFetchURL:url
                fromAuthState:authState
                  withComment:@"Test data fetcher."
                   completion:^(NSData *data, NSError *error) {
    if (error == nil) {
      [expectation fulfill];
    }
  }];

  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  [self didFetch:nil error:nil];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchData_error {
  NSURL *url = [NSURL URLWithString:kTestURL];
  OIDAuthState *authState = [OIDAuthState testInstance];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with an error"];
  [_dataFetcher startFetchURL:url
                fromAuthState:authState
                  withComment:@"Test data fetcher."
                   completion:^(NSData *data, NSError *error) {
    if (error != nil) {
      [expectation fulfill];
    }
  }];

  XCTAssertTrue([self isFetcherStarted], @"should start fetching");
  // Emulate result back from server.
  NSError *error = [self error];
  [self didFetch:nil error:error];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Helpers

// Whether or not a fetcher has been started.
- (BOOL)isFetcherStarted {
  NSUInteger count = _fakeFetcherService.fetchers.count;
  XCTAssertTrue(count <= 1, @"Only one fetcher is supported");
  return !!count;
}

// Emulates server returning the data as in JSON.
- (void)didFetch:(id)dataObject error:(NSError *)error {
  NSData *data = nil;
  if (dataObject) {
    NSError *jsonError = nil;
    data = [NSJSONSerialization dataWithJSONObject:dataObject
                                           options:0
                                             error:&jsonError];
    XCTAssertNil(jsonError, @"must provide valid data");
  }
  [_fakeFetcherService.fetchers[0] didFinishWithData:data error:error];
}

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

@end
