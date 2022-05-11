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

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Tests/Unit/GIDProfileData+Testing.h"

static const NSUInteger kDimension = 100;
static NSString *const kFIFEImageURL =
    @"https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/4252rscbv5M/photo.jpg";
static NSString *const kFIFEImageURLWithDimension =
    @"https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/4252rscbv5M/photo.jpg?sz=100";
static NSString *const kFIFEImageURL2 =
    @"https://lh3.googleusercontent.com/-sGxmwN8NbRA/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rd8EJb89PcveglTOdub_E1PO8ehJg/photo.jpg";
static NSString *const kFIFEImageURL2WithDimension =
    @"https://lh3.googleusercontent.com/-sGxmwN8NbRA/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rd8EJb89PcveglTOdub_E1PO8ehJg/photo.jpg?sz=100";
static NSString *const kFIFEAvatarURL =
    @"https://lh3.googleusercontent.com/a-/AAuE7mAWaTjIS4B9ojpOMNu247d6qO7LcH5teU0Idr5pK_E";
static NSString *const kFIFEAvatarURLWithDimension =
    @"https://lh3.googleusercontent.com/a-/AAuE7mAWaTjIS4B9ojpOMNu247d6qO7LcH5teU0Idr5pK_E=s100";
static NSString *const kFIFEAvatarURL2 =
    @"https://lh3.googleusercontent.com/a/default-user";
static NSString *const kFIFEAvatarURL2WithDimension =
    @"https://lh3.googleusercontent.com/a/default-user=s100";

@interface GIDProfileDataOld : NSObject <NSCoding, NSSecureCoding>
@end

@implementation GIDProfileDataOld {
  NSString *_email;
  NSString *_name;
  NSString *_imageURL;
}

- (instancetype)initWithEmail:(NSString *)email
                         name:(NSString *)name
                     imageURL:(NSString *)imageURL {
  self = [super init];
  if (self) {
    _email = [email copy];
    _name = [name copy];
    _imageURL = [imageURL copy];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_email forKey:@"email"];
  [encoder encodeObject:_name forKey:@"name"];
  [encoder encodeObject:_imageURL forKey:@"picture"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

@interface GIDProfileDataTest : XCTestCase
@end

@implementation GIDProfileDataTest

#pragma mark - Tests

- (void)testInitialization {
  GIDProfileData *profileData = [self profileData];
  XCTAssertEqualObjects(profileData.email, kEmail);
  XCTAssertEqualObjects(profileData.name, kName);
  XCTAssertEqualObjects(profileData.givenName, kGivenName);
  XCTAssertEqualObjects(profileData.familyName, kFamilyName);
  XCTAssertTrue(profileData.hasImage);
}

- (void)testCoding {
  if (@available(iOS 11, macOS 10.13, *)) {
    GIDProfileData *profileData = [self profileData];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profileData
                                         requiringSecureCoding:YES
                                                         error:nil];
    GIDProfileData *newProfileData = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDProfileData class]
                                                                       fromData:data
                                                                          error:nil];
    XCTAssertEqualObjects(profileData, newProfileData);
    XCTAssertTrue(GIDProfileData.supportsSecureCoding);
  } else {
    XCTSkip(@"Required API is not available for this test.");
  }
}

- (void)testOldArchiveFormat {
  if (@available(iOS 11, macOS 10.13, *)) {
    GIDProfileDataOld *oldProfile = [[GIDProfileDataOld alloc] initWithEmail:kEmail
                                                                        name:kName
                                                                    imageURL:kFIFEImageURL];
    [NSKeyedArchiver setClassName:@"GIDProfileData" forClass:[GIDProfileDataOld class]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldProfile
                                         requiringSecureCoding:YES
                                                         error:nil];

    GIDProfileData *profileData = [NSKeyedUnarchiver unarchivedObjectOfClass:[GIDProfileData class]
                                                                    fromData:data
                                                                       error:nil];
    XCTAssertEqualObjects(profileData.email, kEmail);
    XCTAssertEqualObjects(profileData.name, kName);
    XCTAssertNil(profileData.givenName);
    XCTAssertNil(profileData.familyName);
    XCTAssertTrue(profileData.hasImage);
    XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                          kFIFEImageURLWithDimension);
  } else {
    XCTSkip(@"Required API is not available for this test.");
  }
}

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

// Deprecated in iOS 13 and macOS 10.14
- (void)testLegacyCoding {
  GIDProfileData *profileData = [self profileData];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profileData];
  GIDProfileData *newProfileData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(profileData, newProfileData);
  XCTAssertTrue(GIDProfileData.supportsSecureCoding);
}

- (void)testOldArchiveFormatLegacy {
  GIDProfileDataOld *oldProfile = [[GIDProfileDataOld alloc] initWithEmail:kEmail
                                                                      name:kName
                                                                  imageURL:kFIFEImageURL];
  [NSKeyedArchiver setClassName:@"GIDProfileData" forClass:[GIDProfileDataOld class]];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oldProfile];
  GIDProfileData *profileData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(profileData.email, kEmail);
  XCTAssertEqualObjects(profileData.name, kName);
  XCTAssertNil(profileData.givenName);
  XCTAssertNil(profileData.familyName);
  XCTAssertTrue(profileData.hasImage);
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEImageURLWithDimension);
}

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

- (void)testImageURLWithDimension {
  GIDProfileData *profileData;
  // Test FIFE Image URLs
  profileData = [self profileDataWithImageURL:kFIFEImageURL];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEImageURLWithDimension);
  profileData = [self profileDataWithImageURL:kFIFEImageURL2];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEImageURL2WithDimension);
  // with preexisting options
  profileData = [self profileDataWithImageURL:kFIFEImageURLWithDimension];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEImageURLWithDimension);
  profileData = [self profileDataWithImageURL:kFIFEImageURL2WithDimension];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEImageURL2WithDimension);

  // Test FIFE Avatar URLs
  profileData = [self profileDataWithImageURL:kFIFEAvatarURL];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEAvatarURLWithDimension);
  profileData = [self profileDataWithImageURL:kFIFEAvatarURL2];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEAvatarURL2WithDimension);
  // with preexisting options
  profileData = [self profileDataWithImageURL:kFIFEAvatarURLWithDimension];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEAvatarURLWithDimension);
  profileData = [self profileDataWithImageURL:kFIFEAvatarURL2WithDimension];
  XCTAssertEqualObjects([profileData imageURLWithDimension:kDimension].absoluteString,
                        kFIFEAvatarURL2WithDimension);
}

#pragma mark - Helpers

- (GIDProfileData *)profileData {
  return [self profileDataWithImageURL:kFIFEImageURL];
}

- (GIDProfileData *)profileDataWithImageURL:(NSString *)imageURL {
  return [GIDProfileData testInstanceWithImageURL:imageURL];
}

@end
