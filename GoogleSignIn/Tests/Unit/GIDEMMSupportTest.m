/*
 * Copyright 2022 Google LLC
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDEMMSupport.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDFailingOIDAuthState.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/UIAlertAction+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GoogleUtilities_MethodSwizzler;
@import GoogleUtilities_SwizzlerTestHelpers;
@import OCMock;
#else
#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>
#import <AppAuth/OIDError.h>
#import <OCMock/OCMock.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The system name in old iOS versions.
static NSString *const kOldIOSName = @"iPhone OS";

// The system name in new iOS versions.
static NSString *const kNewIOSName = @"iOS";

// They keys in EMM dictionary.
static NSString *const kEMMKey = @"emm_support";
static NSString *const kDeviceOSKey = @"device_os";
static NSString *const kEMMPasscodeInfoKey = @"emm_passcode_info";

@interface GIDEMMSupportTest : XCTestCase
  // The view controller that has been presented, if any.
@property(nonatomic, strong, nullable) UIViewController *presentedViewController;

@end

@implementation GIDEMMSupportTest

- (void)testEMMSupportDelegate {
  [self setupSwizzlers];
  XCTestExpectation *emmErrorExpectation = [self expectationWithDescription:@"EMM AppAuth error"];

  GIDFailingOIDAuthState *failingAuthState = [GIDFailingOIDAuthState testInstance];
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:failingAuthState profileData:nil];
  GIDFakeFetcherService *fakeFetcherService = [[GIDFakeFetcherService alloc]
                                                initWithAuthorizer:user.fetcherAuthorizer];

  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@""]];
  GTMSessionFetcher *fetcher = [fakeFetcherService fetcherWithRequest:request];

  [fetcher beginFetchWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
    XCTAssertNotNil(error);
    NSDictionary<NSString *, id> *userInfo = @{
      @"OIDOAuthErrorResponseErrorKey": @{@"error": @"emm_passcode_required"},
      NSUnderlyingErrorKey: [NSError errorWithDomain:@"SomeUnderlyingError" code:0 userInfo:nil]
    };
    NSError *expectedError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                                 code:kGIDSignInErrorCodeEMM
                                             userInfo:userInfo];
    XCTAssertEqualObjects(expectedError, error);
    [emmErrorExpectation fulfill];
  }];

  // Wait for the code under test to be executed on the main thread.
  XCTestExpectation *mainThreadExpectation =
      [self expectationWithDescription:@"wait for main thread"];
  dispatch_async(dispatch_get_main_queue(), ^() {
    [mainThreadExpectation fulfill];
  });
  [self waitForExpectations:@[mainThreadExpectation] timeout:1];

  XCTAssertTrue([_presentedViewController isKindOfClass:[UIAlertController class]]);
  UIAlertController *alert = (UIAlertController *)_presentedViewController;
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Cancel" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"Cancel");
  action.actionHandler(action);

  [self waitForExpectations:@[emmErrorExpectation] timeout:1];
  [self unswizzle];
}

- (void)testUpdatedEMMParametersWithParameters_NoEMMKey {
  NSDictionary *originalParameters = @{
    @"not_emm_support_key" : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [GIDEMMSupport updatedEMMParametersWithParameters:originalParameters];

  XCTAssertEqualObjects(updatedEMMParameters, originalParameters);
}

- (void)testUpdateEMMParametersWithParameters_systemName {
  [GULSwizzler swizzleClass:[UIDevice class]
                   selector:@selector(systemName)
            isClassSelector:NO
                  withBlock:^(id sender) { return kNewIOSName; }];

  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [GIDEMMSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, [self systemVersion]]
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);

  [self addTeardownBlock:^{
    [GULSwizzler unswizzleClass:[UIDevice class]
                       selector:@selector(systemName)
                isClassSelector:NO];
  }];
}

// When the systemName is @"iPhone OS" we still get "iOS".
- (void)testUpdateEMMParametersWithParameters_systemNameNormalization {
  [GULSwizzler swizzleClass:[UIDevice class]
                    selector:@selector(systemName)
             isClassSelector:NO
                   withBlock:^(id sender) { return kOldIOSName; }];

  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [GIDEMMSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, [self systemVersion]]
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);

  [self addTeardownBlock:^{
    [GULSwizzler unswizzleClass:[UIDevice class]
                       selector:@selector(systemName)
                isClassSelector:NO];
  }];
}

- (void)testUpdateEMMParametersWithParameters_passcodInfo {
  [GULSwizzler swizzleClass:[UIDevice class]
                   selector:@selector(systemName)
            isClassSelector:NO
                  withBlock:^(id sender) { return kOldIOSName; }];

  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : @"old one",
    kEMMPasscodeInfoKey : @"something",
  };

  NSDictionary *updatedEMMParameters =
      [GIDEMMSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, [self systemVersion]],
    kEMMPasscodeInfoKey : [GIDMDMPasscodeState passcodeState].info,
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);

  [self addTeardownBlock:^{
    [GULSwizzler unswizzleClass:[UIDevice class]
                       selector:@selector(systemName)
                isClassSelector:NO];
  }];
  
}

- (void)testHandleTokenFetchEMMError_errorIsEMM {
  // Set expectations.
  NSDictionary *errorJSON = @{ @"error" : @"EMM Specific Error" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];
  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^savedCompletion)(void);
  [[[mockEMMErrorHandler stub] andReturnValue:@YES]
      handleErrorFromResponse:errorJSON completion:[OCMArg checkWithBlock:^(id arg) {
    savedCompletion = arg;
    return YES;
  }]];

  XCTestExpectation *notCalled = [self expectationWithDescription:@"Callback is not called"];
  notCalled.inverted = YES;
  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];

  [GIDEMMSupport handleTokenFetchEMMError:emmError completion:^(NSError *error) {
    [notCalled fulfill];
    [called fulfill];
    XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeEMM);
  }];
  
  [self waitForExpectations:@[ notCalled ] timeout:1];
  savedCompletion();
  [self waitForExpectations:@[ called ] timeout:1];
}

- (void)testHandleTokenFetchEMMError_errorIsNotEMM {
  // Set expectations.
  NSDictionary *errorJSON = @{ @"error" : @"Not EMM Specific Error" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];
  id mockEMMErrorHandler = OCMStrictClassMock([GIDEMMErrorHandler class]);
  [[[mockEMMErrorHandler stub] andReturn:mockEMMErrorHandler] sharedInstance];
  __block void (^savedCompletion)(void);
  [[[mockEMMErrorHandler stub] andReturnValue:@NO]
      handleErrorFromResponse:errorJSON completion:[OCMArg checkWithBlock:^(id arg) {
    savedCompletion = arg;
    return YES;
  }]];

  XCTestExpectation *notCalled = [self expectationWithDescription:@"Callback is not called"];
  notCalled.inverted = YES;
  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];
  
  [GIDEMMSupport handleTokenFetchEMMError:emmError completion:^(NSError *error) {
    [notCalled fulfill];
    [called fulfill];
    XCTAssertEqualObjects(error.domain, @"anydomain");
    XCTAssertEqual(error.code, 12345);
  }];

  [self waitForExpectations:@[ notCalled ] timeout:1];
  savedCompletion();
  [self waitForExpectations:@[ called ] timeout:1];
}

# pragma mark - Helpers

- (NSString *)systemVersion {
  return [UIDevice currentDevice].systemVersion;
}

- (void)setupSwizzlers {
  UIWindow *fakeKeyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [GULSwizzler swizzleClass:[GIDEMMErrorHandler class]
                   selector:@selector(keyWindow)
            isClassSelector:NO
                  withBlock:^() { return fakeKeyWindow; }];
  [GULSwizzler swizzleClass:[UIViewController class]
                   selector:@selector(presentViewController:animated:completion:)
            isClassSelector:NO
                  withBlock:^(id obj, id arg1) { self->_presentedViewController = arg1; }];
}

- (void)unswizzle {
  [GULSwizzler unswizzleClass:[GIDEMMErrorHandler class]
                     selector:@selector(keyWindow)
              isClassSelector:NO];
  [GULSwizzler unswizzleClass:[UIViewController class]
                     selector:@selector(presentViewController:animated:completion:)
              isClassSelector:NO];
  self.presentedViewController = nil;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
