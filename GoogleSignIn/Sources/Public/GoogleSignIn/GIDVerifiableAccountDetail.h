/*
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An enumeration defining the types of account details Google can verify.
typedef NS_ENUM(NSInteger, GIDAccountDetailType) {
  /// User account detail for age over 18.
  GIDAccountDetailTypeAgeOver18,
};

/// String scope representing the account detail type for age over 18.
extern NSString *const kAccountDetailTypeAgeOver18Scope;

/// Helper object used to hold the enumeration representing a list of
/// account details that Google can verify via GSI.
@interface GIDVerifiableAccountDetail : NSObject

/// The type of account detail that will be verified.
@property(nonatomic, readonly) GIDAccountDetailType accountDetailType;

/// Initializes a new GIDVerifiableAccountDetail object with the given
/// account detail type.
///
/// @param accountDetailType The type of account detail that will be verified.
- (instancetype)initWithAccountDetailType:(GIDAccountDetailType)accountDetailType;

/// Retrieves the scope required to verify the account detail.
///
/// @return A string representing the scope required to verify the account detail.
- (nullable NSString *)scope;

@end

NS_ASSUME_NONNULL_END
