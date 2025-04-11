// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GIDKeychainHelperFake.h"

static NSString *const kAccountName = @"OAuthTest";

@interface GIDKeychainHelperFake ()

@property(nonatomic, copy) NSMutableDictionary<NSString *, NSData *> *passwordStore;

@end

@implementation GIDKeychainHelperFake

- (instancetype)initWithKeychainAttributes:(NSSet<GTMKeychainAttribute *> *)keychainAttributes {
  self = [super init];
  if (self) {
    _keychainAttributes = keychainAttributes;
    _accountName = kAccountName;
  }
  return self;
}

- (NSDictionary<NSString *,id> * _Nonnull)keychainQueryForService:(NSString * _Nonnull)service { 
  [NSException raise:@"Not Implemented" format:@"This method is not implemented"];
}


- (NSData * _Nullable)passwordDataForService:(NSString * _Nonnull)service
                                       error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  if (service.length == 0) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                code:GTMKeychainStoreErrorCodeNoService
                            userInfo:nil];
    return;
  }
  
  NSString *passwordKey = [service stringByAppendingString:self.accountName];
  NSData *passwordData = self.passwordStore[passwordKey];
  if (!passwordData) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodePasswordNotFound
                             userInfo:nil];
    return;
  }
  
  return passwordData;
}

- (NSString * _Nullable)passwordForService:(NSString * _Nonnull)service
                                     error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  NSData *passwordData = [self passwordDataForService:service error:error];
  NSString *passwordString = [[NSString alloc] initWithData:passwordData
                                                   encoding:NSUTF8StringEncoding];
  return passwordString;
}

- (BOOL)removePasswordForService:(NSString * _Nonnull)service
                           error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  if (service.length == 0) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodeNoService
                             userInfo:nil];
    return;
  }
  
  NSString *passwordKey = [service stringByAppendingString:self.accountName];
  [self.passwordStore removeObjectForKey:passwordKey];
  return self.passwordStore[passwordKey] != nil;
}

- (BOOL)setPassword:(NSString * _Nonnull)password
         forService:(NSString * _Nonnull)service
      accessibility:(CFTypeRef _Nonnull)accessibility
              error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
  if (!passwordData) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodeUnexpectedPasswordData
                             userInfo:nil];
    return NO;
  }
  return [self setPasswordWithData:passwordData
                        forService:service
                     accessibility:accessibility
                             error:error];
}

- (BOOL)setPassword:(NSString * _Nonnull)password
         forService:(NSString * _Nonnull)service
              error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
  if (!passwordData) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodeUnexpectedPasswordData
                             userInfo:nil];
    return NO;
  }
  return [self setPasswordWithData:passwordData forService:service accessibility:nil error:error];
}

- (BOOL)setPasswordWithData:(NSData * _Nonnull)data
                 forService:(NSString * _Nonnull)service
              accessibility:(CFTypeRef _Nullable)accessibility
                      error:(NSError * _Nullable __autoreleasing * _Nullable)error {
  if (service.length == 0) {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodeNoService
                             userInfo:nil];
    return;
  }
  NSString *passwordKey = [service stringByAppendingString:self.accountName];
  [self.passwordStore setValue:data forKey:passwordKey];
  if (self.passwordStore[passwordKey] != nil) {
    return YES;
  } else {
    *error = [NSError errorWithDomain:@"GTMAppAuthKeychainErrorDomain"
                                 code:GTMKeychainStoreErrorCodeFailedToSetPassword
                             userInfo:nil];
    return NO;
  }
}

@end
