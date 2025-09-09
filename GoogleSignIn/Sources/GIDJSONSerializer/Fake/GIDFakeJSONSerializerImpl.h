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

#import "GoogleSignIn/Sources/GIDJSONSerializer/API/GIDJSONSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/** A fake implementation of `GIDJSONSerializer` for testing purposes. */
@interface GIDFakeJSONSerializerImpl : NSObject <GIDJSONSerializer>

/**
 * An error to be returned by `stringWithJSONObject:error:`.
 *
 * If this property is set, `stringWithJSONObject:error:` will return `nil` and
 * populate the error parameter with this error.
 */
@property(nonatomic, nullable) NSError *serializationError;

/** The dictionary passed to the serialization method. */
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, id> *capturedJSONObject;

@end

NS_ASSUME_NONNULL_END
