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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDScopes.h"

// Scope constants.
static NSString *const kProfile = @"profile";
static NSString *const kUserinfoProfile = @"https://www.googleapis.com/auth/userinfo.profile";
static NSString *const kEmail = @"email";
static NSString *const kUserinfoEmail = @"https://www.googleapis.com/auth/userinfo.email";
static NSString *const kDriveScope = @"https://www.googleapis.com/auth/drive";

@interface GIDScopesTest : XCTestCase
@end

@implementation GIDScopesTest

- (void)testScopesWithBasicProfile_NoChange {
  XCTAssertEqualObjects([GIDScopes scopesWithBasicProfile:(@[ kProfile, kEmail])],
                        (@[ kProfile, kEmail]));
}

- (void)testScopesWithBasicProfile_NoChangeOldScopes {
  XCTAssertEqualObjects([GIDScopes scopesWithBasicProfile:(@[ kUserinfoProfile, kUserinfoEmail])],
                        (@[ kUserinfoProfile, kUserinfoEmail]));
}

- (void)testScopesWithBasicProfile_AddScope {
  XCTAssertEqualObjects([GIDScopes scopesWithBasicProfile:(@[ kDriveScope ])],
                        (@[ kDriveScope, kEmail, kProfile ]));
}

@end
