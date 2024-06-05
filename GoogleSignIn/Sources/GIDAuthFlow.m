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
#import "GoogleSignIn/Sources/GIDAuthFlow.h"

@implementation GIDAuthFlow

- (instancetype)initWithAuthState:(nullable OIDAuthState *)authState
                            error:(nullable NSError *)error
                       emmSupport:(nullable NSString *)emmSupport
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    _authState = authState;
    _error = error;
    _emmSupport = emmSupport;
    _profileData = profileData;
  }
  return self;
}

- (instancetype)init {
  return [self initWithAuthState:nil
                           error:nil
                      emmSupport:nil
                     profileData:nil];
}

@end
