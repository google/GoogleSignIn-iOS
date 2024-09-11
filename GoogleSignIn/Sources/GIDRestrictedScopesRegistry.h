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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

/// A registry to manage restricted scopes and their associated handling classes to track scopes
/// that require separate flows within an application.
@interface GIDRestrictedScopesRegistry : NSObject

/// A set of strings representing the restricted scopes.
@property (nonatomic, strong, readonly) NSSet<NSString *> *restrictedScopes;

/// A dictionary mapping restricted scopes to their corresponding handling classes.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, Class> *scopeToClassMapping;

/// This designated initializer sets up the initial restricted scopes and their corresponding handling classes.
///
/// @return An initialized `GIDRestrictedScopesRegistry` instance
- (instancetype)init;

/// Checks if a given scope is restricted.
///
/// @param scope The scope to check.
/// @return YES if the scope is restricted; otherwise, NO.
- (BOOL)isScopeRestricted:(NSString *)scope;

/// Retrieves a dictionary mapping restricted scopes to their handling classes within a given set of scopes.
///
/// @param scopes A set of scopes to lookup their handling class.
/// @return A dictionary where restricted scopes found in the input set are mapped to their corresponding handling classes.
///     If no restricted scopes are found, an empty dictionary is returned.
- (NSDictionary<NSString *, Class> *)restrictedScopesToClassMappingInSet:(NSSet<NSString *> *)scopes;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
