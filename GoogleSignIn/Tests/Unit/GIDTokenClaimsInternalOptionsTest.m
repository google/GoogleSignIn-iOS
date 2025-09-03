#import <XCTest/XCTest.h>
#import "GoogleSignIn/Sources/GIDTokenClaimsInternalOptions.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDTokenClaim.h"

@import OCMock;


@interface GIDTokenClaimsInternalOptionsTest : XCTestCase
@end

@implementation GIDTokenClaimsInternalOptionsTest

#pragma mark - Input Validation Tests

- (void)testValidatedJSONStringForClaims_withNilInput_shouldReturnNil {
  XCTAssertNil([GIDTokenClaimsInternalOptions validatedJSONStringForClaims:nil error:nil]);
}

- (void)testValidatedJSONStringForClaims_withEmptyInput_shouldReturnNil {
  XCTAssertNil([GIDTokenClaimsInternalOptions validatedJSONStringForClaims:[NSSet set] error:nil]);
}

#pragma mark - Correct Formatting Tests

- (void)testValidatedJSONStringForClaims_withSingleNonEssentialClaim_isCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim authTimeClaim]];
  NSString *expectedJSON = @"{\"id_token\":{\"auth_time\":null}}";

  NSError *error = nil;
  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, expectedJSON);
}

- (void)testValidatedJSONStringForClaims_withSingleEssentialClaim_isCorrectlyFormatted {
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim essentialAuthTimeClaim]];
  NSString *expectedJSON = @"{\"id_token\":{\"auth_time\":{\"essential\":true}}}";

  NSError *error = nil;
  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(result, expectedJSON);
}

#pragma mark - Client Error Handling Tests

- (void)testValidatedJSONStringForClaims_withConflictingClaims_returnsNilAndPopulatesError {
  // Arrange
  NSSet *claims = [NSSet setWithObjects:[GIDTokenClaim authTimeClaim],
                                        [GIDTokenClaim essentialAuthTimeClaim],
                                        nil];
  NSError *error = nil;

  // Act
  NSString *result = [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&error];

  // Assert
  XCTAssertNil(result, @"Method should return nil for conflicting claims.");
  XCTAssertNotNil(error, @"An error object should be populated.");
  XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain, @"Error domain should be correct.");
  XCTAssertEqual(error.code, kGIDSignInErrorCodeAmbiguousClaims, @"Error code should be for ambiguous claims.");
}

- (void)testValidatedJSONStringForClaims_whenSerializationFails_returnsNilAndError {
  // 1. Arrange
  NSSet *claims = [NSSet setWithObject:[GIDTokenClaim authTimeClaim]];
  NSError *fakeJSONError = [NSError errorWithDomain:@"com.fake.json" code:-999 userInfo:nil];
  id mockSerialization = OCMClassMock([NSJSONSerialization class]);

  OCMStub([mockSerialization dataWithJSONObject:OCMOCK_ANY
                                         options:0
                                           error:[OCMArg setTo:fakeJSONError]]).andReturn(nil);

  // 2. Act
  NSError *actualError = nil;
  NSString *result =
      [GIDTokenClaimsInternalOptions validatedJSONStringForClaims:claims error:&actualError];

  // 3. Assert
  XCTAssertNil(result, @"The result should be nil when JSON serialization fails.");
  XCTAssertEqualObjects(actualError, fakeJSONError,
                        @"The error from serialization should be passed back to the caller.");

  [mockSerialization stopMocking];
}

@end
