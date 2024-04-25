#import <XCTest/XCTest.h>

#if TARGET_OS_IOS
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

#import "GoogleSignIn/Tests/Unit/GIDFakeMainBundle.h"

static NSString * const kClientId = @"FakeClientID";

@interface GIDVerifyAccountDetailTests : XCTestCase {
@private
  // Mock |UIViewController|.
  UIViewController *_presentingViewController;

  // Fake [NSBundle mainBundle];
  GIDFakeMainBundle *_fakeMainBundle;

  // The |GIDVerifyAccountDetail| object being tested.
  GIDVerifyAccountDetail *_verifyAccountDetail;

  // [comment]
  NSArray<GIDVerifiableAccountDetail *> *_verifiableAccountDetails;

  GIDConfiguration *_configuration;
}
@end

@implementation GIDVerifyAccountDetailTests

#pragma mark - Lifecycle

- (void)setUp {
  [super setUp];

  _presentingViewController = [[UIViewController alloc] init];

//  _verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];
  _verifyAccountDetail = [[GIDVerifyAccountDetail alloc] init];

  GIDVerifiableAccountDetail *ageOver18Detail = [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:GIDAccountDetailTypeAgeOver18];
  _verifiableAccountDetails = @[ageOver18Detail];

  _fakeMainBundle = [[GIDFakeMainBundle alloc] init];
  [_fakeMainBundle startFakingWithClientID:kClientId];
  [_fakeMainBundle fakeAllSchemesSupported];
}


#pragma mark - Tests

- (void)testPresentingViewControllerException {
  _presentingViewController = nil;

  XCTAssertThrows([_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                                    presentingViewController:_presentingViewController
                                                  completion:nil]);
}

- (void)testClientIDMissingException {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
 _verifyAccountDetail.configuration = [[GIDConfiguration alloc] initWithClientID:nil];
#pragma GCC diagnostic pop
 BOOL threw = NO;
 @try {
   [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                     presentingViewController:_presentingViewController
                                   completion:nil];
 } @catch (NSException *exception) {
   threw = YES;
   XCTAssertEqualObjects(exception.description,
                         @"You must specify |clientID| in |GIDConfiguration|");
 } @finally {
 }
 XCTAssert(threw);
}

- (void)testSchemesNotSupportedException {
  [_fakeMainBundle fakeMissingAllSchemes];
  BOOL threw = NO;
  @try {
    [_verifyAccountDetail verifyAccountDetails:_verifiableAccountDetails
                      presentingViewController:_presentingViewController
                                    completion:nil];
  } @catch (NSException *exception) {
    threw = YES;
    XCTAssertEqualObjects(exception.description,
                          @"Your app is missing support for the following URL schemes: "
                          "fakeclientid");
  } @finally {
  }
  XCTAssert(threw);
}

@end

#endif // TARGET_OS_IOS
