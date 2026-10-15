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

@import GTMAppAuth;

#import "GoogleSignIn/Sources/GIDEMMSupport.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDApplication/Fake/GIDFakeApplication.h"
#import "GoogleSignIn/Sources/GIDDevice/Fake/GIDFakeDevice.h"
#import "GoogleSignIn/Sources/GIDEMMAlertPresenter/Fake/GIDFakeEMMAlertPresenter.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/GIDFailingOIDAuthState.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcher.h"
#import "GoogleSignIn/Tests/Unit/GIDFakeFetcherService.h"
#import "GoogleSignIn/Tests/Unit/UIAlertAction+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDError.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The system name in old iOS versions.
static NSString *const kOldIOSName = @"iPhone OS";

// The system name in new iOS versions.
static NSString *const kNewIOSName = @"iOS";

// The system version reported by the fake device.
static NSString *const kSystemVersion = @"17.1";

// They keys in EMM dictionary.
static NSString *const kEMMKey = @"emm_support";
static NSString *const kDeviceOSKey = @"device_os";
static NSString *const kEMMPasscodeInfoKey = @"emm_passcode_info";

@interface GIDEMMSupportTest : XCTestCase
@end

@implementation GIDEMMSupportTest {
  // Fake device providing system name and version.
  GIDFakeDevice *_device;

  // Fake application providing the key window.
  GIDFakeApplication *_application;

  // Fake presenter capturing EMM alerts.
  GIDFakeEMMAlertPresenter *_alertPresenter;

  // Real EMM error handler backed by the fake application and alert presenter.
  GIDEMMErrorHandler *_errorHandler;

  // The system under test.
  GIDEMMSupport *_emmSupport;
}

- (void)setUp {
  [super setUp];
  _device = [[GIDFakeDevice alloc] initWithSystemName:kNewIOSName systemVersion:kSystemVersion];
  _application = [[GIDFakeApplication alloc] init];
  _application.keyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  _alertPresenter = [[GIDFakeEMMAlertPresenter alloc] init];
  _errorHandler = [[GIDEMMErrorHandler alloc] initWithApplication:_application
                                                   alertPresenter:_alertPresenter];
  _emmSupport = [[GIDEMMSupport alloc] initWithErrorHandler:_errorHandler device:_device];
}

- (void)testEMMSupportDelegate {
  XCTestExpectation *emmErrorExpectation = [self expectationWithDescription:@"EMM AppAuth error"];

  GIDFailingOIDAuthState *failingAuthState = [GIDFailingOIDAuthState testInstance];
  GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:failingAuthState profileData:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  GTMAuthSession *authSession = (GTMAuthSession *)user.fetcherAuthorizer;
#pragma clang diagnostic pop
  authSession.delegate = _emmSupport;
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

  UIAlertController *alert = _alertPresenter.presentedAlert;
  XCTAssertNotNil(alert);
  XCTAssertEqual(_alertPresenter.presentedOverKeyWindow, _application.keyWindow);
  XCTAssertNotNil(alert.title);
  XCTAssertNotNil(alert.message);
  XCTAssertEqual(alert.actions.count, 2);

  // Pretend to touch the "Cancel" button.
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"Cancel");
  action.actionHandler(action);

  [self waitForExpectations:@[emmErrorExpectation] timeout:1];
  XCTAssertNil(_alertPresenter.presentedAlert);
  XCTAssertEqual(_alertPresenter.dismissCount, 1u);
}

- (void)testUpdatedEMMParametersWithParameters_NoEMMKey {
  NSDictionary *originalParameters = @{
    @"not_emm_support_key" : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [_emmSupport updatedEMMParametersWithParameters:originalParameters];

  XCTAssertEqualObjects(updatedEMMParameters, originalParameters);
}

- (void)testUpdateEMMParametersWithParameters_systemName {
  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [_emmSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, kSystemVersion]
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);
}

// When the systemName is @"iPhone OS" we still get "iOS".
- (void)testUpdateEMMParametersWithParameters_systemNameNormalization {
  _device.systemName = kOldIOSName;

  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
  };

  NSDictionary *updatedEMMParameters =
      [_emmSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, kSystemVersion]
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);
}

- (void)testUpdateEMMParametersWithParameters_passcodInfo {
  _device.systemName = kOldIOSName;

  NSDictionary *originalParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : @"old one",
    kEMMPasscodeInfoKey : @"something",
  };

  NSDictionary *updatedEMMParameters =
      [_emmSupport updatedEMMParametersWithParameters:originalParameters];

  NSDictionary *expectedParameters = @{
    kEMMKey : @"xyz",
    kDeviceOSKey : [NSString stringWithFormat:@"%@ %@", kNewIOSName, [self systemVersion]],
    kEMMPasscodeInfoKey : [GIDMDMPasscodeState passcodeState].info,
  };

  XCTAssertEqualObjects(updatedEMMParameters, expectedParameters);
}

