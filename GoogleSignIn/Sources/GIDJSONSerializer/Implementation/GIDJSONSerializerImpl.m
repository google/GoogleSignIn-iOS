/*
 * Copyright 2025 Google LLC
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

#import "GoogleSignIn/Sources/GIDJSONSerializer/Implementation/GIDJSONSerializerImpl.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

NSString * const kGIDJSONSerializationErrorDescription =
    @"The provided object could not be serialized to a JSON string.";

@implementation GIDJSONSerializerImpl

- (nullable NSString *)stringWithJSONObject:(NSDictionary<NSString *, id> *)jsonObject
                                      error:(NSError *_Nullable *_Nullable)error {
  NSError *serializationError;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                     options:0
                                                       error:&serializationError];
  if (!jsonData) {
    if (error) {
      *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                   code:kGIDSignInErrorCodeJSONSerializationFailure
                               userInfo:@{
                            NSLocalizedDescriptionKey:kGIDJSONSerializationErrorDescription,
                                 NSUnderlyingErrorKey:serializationError
                               }];
    }
    return nil;
  }
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
