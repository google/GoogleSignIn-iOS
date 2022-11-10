// Copyright 2022 Google LLC
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
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDToken.h"

#import "GoogleSignIn/Sources/GIDToken_Private.h"

static NSString * const tokenString = @"tokenString";
static NSString * const tokenString2 = @"tokenString2";

@interface GIDTokenTest : XCTestCase {
  NSDate *_date;
}
@end

@implementation GIDTokenTest

- (void)setUp {
  [super setUp];
  _date = [[NSDate alloc]initWithTimeIntervalSince1970:1000];
}

- (void)testInitializer {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  XCTAssertEqualObjects(token.tokenString, tokenString);
  XCTAssertEqualObjects(token.expirationDate, _date);
}

- (void)testTokensWithSameTokenStringAndExpirationDateAreEqual {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  GIDToken *token2 = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  XCTAssertEqualObjects(token, token2);
}

- (void)testEqualTokensHaveTheSameHash {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  GIDToken *token2 = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  XCTAssertEqualObjects(token, token2);
  XCTAssertEqual(token.hash, token2.hash);
}

- (void)testTokensWithDifferentTokenStringsAreNotEqual {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  GIDToken *token2 = [[GIDToken alloc]initWithTokenString:tokenString2 expirationDate:_date];
  XCTAssertNotEqualObjects(token, token2);
}

- (void)testTokensWithSameTokenStringAndNoExpirationDateAreEqual {
  GIDToken *refreshToken = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:nil];
  GIDToken *refreshToken2 = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:nil];
  XCTAssertEqualObjects(refreshToken, refreshToken2);
}

- (void)testTokensWithSameTokenStringAndDifferentExpirationDateAreNotEqual {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  NSDate *date2 = [[NSDate alloc]initWithTimeIntervalSince1970:2000];
  GIDToken *token2 = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:date2];
  XCTAssertNotEqualObjects(token, token2);
}

- (void)testTokensWithSameTokenStringAndOneHasNoExpirationDateAreNotEqual {
  GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
  GIDToken *token2 = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:nil];
  XCTAssertNotEqualObjects(token, token2);
}
  
- (void)testCoding {
  if (@available(iOS 11, macOS 10.13, *)) {
    GIDToken *token = [[GIDToken alloc]initWithTokenString:tokenString expirationDate:_date];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:token requiringSecureCoding:YES error:nil];
    GIDToken *newToken = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDToken class]
                                                           fromData:data
                                                              error:nil];
    XCTAssertEqualObjects(token, newToken);
    
    XCTAssertTrue([GIDToken supportsSecureCoding]);
  } else {
    XCTSkip(@"Required API is not available for this test.");
  }
}
  
@end
