//
//  GIDTokenClaimsInternalOptionsTest.h
//  GoogleSignIn
//
//  Created by Akshat Gandhi on 9/5/25.
//


#import <XCTest/XCTest.h>
#import "GoogleSignIn/Sources/GIDTokenClaimsInternalOptions.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDTokenClaim.h"

@import OCMock;

static NSString *const kEssentialAuthTimeExpectedJSON = @"{\"id_token\":{\"auth_time\":{\"essential\":true}}}";
static NSString *const kNonEssentialAuthTimeExpectedJSON = @"{\"id_token\":{\"auth_time\":null}}";


@interface GIDTokenClaimsInternalOptionsTest : XCTestCase
@end

@implementation GIDTokenClaimsInternalOptionsTest

#pragma mark - Input Validation Tests

- (void)testValidatedJSONStringForClaims_WithNilInput_ShouldReturnNil {
  XCTAssertNil([GIDTokenClaimsInternalOptions validatedJSONStringForClaims:nil error:nil]);
}

- (void)testValidatedJSONStringForClaims_WithEmptyInput_ShouldReturnNil {
  XCTAssertNil([GIDTokenClaimsInternalOptions validatedJSONStringForClaims:[NSSet set] error:nil]);
}

#pragma mark - Correct Formatting Tests

- (void)testValidatedJSONStringForClaims_WithNonEssentialClaim_IsCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim authTimeClaim]];

  NSError *error = nil;
  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, kNonEssentialAuthTimeExpectedJSON);
}

- (void)testValidatedJSONStringForClaims_WithEssentialClaim_IsCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim essentialAuthTimeClaim]];

  NSError *error = nil;
  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, kEssentialAuthTimeExpectedJSON);
}

#pragma mark - Client Error Handling Tests

- (void)testValidatedJSONStringForClaims_WithConflictingClaims_ReturnsNilAndPopulatesError {
  NSSet *claims = [NSSet setWithObjects:[GIDTokenClaim authTimeClaim],
                                        [GIDTokenClaim essentialAuthTimeClaim],
                                        nil];
  NSError *error = nil;

  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(result, @"Method should return nil for conflicting claims.");
  XCTAssertNotNil(error, @"An error object should be populated.");
  XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain, @"Error domain should be correct.");
  XCTAssertEqual(error.code, kGIDSignInErrorCodeAmbiguousClaims, @"Error code should be for ambiguous claims.");
}

- (void)testValidatedJSONStringForClaims_WhenSerializationFails_ReturnsNilAndError {
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim authTimeClaim]];
  NSError *fakeJSONError = [NSError errorWithDomain:@"com.fake.json" code:-999 userInfo:nil];
  id mockSerialization = OCMClassMock([NSJSONSerialization class]);

  OCMStub([mockSerialization dataWithJSONObject:OCMOCK_ANY
                                         options:0
                                           error:[OCMArg setTo:fakeJSONError]]).andReturn(nil);

  NSError *actualError = nil;
  NSString *result =
      [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&actualError];

  XCTAssertNil(result, @"The result should be nil when JSON serialization fails.");
  XCTAssertEqualObjects(actualError, fakeJSONError,
                        @"The error from serialization should be passed back to the caller.");

  [mockSerialization stopMocking];
}

@end
