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

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

#import <GoogleUtilities/GULSwizzler.h>
#import <GoogleUtilities/GULSwizzler+Unswizzle.h>

@interface GIDMDMPasscodeStateTests : XCTestCase
@end

@implementation GIDMDMPasscodeStateTests {
  /** Whether or not the iOS version is equal or greater than 9.0. */
  BOOL _isIOS9orAbove;

  /** Whether or not `canEvaluatePolicy:error:` method has been called. */
  BOOL _canEvaluatePolicyCalled;

  /** The next result to be returned from the `canEvaluatePolicy:error:` method. */
  BOOL _nextCanEvaluatePolicyResult;

  /** The next error to be returned from the `canEvaluatePolicy:error:` method. */
  NSError *_nextCanEvaluatePolicyError;
}

- (void)setUp {
  [super setUp];
  _isIOS9orAbove = [[NSProcessInfo processInfo]
      isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
  if (!_isIOS9orAbove) {
    return;
  }
  _canEvaluatePolicyCalled = NO;
  id canEvaluatePolicyError = ^BOOL(id context, LAPolicy policy, NSError * _Nullable *error) {
    self->_canEvaluatePolicyCalled = YES;
    XCTAssertEqual(policy, LAPolicyDeviceOwnerAuthentication);
    if (error) {
      *error = self->_nextCanEvaluatePolicyError;
    }
    return self->_nextCanEvaluatePolicyResult;
  };
  [GULSwizzler swizzleClass:[LAContext class]
                   selector:@selector(canEvaluatePolicy:error:)
            isClassSelector:NO
                  withBlock:canEvaluatePolicyError];
  [self postApplicationDidEnterBackgroundNotification];
}

- (void)tearDown {
  if (!_isIOS9orAbove) {
    return;
  }
  [GULSwizzler unswizzleClass:[LAContext class]
                     selector:@selector(canEvaluatePolicy:error:)
              isClassSelector:NO];
}

/**
 * Verifies the correct response when LocalAuthentication API returns without an error.
 */
- (void)testLocalAuthenticationNoError {
  if (!_isIOS9orAbove) {
    return;
  }
  _nextCanEvaluatePolicyResult = YES;
  _nextCanEvaluatePolicyError = nil;
  GIDMDMPasscodeState *passcodeState = [GIDMDMPasscodeState passcodeState];
  XCTAssertTrue(_canEvaluatePolicyCalled);
  XCTAssertEqualObjects(passcodeState.status, @"YES");
  NSDictionary *dict = [self dictWithEncodedString:passcodeState.info];
  [self assertJSONNumber:dict[@"LocalAuthentication"][@"result"] isInteger:1];
  XCTAssertNil(dict[@"LocalAuthentication"][@"error_domain"]);
  XCTAssertNil(dict[@"LocalAuthentication"][@"error_code"]);
}

/**
 * Verifies the correct response when LocalAuthentication API returns with an error.
 */
- (void)testLocalAuthenticationHasError {
  if (!_isIOS9orAbove) {
    return;
  }
  NSString *fakeErrorDomain = @"asdf.hjkl";
  NSInteger fakeErrorCode = -12345;
  _nextCanEvaluatePolicyResult = NO;
  _nextCanEvaluatePolicyError = [NSError errorWithDomain:fakeErrorDomain
                                                    code:fakeErrorCode
                                                userInfo:nil];
  GIDMDMPasscodeState *passcodeState = [GIDMDMPasscodeState passcodeState];
  XCTAssertTrue(_canEvaluatePolicyCalled);
  XCTAssertEqualObjects(passcodeState.status, @"NO");
  NSDictionary *dict = [self dictWithEncodedString:passcodeState.info];
  [self assertJSONNumber:dict[@"LocalAuthentication"][@"result"] isInteger:0];
  XCTAssertEqualObjects(dict[@"LocalAuthentication"][@"error_domain"], fakeErrorDomain);
  XCTAssertEqualObjects(dict[@"LocalAuthentication"][@"error_code"], @(fakeErrorCode));
}

/**
 * Verifies caching behavior regarding to calling LocalAuthentication API.
 */
- (void)testLocalAuthenticationCache {
  if (!_isIOS9orAbove) {
    return;
  }
  GIDMDMPasscodeState *oldPasscodeState = [GIDMDMPasscodeState passcodeState];
  _canEvaluatePolicyCalled = false;
  GIDMDMPasscodeState *newPasscodeState = [GIDMDMPasscodeState passcodeState];
  XCTAssertFalse(_canEvaluatePolicyCalled);
  XCTAssertEqualObjects(oldPasscodeState.status, newPasscodeState.status);
  XCTAssertEqualObjects(oldPasscodeState.info, newPasscodeState.info);

  // Verify that the cache is cleared after background notification.
  [self postApplicationDidEnterBackgroundNotification];
  [GIDMDMPasscodeState passcodeState];
  XCTAssertTrue(_canEvaluatePolicyCalled);
}

/**
 * Verifies the presence of the result from Keychain API.
 * Keychain API is in C thus there is no easy way to swizzler them.
 */
- (void)testKeychain {
  GIDMDMPasscodeState *passcodeState = [GIDMDMPasscodeState passcodeState];
  NSDictionary *dict = [self dictWithEncodedString:passcodeState.info];
  XCTAssertTrue([dict[@"Keychain"][@"result"] isKindOfClass:[NSNumber class]]);
}

#pragma mark - Helpers

/**
 * Posts `UIApplicationDidEnterBackgroundNotification` notification.
 */
- (void)postApplicationDidEnterBackgroundNotification {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (NSDictionary *)dictWithEncodedString:(NSString *)string {
  string = [string stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
  string = [string stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
  XCTAssertNotNil(data);
  id dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
  XCTAssertTrue([dictionary isKindOfClass:[NSDictionary class]]);
  return (NSDictionary *)dictionary;
}

/**
 * Asserts that the given number is the integer by both value and type.
 */
- (void)assertJSONNumber:(NSNumber *)number isInteger:(int)integer {
  XCTAssertTrue([number isKindOfClass:[NSNumber class]]);
  XCTAssertEqual([number intValue], integer);
  NSString *objcType = [NSString stringWithUTF8String:[number objCType]];
  // Depends on iOS version, numbers from JSON can be either "int" or "long long".
  XCTAssertTrue([objcType isEqualToString:@"i"] || [objcType isEqualToString:@"q"],
                @"unrecognized objcType: %@", objcType);
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