- (void)testHandleTokenFetchEMMError_errorIsEMM {
  NSDictionary *errorJSON = @{ @"error" : @"emm_passcode_required" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];

  XCTestExpectation *notCalled = [self expectationWithDescription:@"Callback is not called"];
  notCalled.inverted = YES;
  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];

  [_emmSupport handleTokenFetchEMMError:emmError completion:^(NSError *error) {
    [notCalled fulfill];
    [called fulfill];
    XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain);
    XCTAssertEqual(error.code, kGIDSignInErrorCodeEMM);
  }];

  [self waitForExpectations:@[ notCalled ] timeout:1];
  UIAlertController *alert = _alertPresenter.presentedAlert;
  XCTAssertNotNil(alert);
  XCTAssertEqual(alert.actions.count, 2u);
  UIAlertAction *action = alert.actions[0];
  XCTAssertEqualObjects(action.title, @"Cancel");
  action.actionHandler(action);
  [self waitForExpectations:@[ called ] timeout:1];
}

- (void)testHandleTokenFetchEMMError_errorIsNotEMM {
  NSDictionary *errorJSON = @{ @"error" : @"invalid_grant" };
  NSError *emmError = [NSError errorWithDomain:@"anydomain"
                                          code:12345
                                      userInfo:@{ OIDOAuthErrorResponseErrorKey : errorJSON }];

  XCTestExpectation *called = [self expectationWithDescription:@"Callback is called"];
  __block NSError *receivedError;
  [_emmSupport handleTokenFetchEMMError:emmError completion:^(NSError *error) {
    receivedError = error;
    [called fulfill];
  }];

  [self waitForExpectations:@[ called ] timeout:1];
  XCTAssertEqualObjects(receivedError, emmError);
  XCTAssertNil(_alertPresenter.presentedAlert);
  XCTAssertEqual(_alertPresenter.dismissCount, 0u);
}

# pragma mark - String Conversion Tests

- (void)testParametersWithParameters_withAnyNumber_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @12345 };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"12345",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withNumberOne_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @1 };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"1",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withNumberZero_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @0};

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"0",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withBooleanYes_isConvertedToTrueString {
  NSDictionary *inputParameters = @{ @"bool_key": @YES };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"bool_key"], @"true",
                        @"The boolean YES should be converted to the string 'true'.");
  XCTAssertTrue([stringifiedParameters[@"bool_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withBooleanNo_isConvertedToFalseString {
  NSDictionary *inputParameters = @{ @"bool_key": @NO };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"bool_key"], @"false",
                        @"The boolean NO should be converted to the string 'false'.");
  XCTAssertTrue([stringifiedParameters[@"bool_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withString_remainsUnchanged {
  NSDictionary *inputParameters = @{ @"string_key": @"hello" };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"string_key"], @"hello",
                        @"The original string value should be preserved.");
  XCTAssertTrue([stringifiedParameters[@"string_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withEMMSupportNil_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @12345 };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:nil
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"12345",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withArbitraryEMMSupport_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @12345 };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"False"
                                                       isPasscodeInfoRequired:NO];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"12345",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
  XCTAssertEqualObjects(stringifiedParameters[kEMMKey], @"False",
                        @"The EMM support parameter should append any valid NSString it receives.");
  XCTAssertTrue([stringifiedParameters[kEMMKey] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
}

- (void)testParametersWithParameters_withPasscodeInfoRequired_isConvertedToString {
  NSDictionary *inputParameters = @{ @"number_key": @12345 };

  NSDictionary *stringifiedParameters = [_emmSupport parametersWithParameters:inputParameters
                                                                   emmSupport:@"1"
                                                       isPasscodeInfoRequired:YES];

  XCTAssertEqualObjects(stringifiedParameters[@"number_key"], @"12345",
                        @"The NSNumber should be converted to a string.");
  XCTAssertTrue([stringifiedParameters[@"number_key"] isKindOfClass:[NSString class]],
                @"The final value should be of a NSString type.");
  XCTAssertNotNil(stringifiedParameters[kEMMPasscodeInfoKey],
                  @"The passcode info key should be present when requested.");
  XCTAssertTrue([stringifiedParameters[kEMMPasscodeInfoKey] isKindOfClass:[NSString class]],
                @"The passcode info value should be of a NSString type.");
}

# pragma mark - Helpers

- (NSString *)systemVersion {
  return kSystemVersion;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
