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

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#ifdef SWIFT_PACKAGE
@import OCMock;
#else
#import <OCMock/OCMock.h>
#endif

@interface GIDSignInInternalOptionsTest : XCTestCase
@end

@implementation GIDSignInInternalOptionsTest

- (void)testDefaultOptions {
  id configuration = OCMStrictClassMock([GIDConfiguration class]);
  id presentingViewController = OCMStrictClassMock([UIViewController class]);
  NSString *loginHint = @"login_hint";
  GIDSignInCallback callback = ^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {};
  
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:loginHint
                                                       callback:callback];
  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);

  OCMVerifyAll(configuration);
  OCMVerifyAll(presentingViewController);
}

- (void)testSilentOptions {
  GIDSignInCallback callback = ^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {};
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions silentOptionsWithCallback:callback];
  XCTAssertFalse(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);
  XCTAssertEqual(options.callback, callback);
}

@end
