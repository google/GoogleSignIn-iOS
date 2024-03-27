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
  NSString *retrievedScope = [detail scope];
  XCTAssertEqualObjects(retrievedScope, kAccountDetailTypeAgeOver18Scope);
}

- (void)testScopeRetrieval_MissingScope {
  NSInteger missingScope = 5;
  GIDVerifiableAccountDetail *detail = [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:missingScope];
  NSString *retrievedScope = [detail scope];
  XCTAssertNil(retrievedScope);
}

@end
