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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDSignInStrings.h"
#import "GoogleSignIn/Tests/Unit/UIAlertAction+Testing.h"

#ifdef SWIFT_PACKAGE
@import GoogleUtilities_MethodSwizzler;
@import GoogleUtilities_SwizzlerTestHelpers;
@import OCMock;
#else
#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>
#import <OCMock/OCMock.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Unit test for GIDEMMErrorHandler.
@interface GIDEMMErrorHandlerTest : XCTestCase
@end

@implementation GIDEMMErrorHandlerTest {
  // Whether or not the current device runs on iOS 10.
  BOOL _isIOS10;

  // Whether key window has been set.
  BOOL _keyWindowSet;

  // The view controller that has been presented, if any.
  UIViewController *_presentedViewController;
}

- (void)setUp {
  [super setUp];
  _isIOS10 = [UIDevice currentDevice].systemVersion.integerValue == 10;
  _keyWindowSet = NO;
  _presentedViewController = nil;
  UIWindow *fakeKeyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [GULSwizzler swizzleClass:[GIDEMMErrorHandler class]
                   selector:@selector(keyWindow)
            isClassSelector:NO
                  withBlock:^() { return fakeKeyWindow; }];
  [GULSwizzler swizzleClass:[UIWindow class]
                   selector:@selector(makeKeyAndVisible)
            isClassSelector:NO
                  withBlock:^() { self->_keyWindowSet = YES; }];
  [GULSwizzler swizzleClass:[UIViewController class]
                   selector:@selector(presentViewController:animated:completion:)
            isClassSelector:NO
                  withBlock:^(id obj, id arg1) { self->_presentedViewController = arg1; }];
  [GULSwizzler swizzleClass:[GIDSignInStrings class]
                   selector:@selector(localizedStringForKey:text:)
            isClassSelector:YES
                  withBlock:^(id obj, NSString *key, NSString *text) { return text; }];
}

- (void)tearDown {
  [GULSwizzler unswizzleClass:[GIDEMMErrorHandler class]
                     selector:@selector(keyWindow)
              isClassSelector:NO];
  [GULSwizzler unswizzleClass:[UIWindow class]
                     selector:@selector(makeKeyAndVisible)
              isClassSelector:NO];
  [GULSwizzler unswizzleClass:[UIViewController class]
                     selector:@selector(presentViewController:animated:completion:)
              isClassSelector:NO];
  [GULSwizzler unswizzleClass:[GIDSignInStrings class]
                     selector:@selector(localizedStringForKey:text:)
              isClassSelector:YES];
  _presentedViewController = nil;
  [super tearDown];
}

// Expects opening a particular URL string in performing an action.
- (void)expectOpenURLString:(NSString *)urlString inAction:(void (^)(void))action {
  // Swizzle and mock [UIApplication sharedApplication] since it is unavailable in unit tests.
  id mockApplication = OCMStrictClassMock([UIApplication class]);
  [GULSwizzler swizzleClass:[UIApplication class]
                   selector:@selector(sharedApplication)
            isClassSelector:YES
                  withBlock:^() { return mockApplication; }];
  [[mockApplication expect] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
  action();
  [mockApplication verify];
  [GULSwizzler unswizzleClass:[UIApplication class]
                     selector:@selector(sharedApplication)
              isClassSelector:YES];
}

// Verifies that the handler doesn't handle non-exist error.
- (void)testNoError {
  __block BOOL completionCalled = NO;
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:@{ @"abc" : @123 }
                                                                  completion:^() {
    completionCalled = YES;
  }];
  XCTAssertFalse(result);
  XCTAssertTrue(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);
}

// Verifies that the handler doesn't handle non-EMM error.
- (void)testNoEMMError {
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"invalid_token" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  XCTAssertFalse(result);
  XCTAssertTrue(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);
}

// Verifies that the handler handles general EMM error with user tapping 'OK'.
- (void)testGeneralEMMErrorOK {
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_something_wrong" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Should handle no more error while the previous one is being handled.
  __block BOOL secondCompletionCalled = NO;
  BOOL secondResult = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    secondCompletionCalled = YES;
  }];
  XCTAssertFalse(secondResult);
  XCTAssertTrue(secondCompletionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 1);

  // Pretend to touch the "OK" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"OK");
  action.actionHandler(action);
  XCTAssertTrue(completionCalled);
}

// Verifies that the handler handles EMM screenlock required error with user tapping 'Cancel'.
- (void)testScreenlockRequiredCancel {
  if (_isIOS10) {
    // The dialog is different on iOS 10.
    return;
  }
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_passcode_required" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Cancel" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"Cancel");
  action.actionHandler(action);
  XCTAssertTrue(completionCalled);
}

