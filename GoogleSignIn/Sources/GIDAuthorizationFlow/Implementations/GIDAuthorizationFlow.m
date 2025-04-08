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

#import "GIDAuthorizationFlow.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Operations/GIDSaveAuthOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Operations/GIDTokenFetchOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Operations/GIDDecodeIDTokenOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Operations/GIDAuthorizationCompletionOperation.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

@interface GIDAuthorizationFlow ()

@property(nonatomic) BOOL restarting;

@end

@implementation GIDAuthorizationFlow

- (instancetype)initWithSignInOptions:(GIDSignInInternalOptions *)options
                            authState:(OIDAuthState *)authState
                          profileData:(nullable GIDProfileData *)profileData
                           googleUser:(nullable GIDGoogleUser *)googleUser
             externalUserAgentSession:(nullable id<OIDExternalUserAgentSession>)userAgentSession
                           emmSupport:(nullable NSString *)emmSupport
                                error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _options = options;
    _authState = authState;
    _profileData = profileData;
    _googleUser = googleUser;
    _currentUserAgentSession = userAgentSession;
    _error = error;
    _emmSupport = emmSupport;
  }
  return self;
}

#pragma mark - Authorize

- (void)authorize {
  GIDTokenFetchOperation *tokenFetch =
    [[GIDTokenFetchOperation alloc] initWithAuthState:self.authState
                                              options:self.options
                                           emmSupport:self.emmSupport
                                                error:self.error];
  GIDDecodeIDTokenOperation *idToken = [[GIDDecodeIDTokenOperation alloc] init];
  [idToken addDependency:tokenFetch];
  GIDSaveAuthOperation *saveAuth = [[GIDSaveAuthOperation alloc] init];
  [saveAuth addDependency:idToken];
  GIDAuthorizationCompletionOperation *authCompletion =
  [[GIDAuthorizationCompletionOperation alloc] initWithAuthorizationFlow:self];
  
  NSArray<NSOperation *> *operations = @[tokenFetch, idToken, saveAuth, authCompletion];
  [NSOperationQueue.mainQueue addOperations:operations waitUntilFinished:NO];
}

- (void)authorizeInteractively {
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX
  
  [self authorizationRequestWithOptions:self.options
                             completion:^(OIDAuthorizationRequest * _Nullable request,
                                          NSError * _Nullable error) {
    self->_currentUserAgentSession =
    [OIDAuthorizationService presentAuthorizationRequest:request
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                presentingViewController:self.options.presentingViewController
#elif TARGET_OS_OSX
                                        presentingWindow:options.presentingWindow
#endif // TARGET_OS_OSX
                                                callback:
     ^(OIDAuthorizationResponse *_Nullable authorizationResponse,
       NSError *_Nullable error) {
      [self processAuthorizationResponse:authorizationResponse
                                   error:error
                              emmSupport:emmSupport];
    }];
  }];
}

#pragma mark - Authorization Request

- (void)authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
                             completion:
(void (^)(OIDAuthorizationRequest *_Nullable request, NSError *_Nullable error))completion {
  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
    [self additionalParametersFromOptions:options];
  OIDAuthorizationRequest *request = [self authorizationRequestWithOptions:options
                                                      additionalParameters:additionalParameters];
  // TODO: Add app check steps as well
  completion(request, nil);
}

- (OIDAuthorizationRequest *)
authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
additionalParameters:(NSDictionary<NSString *, NSString *> *)additionalParameters {
  OIDAuthorizationRequest *request;
  if (options.nonce) {
    request = [[OIDAuthorizationRequest alloc] initWithConfiguration:self.serviceConfiguration
                                                            clientId:options.configuration.clientID
                                                              scopes:options.scopes
                                                         redirectURL:[self redirectURLWithOptions:options]
                                                        responseType:OIDResponseTypeCode
                                                               nonce:options.nonce
                                                additionalParameters:additionalParameters];
  } else {
    request = [[OIDAuthorizationRequest alloc] initWithConfiguration:self.serviceConfiguration
                                                            clientId:options.configuration.clientID
                                                              scopes:options.scopes
                                                         redirectURL:[self redirectURLWithOptions:options]
                                                        responseType:OIDResponseTypeCode
                                                additionalParameters:additionalParameters];
  }
  return request;
}

