/*
 * Copyright 2023 Google LLC
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
@class FIRAppCheckToken;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@interface GIDAppCheck : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (void)prepareForAppAttest;
- (void)getLimitedUseTokenWithCompletion:(nullable void (^)(FIRAppCheckToken * _Nullable token,
                                                            NSError * _Nullable error))completion;

@property(class, nonatomic, strong, readonly) GIDAppCheck *sharedInstance;
@property(nonatomic, readonly, getter=isPrepared) BOOL prepared;

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END

