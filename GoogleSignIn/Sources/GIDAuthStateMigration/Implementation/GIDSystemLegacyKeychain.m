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

#import "GoogleSignIn/Sources/GIDAuthStateMigration/Implementation/GIDSystemLegacyKeychain.h"

#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

// Keychain account used to store additional state in SDKs previous to v5, including GPPSignIn.
static NSString *const kOldKeychainAccount = @"GooglePlus";

// The value used for the kSecAttrGeneric key by GTMAppAuth and GTMOAuth2.
static NSString *const kGenericAttribute = @"OAuth";

@implementation GIDSystemLegacyKeychain

- (nullable NSString *)passwordForService:(NSString *)service {
  if (!service.length) {
    return nil;
  }
  CFDataRef result = NULL;
  NSDictionary<id, id> *query = @{
    (id)kSecClass : (id)kSecClassGenericPassword,
    (id)kSecAttrGeneric : kGenericAttribute,
    (id)kSecAttrAccount : kOldKeychainAccount,
    (id)kSecAttrService : service,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne,
  };
  OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
  NSData *passwordData;
  if (status == noErr && [(__bridge NSData *)result length] > 0) {
    passwordData = [(__bridge NSData *)result copy];
  }
  if (result != NULL) {
    CFRelease(result);
  }
  if (!passwordData) {
    return nil;
  }
  NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
  return password;
}

@end

NS_ASSUME_NONNULL_END
