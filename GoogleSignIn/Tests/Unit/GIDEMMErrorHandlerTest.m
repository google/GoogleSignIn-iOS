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

// Records how, and whether, a GIDEMMErrorHandler completion was called.
@interface GIDEMMCompletionSpy : NSObject
@property(nonatomic, readonly) NSInteger callCount;
@property(nonatomic, readonly) BOOL handled;
// A completion to pass to -handleErrorFromResponse:completion:.
- (void (^)(BOOL handled))completion;
@end

@implementation GIDEMMCompletionSpy

- (void (^)(BOOL handled))completion {
  return ^(BOOL handled) {
    self->_callCount++;
    self->_handled = handled;
  };
}

@end

// Unit test for GIDEMMErrorHandler.
@interface GIDEMMErrorHandlerTest : XCTestCase
@end

@implementation GIDEMMErrorHandlerTest {
  // Whether key window has been set.
  BOOL _keyWindowSet;

  // The view controller that has been presented, if any.
  UIViewController *_presentedViewController;
}

- (void)setUp {
  [super setUp];
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

// Waits until work already dispatched to the main queue (such as the handler presenting
// its dialog) has run.
- (void)waitForMainQueue {
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait for main queue"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

// Returns the presented UIAlertController, or records a test failure and returns nil.
- (nullable UIAlertController *)presentedAlert {
  if (![_presentedViewController isKindOfClass:[UIAlertController class]]) {
    XCTFail(@"Expected a presented UIAlertController, got %@.", _presentedViewController);
    return nil;
  }
  return (UIAlertController *)_presentedViewController;
}

// Asserts that the alert has a title and message and that its actions have the expected titles.
- (void)assertAlert:(UIAlertController *)alert hasActionTitles:(NSArray<NSString *> *)titles {
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqualObjects([alert.actions valueForKey:@"title"], titles);
}

// Invokes the handler of the alert action with the given title, or records a test failure.
- (void)tapActionTitled:(NSString *)title inAlert:(UIAlertController *)alert {
  for (UIAlertAction *action in alert.actions) {
    if ([action.title isEqualToString:title]) {
      action.actionHandler(action);
      return;
    }
  }
  XCTFail(@"No action titled '%@' in alert (found: %@).",
          title, [alert.actions valueForKey:@"title"]);
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
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:@{ @"abc" : @123 }
                                                    completion:spy.completion];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertFalse(spy.handled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);
}

// Verifies that a non-string value under the `error` key is ignored rather than crashing.
// The value comes straight from a server JSON response and is typed `id`, so it can be any
// plist type. `-hasPrefix:` is an `NSString` method, so before the type check was added it
// raised an unrecognized selector exception on a number, array or dictionary.
- (void)testNonStringErrorValue {
  NSArray *nonStringValues = @[ @123, @[ @"emm_passcode_required" ], @{ @"a" : @"b" } ];
  for (id nonStringValue in nonStringValues) {
    GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
    NSDictionary<NSString *, id> *response = @{ @"error" : nonStringValue };
    [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                      completion:spy.completion];
    XCTAssertEqual(spy.callCount, 1);
    XCTAssertFalse(spy.handled);
  }
}

// Verifies that the handler doesn't handle non-EMM error.
- (void)testNoEMMError {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"invalid_token" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertFalse(spy.handled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);
}

// Verifies that the handler handles general EMM error with user tapping 'OK'.
- (void)testGeneralEMMErrorOK {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_something_wrong" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  // Should handle no more error while the previous one is being handled.
  GIDEMMCompletionSpy *secondSpy = [[GIDEMMCompletionSpy alloc] init];
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:secondSpy.completion];
  XCTAssertEqual(secondSpy.callCount, 1);
  XCTAssertFalse(secondSpy.handled);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"OK" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self tapActionTitled:@"OK" inAlert:alert];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
}

