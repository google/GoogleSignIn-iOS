#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"

@interface GIDVerifiableAccountDetailTests : XCTestCase
@end

@implementation GIDVerifiableAccountDetailTests

- (void)testDesignatedInitializer {
  GIDVerifiableAccountDetail *detail = [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];
  XCTAssertNotNil(detail);
  XCTAssertEqual(detail.accountDetailType, GIDAccountDetailTypeAgeOver18);
}

- (void)testScopeRetrieval {
  GIDVerifiableAccountDetail *detail = [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];
  NSString *retrievedScope = [detail retrieveScope];
  NSString *expectedScope = @"https://www.googleapis.com/auth/verified.age.over18.standard";
  XCTAssertEqualObjects(retrievedScope, expectedScope);
}

@end
