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

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import OCMock;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <OCMock/OCMock.h>
#endif

static NSString *const kTestURL = @"https://testURL.com";
static NSString *const kErrorDomain = @"ERROR_DOMAIN";
static NSInteger const kErrorCode = 400;

@interface GIDDataFetcherTest : XCTestCase {
  GIDDataFetcher *_dataFetcher;
}

@end

@implementation GIDDataFetcherTest

- (void)setUp {
  [super setUp];
  _dataFetcher = [[GIDDataFetcher alloc] init];
}

- (void)testFetchData_success {
  NSURL *url = [NSURL URLWithString:kTestURL];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with no error"];
  
  
  GTMSessionFetcherTestBlock block =
      ^(GTMSessionFetcher *fetcherToTest, GTMSessionFetcherTestResponse testResponse) {
        NSData *data = [[NSData alloc] init];
        testResponse(nil, data, nil);
      };
  [GTMSessionFetcher setGlobalTestBlock:block];
  
  [_dataFetcher fetchURL:url
             withComment:@"Test data fetcher."
              completion:^(NSData *data, NSError *error) {
    XCTAssertNil(error);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchData_error {
  NSURL *url = [NSURL URLWithString:kTestURL];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Callback called with an error"];
  
  GTMSessionFetcherTestBlock block =
      ^(GTMSessionFetcher *fetcherToTest, GTMSessionFetcherTestResponse testResponse) {
        NSData *data = [[NSData alloc] init];
        NSError *error = [self error];
        testResponse(nil, data, error);
      };
  [GTMSessionFetcher setGlobalTestBlock:block];
  
  
  [_dataFetcher fetchURL:url
             withComment:@"Test data fetcher."
              completion:^(NSData *data, NSError *error) {
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, kErrorCode);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Helpers

- (NSError *)error {
  return [NSError errorWithDomain:kErrorDomain code:kErrorCode userInfo:nil];
}

@end
