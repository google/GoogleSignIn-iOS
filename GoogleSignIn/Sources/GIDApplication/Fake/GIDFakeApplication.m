/*
 * Copyright 2026 Google LLC
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

#import "GoogleSignIn/Sources/GIDApplication/Fake/GIDFakeApplication.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDFakeApplication {
  NSMutableArray<NSURL *> *_openedURLs;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _openedURLs = [NSMutableArray array];
  }
  return self;
}

- (NSArray<NSURL *> *)openedURLs {
  return [_openedURLs copy];
}

- (void)openURL:(NSURL *)url {
  [_openedURLs addObject:url];
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
