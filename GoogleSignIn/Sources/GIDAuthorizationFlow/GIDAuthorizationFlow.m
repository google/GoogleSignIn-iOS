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
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDSaveAuthOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDTokenFetchOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDDecodeIDTokenOperation.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDAuthorizationCompletionOperation.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

// TODO: Move these constants to their own spot
#pragma mark - Parameters in the callback URL coming back from browser.
static NSString *const kAuthorizationCodeKeyName = @"code";
static NSString *const kOAuth2ErrorKeyName = @"error";
static NSString *const kOAuth2AccessDenied = @"access_denied";
static NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

/// Error string for user cancelations.
static NSString *const kUserCanceledError = @"The user canceled the sign-in flow.";

/// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;
/// Parameters for the auth and token exchange endpoints.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";

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
  
  NSArray *operations = @[tokenFetch, idToken, saveAuth, authCompletion];
  [NSOperationQueue.mainQueue addOperations:operations waitUntilFinished:NO];
}

- (void)authorizeInteractively {
  // TODO: Implement me
}

#pragma mark - Token Fetching

// TODO: Remove the next four methods
- (void)maybeFetchToken {
  // Do nothing if we have an auth flow error or a restored access token that isn't near expiration.
  if (self.error ||
      (self.authState.lastTokenResponse.accessToken &&
        [self.authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
        kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }
  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (self.options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = self.options.configuration.serverClientID;
  }
  if (self.options.configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = self.options.configuration.openIDRealm;
  }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSDictionary<NSString *, NSObject *> *params =
      self.authState.lastAuthorizationResponse.additionalParameters;
  NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:@{}
                                   emmSupport:self.emmSupport
                       isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  OIDTokenRequest *tokenRequest;
  if (!self.authState.lastTokenResponse.accessToken &&
      self.authState.lastAuthorizationResponse.authorizationCode) {
    tokenRequest = [self.authState.lastAuthorizationResponse
        tokenExchangeRequestWithAdditionalParameters:additionalParameters];
  } else {
    [additionalParameters
        addEntriesFromDictionary:self.authState.lastTokenResponse.request.additionalParameters];
    tokenRequest = [self.authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  }

//  [self wait];
  [OIDAuthorizationService performTokenRequest:tokenRequest
                 originalAuthorizationResponse:self.authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    [self.authState updateWithTokenResponse:tokenResponse error:error];
    self.error = error;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    if (self.emmSupport) {
      [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *error) {
        self.error = error;
//        [self next];
      }];
    } else {
//      [self next];
    }
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    [authFlow next];
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  }];
}

#pragma mark - Decode ID Token

- (void)addDecodeIdTokenCallback {
  
}

#pragma mark - Saving Authorization

- (void)addSaveAuthCallback {
  
}

#pragma mark - Completion Callback

- (void)addCompletionCallback {
  
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
      [self maybeFetchToken];
    } else {
      // There was a failure; convert to appropriate error code.
      NSString *errorString;
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
      if (self.emmSupport) {
//        [self wait];
        BOOL isEMMError = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:params
                                                                            completion:^{
//          [self next];
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

  [self addDecodeIdTokenCallback];
  [self addSaveAuthCallback];
  [self addCompletionCallback];
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

@end