// Verifies that the pending-dialog flag is cleared when there is no key window, so a later
// EMM error can still present its dialog. `GIDEMMErrorHandler` is a process-wide singleton,
// so before this fix a single windowless error suppressed every dialog that followed.
- (void)testNoKeyWindow_ClearsPendingDialogForNextError {
  [GULSwizzler unswizzleClass:[GIDEMMErrorHandler class]
                     selector:@selector(keyWindow)
              isClassSelector:NO];
  [GULSwizzler swizzleClass:[GIDEMMErrorHandler class]
                   selector:@selector(keyWindow)
            isClassSelector:NO
                  withBlock:^() { return nil; }];

  GIDEMMCompletionSpy *firstSpy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_something_wrong" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:firstSpy.completion];

  [self waitForMainQueue];
  XCTAssertEqual(firstSpy.callCount, 1);
  XCTAssertTrue(firstSpy.handled);
  XCTAssertNil(_presentedViewController);

  // Restore a working key window.
  [GULSwizzler unswizzleClass:[GIDEMMErrorHandler class]
                     selector:@selector(keyWindow)
              isClassSelector:NO];
  UIWindow *fakeKeyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [GULSwizzler swizzleClass:[GIDEMMErrorHandler class]
                   selector:@selector(keyWindow)
            isClassSelector:NO
                  withBlock:^() { return fakeKeyWindow; }];

  GIDEMMCompletionSpy *secondSpy = [[GIDEMMCompletionSpy alloc] init];
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:secondSpy.completion];
  // Before the fix, this completed immediately with NO: the pending-dialog flag was still YES.
  XCTAssertEqual(secondSpy.callCount, 0);

  [self waitForMainQueue];
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"OK" ]];
  [self tapActionTitled:@"OK" inAlert:alert];
  XCTAssertEqual(secondSpy.callCount, 1);
  XCTAssertTrue(secondSpy.handled);
}

// Verifies the flag handed to the completion on both the non-EMM path (synchronous, NO) and
// the EMM path (after dialog dismissal, YES).
- (void)testCompletionReceivesHandledFlag {
  // First half — non-EMM.
  GIDEMMCompletionSpy *nonEMMSpy = [[GIDEMMCompletionSpy alloc] init];
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:@{ @"error" : @"invalid_token" }
                                                    completion:nonEMMSpy.completion];
  XCTAssertEqual(nonEMMSpy.callCount, 1);
  XCTAssertFalse(nonEMMSpy.handled);

  // Second half — EMM.
  GIDEMMCompletionSpy *emmSpy = [[GIDEMMCompletionSpy alloc] init];
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:@{ @"error" : @"emm_something_wrong" }
                                                    completion:emmSpy.completion];
  XCTAssertEqual(emmSpy.callCount, 0);

  [self waitForMainQueue];
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"OK" ]];
  XCTAssertEqual(emmSpy.callCount, 0);

  [self tapActionTitled:@"OK" inAlert:alert];
  XCTAssertEqual(emmSpy.callCount, 1);
  XCTAssertTrue(emmSpy.handled);
}

// Verifies that the handler handles EMM screenlock required error with user tapping 'Cancel'.
- (void)testScreenlockRequiredCancel {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_passcode_required" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"Cancel", @"Settings" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self tapActionTitled:@"Cancel" inAlert:alert];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
}

// Verifies that the handler handles EMM screenlock required error with user tapping 'Settings'.
- (void)testScreenlockRequiredSettings {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_passcode_required" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"Cancel", @"Settings" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self expectOpenURLString:UIApplicationOpenSettingsURLString inAction:^() {
    [self tapActionTitled:@"Settings" inAlert:alert];
  }];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
}

// Verifies that the handler handles EMM app verification required error without a URL.
- (void)testAppVerificationNoURL {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response = @{ @"error" : @"emm_app_verification_required" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"OK" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self tapActionTitled:@"OK" inAlert:alert];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
}

// Verifies that the handler handles EMM app verification required error user tapping 'Cancel'.
- (void)testAppVerificationCancel {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response =
      @{ @"error" : @"emm_app_verification_required: https://host.domain/path" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"Cancel", @"Connect" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self tapActionTitled:@"Cancel" inAlert:alert];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
}

// Verifies that the handler handles EMM app verification required error user tapping 'Connect'.
- (void)testAppVerificationConnect {
  GIDEMMCompletionSpy *spy = [[GIDEMMCompletionSpy alloc] init];
  NSDictionary<NSString *, NSString *> *response =
      @{ @"error" : @"emm_app_verification_required: https://host.domain/path" };
  [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:response
                                                    completion:spy.completion];
  // The dialog is presented asynchronously on the main queue, so nothing has happened yet.
  XCTAssertEqual(spy.callCount, 0);
  XCTAssertFalse(_keyWindowSet);
  XCTAssertNil(_presentedViewController);

  [self waitForMainQueue];
  XCTAssertTrue(_keyWindowSet);
  UIAlertController *alert = [self presentedAlert];
  if (!alert) return;
  [self assertAlert:alert hasActionTitles:@[ @"Cancel", @"Connect" ]];
  XCTAssertEqual(spy.callCount, 0);

  [self expectOpenURLString:@"https://host.domain/path" inAction:^() {
    [self tapActionTitled:@"Connect" inAlert:alert];
  }];
  XCTAssertEqual(spy.callCount, 1);
  XCTAssertTrue(spy.handled);
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
