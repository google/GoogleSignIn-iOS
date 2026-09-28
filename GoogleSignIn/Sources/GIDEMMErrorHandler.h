/*
 * Copyright 2021 Google LLC
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

NS_ASSUME_NONNULL_BEGIN

// The handler for displaying EMM-specific errors to users.
@interface GIDEMMErrorHandler : NSObject

// Retrieve the shared instance of this class.
+ (instancetype)sharedInstance;

// Handles EMM-specific errors in the server |response|. |completion| is always called
// exactly once. If |response| carries an EMM error and no EMM dialog is already pending,
// |completion| is called asynchronously on the main thread with |YES| — after the user
// dismisses the remediation dialog, or immediately if no dialog could be presented.
// Otherwise |completion| is called with |NO| before this method returns.
- (void)handleErrorFromResponse:(NSDictionary<NSString *, id> *)response
                     completion:(void (^)(BOOL handled))completion;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
