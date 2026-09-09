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

// Handles EMM specific error that is returned in server response.
// Returns whether an EMM-specific error is being handled by this invocation.
// When the return value is |YES|, |completion| is called asynchronously on the main thread —
// normally after the user dismisses the remediation dialog, but immediately if no dialog
// could be presented — and is passed |YES|. When the return value is |NO|, |completion| is
// called before returning and is passed |NO|. So the |BOOL| the completion receives always
// matches the method's return value.
- (BOOL)handleErrorFromResponse:(NSDictionary<NSString *, id> *)response
                     completion:(void (^)(BOOL handled))completion;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
