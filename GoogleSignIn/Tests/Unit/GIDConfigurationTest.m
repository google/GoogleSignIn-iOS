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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

@interface GIDConfigurationTest : XCTestCase
@end

@implementation GIDConfigurationTest

#pragma mark - Tests

- (void)testClientIDInitializer {
  GIDConfiguration *configuration =
      [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID];
  XCTAssertEqualObjects(configuration.clientID, OIDAuthorizationRequestTestingClientID);
  XCTAssertNil(configuration.serverClientID);
  XCTAssertNil(configuration.hostedDomain);
  XCTAssertNil(configuration.openIDRealm);
}

- (void)testClientIDServerIDInitializer {
  GIDConfiguration *configuration =
      [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                  serverClientID:kServerClientID];
  XCTAssertEqualObjects(configuration.clientID, OIDAuthorizationRequestTestingClientID);
  XCTAssertEqualObjects(configuration.serverClientID, kServerClientID);
  XCTAssertNil(configuration.hostedDomain);
  XCTAssertNil(configuration.openIDRealm);
}

- (void)testFullInitializer {
  GIDConfiguration *configuration = [GIDConfiguration testInstance];
  XCTAssertEqualObjects(configuration.clientID, OIDAuthorizationRequestTestingClientID);
  XCTAssertEqualObjects(configuration.serverClientID, kServerClientID);
  XCTAssertEqualObjects(configuration.hostedDomain, kHostedDomain);
  XCTAssertEqualObjects(configuration.openIDRealm, kOpenIDRealm);
}

- (void)testDescription {
  GIDConfiguration *configuration = [GIDConfiguration testInstance];
  NSString *propertyString = @"";
  unsigned int outCount, c;
  objc_property_t *properties = class_copyPropertyList([configuration class], &outCount);
  NSString *propertyName;
  for (c = 0; c < outCount; c++) {
    propertyName = [NSString stringWithUTF8String:property_getName(properties[c])];
    propertyString = [propertyString stringByAppendingFormat:@", %@: %@",
        propertyName, [configuration valueForKey:propertyName]];
  }
  NSString *expectedDescription =
      [NSString stringWithFormat:@"<GIDConfiguration: %p%@>", configuration, propertyString];

  XCTAssertEqualObjects(configuration.description, expectedDescription);
}

- (void)testCopying {
  GIDConfiguration *configuration = [GIDConfiguration testInstance];
  GIDConfiguration *copiedConfiguration = [configuration copy];
  // Should be the same object.
  XCTAssertEqual(configuration, copiedConfiguration);
}

- (void)testCoding {
  if (@available(iOS 11, macOS 10.13, *)) {
    GIDConfiguration *configuration = [GIDConfiguration testInstance];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:configuration
                                         requiringSecureCoding:YES
                                                         error:nil];
    GIDConfiguration *newConfiguration = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDConfiguration class]
                                                                           fromData:data
                                                                              error:nil];
    XCTAssertEqualObjects(configuration, newConfiguration);
    XCTAssertTrue(GIDConfiguration.supportsSecureCoding);
  }  else {
    XCTSkip(@"Required API is not available for this test.");
  }
}

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
// Deprecated in iOS 13 and macOS 10.14
- (void)testLegacyCoding {
  GIDConfiguration *configuration = [GIDConfiguration testInstance];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:configuration];
  GIDConfiguration *newConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(configuration, newConfiguration);
  XCTAssertTrue(GIDConfiguration.supportsSecureCoding);
}
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

@end
