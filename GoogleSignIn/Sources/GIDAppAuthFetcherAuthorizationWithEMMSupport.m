// Copyright 2022 Google LLC
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDAppAuthFetcherAuthorizationWithEMMSupport.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";
static NSString *const kEMMOSVersionParameterName = @"device_os";
static NSString *const kEMMPasscodeInfoParameterName = @"emm_passcode_info";

// Old UIDevice system name for iOS.
static NSString *const kOldIOSSystemName = @"iPhone OS";

// New UIDevice system name for iOS.
static NSString *const kNewIOSSystemName = @"iOS";

NS_ASSUME_NONNULL_BEGIN

// The specialized GTMAppAuthFetcherAuthorization delegate that handles potential EMM error
// responses.
@interface GTMAppAuthFetcherAuthorizationEMMChainedDelegate : NSObject

// Initializes with chained delegate and selector.
- (instancetype)initWithDelegate:(id)delegate selector:(SEL)selector;

// The callback method for GTMAppAuthFetcherAuthorization to invoke.
- (void)authentication:(GTMAppAuthFetcherAuthorization *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(nullable NSError *)error;

@end

@implementation GTMAppAuthFetcherAuthorizationEMMChainedDelegate {
  // We use a weak reference here to match GTMAppAuthFetcherAuthorization.
  __weak id _delegate;
  SEL _selector;
  // We need to maintain a reference to the chained delegate because GTMAppAuthFetcherAuthorization
  // only keeps a weak reference.
  GTMAppAuthFetcherAuthorizationEMMChainedDelegate *_retained_self;
}

- (instancetype)initWithDelegate:(id)delegate selector:(SEL)selector {
  self = [super init];
  if (self) {
    _delegate = delegate;
    _selector = selector;
    _retained_self = self;
  }
  return self;
}

- (void)authentication:(GTMAppAuthFetcherAuthorization *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(nullable NSError *)error {
  [GIDAppAuthFetcherAuthorizationWithEMMSupport handleTokenFetchEMMError:error
                                                              completion:^(NSError *_Nullable error) {
    if (!self->_delegate || !self->_selector) {
      return;
    }
    NSMethodSignature *signature = [self->_delegate methodSignatureForSelector:self->_selector];
    if (!signature) {
      return;
    }
    id argument1 = auth;
    id argument2 = request;
    id argument3 = error;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self->_delegate];  // index 0
    [invocation setSelector:self->_selector];  // index 1
    [invocation setArgument:&argument1 atIndex:2];
    [invocation setArgument:&argument2 atIndex:3];
    [invocation setArgument:&argument3 atIndex:4];
    [invocation invoke];
  }];
  // Prepare to deallocate the chained delegate instance because the above block will retain the
  // iVar references it uses.
  _retained_self = nil;
}

@end

@implementation GIDAppAuthFetcherAuthorizationWithEMMSupport

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel {
#pragma clang diagnostic pop
  GTMAppAuthFetcherAuthorizationEMMChainedDelegate *chainedDelegate =
      [[GTMAppAuthFetcherAuthorizationEMMChainedDelegate alloc] initWithDelegate:delegate
                                                                        selector:sel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [super authorizeRequest:request
                 delegate:chainedDelegate
        didFinishSelector:@selector(authentication:request:finishedWithError:)];
#pragma clang diagnostic pop
}

- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
       completionHandler:(GTMAppAuthFetcherAuthorizationCompletion)handler {
  [super authorizeRequest:request completionHandler:^(NSError *_Nullable error) {
    [[self class] handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      handler(error);
    }];
  }];
}

+ (void)handleTokenFetchEMMError:(nullable NSError *)error
                      completion:(void (^)(NSError *_Nullable))completion {
  NSDictionary *errorJSON = error.userInfo[OIDOAuthErrorResponseErrorKey];
  if (errorJSON) {
    __block BOOL handled = NO;
    handled = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:errorJSON
                                                                completion:^() {
      if (handled) {
        completion([NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeEMM
                                   userInfo:error.userInfo]);
      } else {
        completion(error);
      }
    }];
  } else {
    completion(error);
  }
}

+ (NSDictionary *)updatedEMMParametersWithParameters:(NSDictionary *)parameters {
  return [[self class] parametersWithParameters:parameters
                                     emmSupport:parameters[kEMMSupportParameterName]
                         isPasscodeInfoRequired:parameters[kEMMPasscodeInfoParameterName] != nil];
}


+ (NSDictionary *)parametersWithParameters:(NSDictionary *)parameters
                                emmSupport:(nullable NSString *)emmSupport
                    isPasscodeInfoRequired:(BOOL)isPasscodeInfoRequired {
  if (!emmSupport) {
    return parameters;
  }
  NSMutableDictionary *allParameters = [(parameters ?: @{}) mutableCopy];
  allParameters[kEMMSupportParameterName] = emmSupport;
  UIDevice *device = [UIDevice currentDevice];
  NSString *systemName = device.systemName;
  if ([systemName isEqualToString:kOldIOSSystemName]) {
    systemName = kNewIOSSystemName;
  }
  allParameters[kEMMOSVersionParameterName] =
      [NSString stringWithFormat:@"%@ %@", systemName, device.systemVersion];
  if (isPasscodeInfoRequired) {
    allParameters[kEMMPasscodeInfoParameterName] = [GIDMDMPasscodeState passcodeState].info;
  }
  return allParameters;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
