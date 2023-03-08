/*
 * Copyright 2022 Google LLC
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

#import "GoogleSignIn/Sources/GIDEMMSupport.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";
static NSString *const kEMMOSVersionParameterName = @"device_os";
static NSString *const kEMMPasscodeInfoParameterName = @"emm_passcode_info";

// Old UIDevice system name for iOS.
static NSString *const kOldIOSSystemName = @"iPhone OS";

// New UIDevice system name for iOS.
static NSString *const kNewIOSSystemName = @"iOS";

// The error key in the server response.
static NSString *const kErrorKey = @"error";

// Error strings in the server response.
static NSString *const kGeneralErrorPrefix = @"emm_";
static NSString *const kScreenlockRequiredError = @"emm_passcode_required";
static NSString *const kAppVerificationRequiredErrorPrefix = @"emm_app_verification_required";

// Optional separator between error prefix and the payload.
static NSString *const kErrorPayloadSeparator = @":";

// A list for recognized error codes.
typedef enum {
  ErrorCodeNone = 0,
  ErrorCodeDeviceNotCompliant,
  ErrorCodeScreenlockRequired,
  ErrorCodeAppVerificationRequired,
} ErrorCode;

@implementation GIDEMMSupport

+ (nullable NSError *)handleTokenFetchEMMError:(nullable NSError *)error {
  NSDictionary *errorJSON = error.userInfo[OIDOAuthErrorResponseErrorKey];
  ErrorCode errorCode = ErrorCodeNone;

  if (errorJSON) {
    id errorValue = errorJSON[kErrorKey];
    if ([errorValue isEqual:kScreenlockRequiredError]) {
      errorCode = ErrorCodeScreenlockRequired;
    } else if ([errorValue hasPrefix:kAppVerificationRequiredErrorPrefix]) {
      errorCode = ErrorCodeAppVerificationRequired;
    } else if ([errorValue hasPrefix:kGeneralErrorPrefix]) {
      errorCode = ErrorCodeDeviceNotCompliant;
    }
  }

  if (errorCode) {
    return [NSError errorWithDomain:kGIDSignInErrorDomain
                               code:kGIDSignInErrorCodeEMM
                           userInfo:error.userInfo];
  } else {
    return error;
  }
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
  return [self parametersWithParameters:parameters
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

#pragma mark - GTMAuthSessionDelegate

- (nullable NSDictionary<NSString *,NSString *> *)
additionalTokenRefreshParametersForAuthSession:(GTMAuthSession *)authSession {
  return [GIDEMMSupport updatedEMMParametersWithParameters:
          authSession.authState.lastTokenResponse.additionalParameters];
}

- (nullable NSError *)updatedErrorForAuthSession:(GTMAuthSession *)authSession
                                   originalError:(NSError *)originalError {
  return [GIDEMMSupport handleTokenFetchEMMError:originalError];
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