#pragma mark - Authorization Response

- (void)processAuthorizationResponse:(nullable OIDAuthorizationResponse *)authorizationResponse
                               error:(nullable NSError *)error
                          emmSupport:(nullable NSString *)emmSupport {
  if (self.restarting) {
    // The auth flow is restarting, so the work here would be performed in the next round.
    self.restarting = NO;
    return;
  }
  
  self.emmSupport = emmSupport;
  
  if (authorizationResponse) {
    if (authorizationResponse.authorizationCode.length) {
      self.authState = [[OIDAuthState alloc] initWithAuthorizationResponse:authorizationResponse];
    } else {
      // There was a failure; convert to appropriate error code.
      NSString *errorString;
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;
      
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      if (self.emmSupport) {
        BOOL isEMMError = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:params
                                                                            completion:^{
          // TODO: What to do here?
        }];
        if (isEMMError) {
          errorCode = kGIDSignInErrorCodeEMM;
        }
      }
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      errorString = (NSString *)params[kOAuth2ErrorKeyName];
      if ([errorString isEqualToString:kOAuth2AccessDenied]) {
        errorCode = kGIDSignInErrorCodeCanceled;
      }
      
      self.error = [self errorWithString:errorString code:errorCode];
    }
  } else {
    NSString *errorString = [error localizedDescription];
    GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
    if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow ||
        error.code == OIDErrorCodeProgramCanceledAuthorizationFlow) {
      // The user has canceled the flow at the iOS modal dialog.
      errorString = kUserCanceledError;
      errorCode = kGIDSignInErrorCodeCanceled;
    }
    self.error = [self errorWithString:errorString code:errorCode];
  }
  
  GIDTokenFetchOperation *tokenFetch =
    [[GIDTokenFetchOperation alloc] initWithAuthState:self.authState
                                              options:self.options
                                           emmSupport:self.emmSupport
                                                error:self.error];
  GIDDecodeIDTokenOperation *decodeID = [[GIDDecodeIDTokenOperation alloc] init];
  [decodeID addDependency:tokenFetch];
  GIDSaveAuthOperation *saveAuth = [[GIDSaveAuthOperation alloc] init];
  [saveAuth addDependency:decodeID];
  GIDAuthorizationCompletionOperation *authCompletion =
    [[GIDAuthorizationCompletionOperation alloc] initWithAuthorizationFlow:self];
  [authCompletion addDependency:saveAuth];
  NSArray<NSOperation *> *operations = @[tokenFetch, decodeID, saveAuth, authCompletion];
  [NSOperationQueue.mainQueue addOperations:operations waitUntilFinished:NO];
}

#pragma mark - Errors

// TODO: Move this to its own type
- (NSError *)errorWithString:(NSString *)errorString code:(GIDSignInErrorCode)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  return [NSError errorWithDomain:kGIDSignInErrorDomain
                             code:code
                         userInfo:errorDict];
}

#pragma mark - Utilities

- (NSMutableDictionary<NSString *, NSString *> *)
    additionalParametersFromOptions:(GIDSignInInternalOptions *)options {
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX

  NSMutableDictionary<NSString *, NSString *> *additionalParameters =
      [[NSMutableDictionary alloc] init];
  additionalParameters[kIncludeGrantedScopesParameter] = @"true";
  if (options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = options.configuration.serverClientID;
  }
  if (options.loginHint) {
    additionalParameters[kLoginHintParameter] = options.loginHint;
  }
  if (options.configuration.hostedDomain) {
    additionalParameters[kHostedDomainParameter] = options.configuration.hostedDomain;
  }

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:options.extraParams
                                   emmSupport:emmSupport
                       isPasscodeInfoRequired:NO]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:options.extraParams];
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  return additionalParameters;
}

+ (BOOL)isOperatingSystemAtLeast9 {
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  return [processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
  [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
}

- (NSURL *)redirectURLWithOptions:(GIDSignInInternalOptions *)options {
  GIDSignInCallbackSchemes *schemes =
    [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
  NSString *redirect =
    [NSString stringWithFormat:@"%@:%@", [schemes clientIdentifierScheme], kBrowserCallbackPath];
  NSURL *redirectURL = [NSURL URLWithString:redirect];
  return redirectURL;
}

@end
