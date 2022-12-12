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
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  id presentingViewController = OCMStrictClassMock([UIViewController class]);
#elif TARGET_OS_OSX
  id presentingWindow = OCMStrictClassMock([NSWindow class]);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
  NSString *loginHint = @"login_hint";

  GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                     NSError * _Nullable error) {};
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:presentingViewController
#elif TARGET_OS_OSX
                                               presentingWindow:presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                      loginHint:loginHint
                                                  addScopesFlow:NO
                                                     completion:completion];
  XCTAssertTrue(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertFalse(options.addScopesFlow);
  XCTAssertNil(options.extraParams);

  OCMVerifyAll(configuration);
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  OCMVerifyAll(presentingViewController);
#elif TARGET_OS_OSX
  OCMVerifyAll(presentingWindow);
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
}

- (void)testSilentOptions {
  GIDSignInCompletion completion = ^(GIDSignInResult *_Nullable signInResult,
                                     NSError * _Nullable error) {};
  GIDSignInInternalOptions *options = [GIDSignInInternalOptions silentOptionsWithCompletion:completion];
  XCTAssertFalse(options.interactive);
  XCTAssertFalse(options.continuation);
  XCTAssertNil(options.extraParams);
  XCTAssertEqual(options.completion, completion);
}

@end
