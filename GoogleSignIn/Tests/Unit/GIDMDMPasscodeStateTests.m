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

#import "GoogleSignIn/Sources/GIDLocalAuthentication/Fake/GIDFakeLocalAuthenticationContext.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeCache.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

@interface GIDMDMPasscodeStateTests : XCTestCase
@end

@implementation GIDMDMPasscodeStateTests {
  /** Stands in for the `LAContext` the cache probes. */
  GIDFakeLocalAuthenticationContext *_context;
  /** The cache under test. */
  GIDMDMPasscodeCache *_cache;
}

- (void)setUp {
  [super setUp];
  _context = [[GIDFakeLocalAuthenticationContext alloc] init];
  _cache = [[GIDMDMPasscodeCache alloc] initWithLocalAuthenticationContext:_context];
}

/**
 * Verifies the correct response when LocalAuthentication API returns without an error.
 */
- (void)testLocalAuthenticationNoError {
  _context.canEvaluatePolicyResult = YES;
  _context.canEvaluatePolicyError = nil;
  GIDMDMPasscodeState *passcodeState = [_cache passcodeState];
  XCTAssertEqualObjects(_context.evaluatedPolicies, @[ @(LAPolicyDeviceOwnerAuthentication) ]);
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
  NSString *fakeErrorDomain = @"asdf.hjkl";
  NSInteger fakeErrorCode = -12345;
  _context.canEvaluatePolicyResult = NO;
  _context.canEvaluatePolicyError = [NSError errorWithDomain:fakeErrorDomain
                                                        code:fakeErrorCode
                                                    userInfo:nil];
  GIDMDMPasscodeState *passcodeState = [_cache passcodeState];
  XCTAssertEqualObjects(_context.evaluatedPolicies, @[ @(LAPolicyDeviceOwnerAuthentication) ]);
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
  GIDMDMPasscodeState *oldPasscodeState = [_cache passcodeState];
  GIDMDMPasscodeState *newPasscodeState = [_cache passcodeState];
  XCTAssertEqual(_context.evaluatedPolicies.count, 1u);
  XCTAssertEqualObjects(oldPasscodeState.status, newPasscodeState.status);
  XCTAssertEqualObjects(oldPasscodeState.info, newPasscodeState.info);

  // Verify that the cache re-probes LocalAuthentication after the app enters the background.
  [self postApplicationDidEnterBackgroundNotification];
  [_cache passcodeState];
  XCTAssertEqual(_context.evaluatedPolicies.count, 2u);
}

/**
 * Verifies the presence of the result from Keychain API.
 * Keychain API is in C thus there is no easy way to swizzler them.
 */
- (void)testKeychain {
  GIDMDMPasscodeState *passcodeState = [_cache passcodeState];
  NSDictionary *dict = [self dictWithEncodedString:passcodeState.info];
  XCTAssertTrue([dict[@"Keychain"][@"result"] isKindOfClass:[NSNumber class]]);
}

/** Verifies `+[GIDMDMPasscodeState passcodeState]` returns a state with a status and info. */
- (void)testPasscodeStateClassMethod {
  GIDMDMPasscodeState *passcodeState = [GIDMDMPasscodeState passcodeState];
  XCTAssertNotNil(passcodeState.status);
  XCTAssertNotNil([self dictWithEncodedString:passcodeState.info]);
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