// Verifies that the handler handles EMM screenlock required error with user tapping 'Settings'.
- (void)testScreenlockRequiredSettings {
  if (_isIOS10) {
    // The dialog is different on iOS 10.
    return;
  }
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_passcode_required" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Settings" button.
  UIAlertAction *action = alert.actions[1];
  XCTAssertEqualObjects(action.title, @"Settings");
  [self expectOpenURLString:UIApplicationOpenSettingsURLString inAction:^() {
    action.actionHandler(action);
  }];
  XCTAssertTrue(completionCalled);
}

- (void)testScreenlockRequiredOkOnIOS10 {
  if (!_isIOS10) {
    // A more useful dialog is used for other iOS versions.
    return;
  }
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_passcode_required" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 1);

  // Pretend to touch the "OK" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"OK");
  action.actionHandler(action);
  XCTAssertTrue(completionCalled);
}

// Verifies that the handler handles EMM app verification required error without a URL.
- (void)testAppVerificationNoURL {
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_app_verification_required" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 1);

  // Pretend to touch the "OK" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"OK");
  action.actionHandler(action);
  XCTAssertTrue(completionCalled);
}


// Verifies that the handler handles EMM app verification required error user tapping 'Cancel'.
- (void)testAppVerificationCancel {
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response =
      @{ @"error" : @"emm_app_verification_required: https://host.domain/path" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Cancel" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"Cancel");
  action.actionHandler(action);
  XCTAssertTrue(completionCalled);
}

// Verifies that the handler handles EMM app verification required error user tapping 'Connect'.
- (void)testAppVerificationConnect {
  __block BOOL completionCalled = NO;
  NSDictionary<NSString *, NSString *> *response =
      @{ @"error" : @"emm_app_verification_required: https://host.domain/path" };
  BOOL result = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                                  completion:^() {
    completionCalled = YES;
  }];
  if (![UIAlertController class]) {
    XCTAssertFalse(result);
    XCTAssertTrue(completionCalled);
    XCTAssertFalse(_keyWindowSet);
    XCTAssertNil(_presentedViewController);
    return;
  }
  XCTAssertTrue(result);
  XCTAssertFalse(completionCalled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertFalse(completionCalled);
  XCTAssertTrue(_keyWindowSet);
  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Connect" button.
  UIAlertAction *action = alert.actions[1];
  XCTAssertEqualObjects(action.title, @"Connect");
  [self expectOpenURLString:@"https://host.domain/path" inAction:^() {
    action.actionHandler(action);
  }];
  XCTAssertTrue(completionCalled);
}

// Verifies that the handler can handle sequential errors independently.
- (void)testSequentialErrors {
  [self testGeneralEMMErrorOK];
  _keyWindowSet = NO;
  _presentedViewController = nil;
  [self testScreenlockRequiredCancel];
}

// Temporarily disable testKeyWindow for Xcode 12 and under due to unexplained failure.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000

// Verifies that the `keyWindow` internal method works on all OS versions as expected.
- (void)testKeyWindow {
  // The original method has been swizzled in `setUp` so get its original implementation to test.
  typedef id (*KeyWindowSignature)(id, SEL);
  KeyWindowSignature keyWindowFunction = (KeyWindowSignature)
      [GULSwizzler originalImplementationForClass:[GIDEMMErrorHandler class]
                       selector:@selector(keyWindow)
                isClassSelector:NO];
  UIWindow *mockKeyWindow = OCMClassMock([UIWindow class]);
  OCMStub(mockKeyWindow.isKeyWindow).andReturn(YES);
  UIApplication *mockApplication = OCMClassMock([UIApplication class]);
  [GULSwizzler swizzleClass:[UIApplication class]
                   selector:@selector(sharedApplication)
            isClassSelector:YES
                  withBlock:^{ return mockApplication; }];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
  if (@available(iOS 15, *)) {
    UIWindowScene *mockWindowScene = OCMClassMock([UIWindowScene class]);
    OCMStub(mockApplication.connectedScenes).andReturn(@[mockWindowScene]);
    OCMStub(mockWindowScene.activationState).andReturn(UISceneActivationStateForegroundActive);
    OCMStub(mockWindowScene.keyWindow).andReturn(mockKeyWindow);
  } else
#endif  // __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
  {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
    if (@available(iOS 13, *)) {
      OCMStub(mockApplication.windows).andReturn(@[mockKeyWindow]);
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
      OCMStub(mockApplication.keyWindow).andReturn(mockKeyWindow);
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
    }
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
  }
  UIWindow *keyWindow =
      keyWindowFunction([GIDEMMErrorHandler sharedInstance], @selector(keyWindow));
  XCTAssertEqual(keyWindow, mockKeyWindow);
  [GULSwizzler unswizzleClass:[UIApplication class]
                     selector:@selector(sharedApplication)
              isClassSelector:YES];
}

#endif  // __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
