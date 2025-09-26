// Copyright 2025 Google LLC
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

#import "GoogleSignIn/Sources/GIDJSONSerializer/Fake/GIDFakeJSONSerializerImpl.h"
#import "GoogleSignIn/Sources/GIDJSONSerializer/Implementation/GIDJSONSerializerImpl.h"
#import "GoogleSignIn/Sources/GIDClaimsInternalOptions.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDClaim.h"

static NSString *const kEssentialAuthTimeExpectedJSON = @"{\"id_token\":{\"auth_time\":{\"essential\":true}}}";
static NSString *const kNonEssentialAuthTimeExpectedJSON = @"{\"id_token\":{\"auth_time\":{\"essential\":false}}}";

@interface GIDClaimsInternalOptionsTest : XCTestCase

@property(nonatomic) GIDFakeJSONSerializerImpl *jsonSerializerFake;
@property(nonatomic) GIDClaimsInternalOptions *claimsInternalOptions;

@end

@implementation GIDClaimsInternalOptionsTest

- (void)setUp {
  [super setUp];
  _jsonSerializerFake = [[GIDFakeJSONSerializerImpl alloc] init];
  _claimsInternalOptions = [[GIDClaimsInternalOptions alloc] initWithJSONSerializer:_jsonSerializerFake];
}

- (void)tearDown {
  _jsonSerializerFake = nil;
  _claimsInternalOptions = nil;
  [super tearDown];
}

#pragma mark - Input Validation Tests

- (void)testValidatedJSONStringForClaims_WithNilInput_ShouldReturnNil {
  XCTAssertNil([_claimsInternalOptions validatedJSONStringForClaims:nil error:nil]);
}

- (void)testValidatedJSONStringForClaims_WithEmptyInput_ShouldReturnNil {
  XCTAssertNil([_claimsInternalOptions validatedJSONStringForClaims:[NSSet set] error:nil]);
}

#pragma mark - Correct Formatting Tests

- (void)testValidatedJSONStringForClaims_WithNonEssentialClaim_IsCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDClaim authTimeClaim]];
  NSError *error;
  NSString *result = [_claimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, kNonEssentialAuthTimeExpectedJSON);
}

- (void)testValidatedJSONStringForClaims_WithEssentialClaim_IsCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDClaim essentialAuthTimeClaim]];
  NSError *error;
  NSString *result = [_claimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, kEssentialAuthTimeExpectedJSON);
}

#pragma mark - Client Error Handling Tests

- (void)testValidatedJSONStringForClaims_WithConflictingClaims_ReturnsNilAndPopulatesError {
  NSSet *claims = [NSSet setWithObjects:[GIDClaim authTimeClaim],
                                        [GIDClaim essentialAuthTimeClaim],
                                        nil];
  NSError *error;
  NSString *result = [_claimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(result, @"Method should return nil for conflicting claims.");
  XCTAssertNotNil(error, @"An error object should be populated.");
  XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain, @"Error domain should be correct.");
  XCTAssertEqual(error.code, kGIDSignInErrorCodeAmbiguousClaims,
                 @"Error code should be for ambiguous claims.");
}

- (void)testValidatedJSONStringForClaims_WhenSerializationFails_ReturnsNilAndError {
  NSSet *claims = [NSSet setWithObject:[GIDClaim authTimeClaim]];
  NSError *expectedJSONError = [NSError errorWithDomain:kGIDSignInErrorDomain
                                                   code:kGIDSignInErrorCodeJSONSerializationFailure
                                               userInfo:@{
                                                 NSLocalizedDescriptionKey: kGIDJSONSerializationErrorDescription,
                                               }];
  _jsonSerializerFake.serializationError = expectedJSONError;
  NSError *actualError;
  NSString *result = [_claimsInternalOptions validatedJSONStringForClaims:claims
                                                                         error:&actualError];

  XCTAssertNil(result, @"The result should be nil when JSON serialization fails.");
  XCTAssertEqualObjects(
      actualError,
      expectedJSONError,
      @"The error from serialization should be passed back to the caller."
  );
}

@end
