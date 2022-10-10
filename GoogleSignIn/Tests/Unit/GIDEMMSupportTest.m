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

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDEMMSupport.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

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
@end

@implementation GIDEMMSupportTest

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

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
