// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthentication.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDCallbackQueue.h"
#import "GoogleSignIn/Sources/GIDScopes.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDAuthStateMigration.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDExternalUserAgentSession.h>
#import <AppAuth/OIDIDToken.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <AppAuth/OIDURLQueryComponent.h>
#import <AppAuth/OIDAuthorizationService+IOS.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization+Keychain.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The name of the query parameter used for logging the restart of auth from EMM callback.
static NSString *const kEMMRestartAuthParameter = @"emmres";

// The URL template for the authorization endpoint.
static NSString *const kAuthorizationURLTemplate = @"https://%@/o/oauth2/v2/auth";

// The URL template for the token endpoint.
static NSString *const kTokenURLTemplate = @"https://%@/token";

// The URL template for the URL to get user info.
static NSString *const kUserInfoURLTemplate = @"https://%@/oauth2/v3/userinfo?access_token=%@";

// The URL template for the URL to revoke the token.
static NSString *const kRevokeTokenURLTemplate = @"https://%@/o/oauth2/revoke?token=%@";

// Expected path in the URL scheme to be handled.
static NSString *const kBrowserCallbackPath = @"/oauth2callback";

// Expected path for EMM callback.
static NSString *const kEMMCallbackPath = @"/emmcallback";

// The EMM support version
static NSString *const kEMMVersion = @"1";

// The error code for Google Identity.
NSErrorDomain const kGIDSignInErrorDomain = @"com.google.GIDSignIn";

// Keychain constants for saving state in the authentication flow.
static NSString *const kGTMAppAuthKeychainName = @"auth";

// Basic profile (Fat ID Token / userinfo endpoint) keys
static NSString *const kBasicProfileEmailKey = @"email";
static NSString *const kBasicProfilePictureKey = @"picture";
static NSString *const kBasicProfileNameKey = @"name";
static NSString *const kBasicProfileGivenNameKey = @"given_name";
static NSString *const kBasicProfileFamilyNameKey = @"family_name";

// Parameters in the callback URL coming back from browser.
static NSString *const kAuthorizationCodeKeyName = @"code";
static NSString *const kOAuth2ErrorKeyName = @"error";
static NSString *const kOAuth2AccessDenied = @"access_denied";
static NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

// Error string for unavailable keychain.
static NSString *const kKeychainError = @"keychain error";

// Error string for user cancelations.
static NSString *const kUserCanceledError = @"The user canceled the sign-in flow.";

// User preference key to detect fresh install of the app.
static NSString *const kAppHasRunBeforeKey = @"GID_AppHasRunBefore";

// Maximum retry interval in seconds for the fetcher.
static const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

// The delay before the new sign-in flow can be presented after the existing one is cancelled.
static const NSTimeInterval kPresentationDelayAfterCancel = 1.0;

// Extra parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
// See b/11669751 .
static NSString *const kOpenIDRealmParameter = @"openid.realm";

// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;

// The callback queue used for authentication flow.
@interface GIDAuthFlow : GIDCallbackQueue

@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, copy, nullable) NSString *emmSupport;
@property(nonatomic, nullable) GIDProfileData *profileData;

@end

@implementation GIDAuthFlow
@end

@implementation GIDSignIn {
  // This value is used when sign-in flows are resumed via the handling of a URL. Its value is
  // set when a sign-in flow is begun via |signInWithOptions:| when the options passed don't
  // represent a sign in continuation.
  GIDSignInInternalOptions *_currentOptions;
  // AppAuth configuration object.
  OIDServiceConfiguration *_appAuthConfiguration;
  // AppAuth external user-agent session state.
  id<OIDExternalUserAgentSession> _currentAuthorizationFlow;
  // Flag to indicate that the auth flow is restarting.
  BOOL _restarting;
}

#pragma mark - Public methods

- (BOOL)handleURL:(NSURL *)url {
  // Check if the callback path matches the expected one for a URL from Safari/Chrome/SafariVC.
  if ([url.path isEqual:kBrowserCallbackPath]) {
    if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
      _currentAuthorizationFlow = nil;
      return YES;
    }
    return NO;
  }
  // Check if the callback path matches the expected one for a URL from Google Device Policy app.
  if ([url.path isEqual:kEMMCallbackPath]) {
    return [self handleDevicePolicyAppURL:url];
  }
  return NO;
}

- (BOOL)hasPreviousSignIn {
  if ([_currentUser.authentication.authState isAuthorized]) {
    return YES;
  }
  OIDAuthState *authState = [self loadAuthState];
  return [authState isAuthorized];
}

- (void)restorePreviousSignInWithCallback:(nullable GIDSignInCallback)callback {
  [self signInWithOptions:[GIDSignInInternalOptions silentOptionsWithCallback:callback]];
}

- (void)signInWithConfiguration:(GIDConfiguration *)configuration
       presentingViewController:(UIViewController *)presentingViewController
                           hint:(nullable NSString *)hint
                       callback:(nullable GIDSignInCallback)callback {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:hint
                                                       callback:callback];
  [self signInWithOptions:options];
}

- (void)signInWithConfiguration:(GIDConfiguration *)configuration
       presentingViewController:(UIViewController *)presentingViewController
                       callback:(nullable GIDSignInCallback)callback {
  [self signInWithConfiguration:configuration
       presentingViewController:presentingViewController
                           hint:nil
                       callback:callback];
}


- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingViewController:(UIViewController *)presentingViewController
                    callback:(nullable GIDSignInCallback)callback {
  // A currentUser must be available in order to complete this flow.
  if (!self.currentUser) {
    // No currentUser is set, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeNoCurrentUser
                                     userInfo:nil];
    if (callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, error);
      });
    }
    return;
  }

  GIDConfiguration *configuration =
      [[GIDConfiguration alloc] initWithClientID:self.currentUser.authentication.clientID
                                  serverClientID:self.currentUser.serverClientID
                                    hostedDomain:self.currentUser.hostedDomain
                                     openIDRealm:self.currentUser.openIDRealm];
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:configuration
                                       presentingViewController:presentingViewController
                                                      loginHint:self.currentUser.profile.email
                                                       callback:callback];

  NSSet<NSString *> *requestedScopes = [NSSet setWithArray:scopes];
  NSMutableSet<NSString *> *grantedScopes =
      [NSMutableSet setWithArray:self.currentUser.grantedScopes];

  // Check to see if all requested scopes have already been granted.
  if ([requestedScopes isSubsetOfSet:grantedScopes]) {
    // All requested scopes have already been granted, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeScopesAlreadyGranted
                                     userInfo:nil];
    if (callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, error);
      });
    }
    return;
  }

  // Use the union of granted and requested scopes.
  [grantedScopes unionSet:requestedScopes];
  options.scopes = [grantedScopes allObjects];

  [self signInWithOptions:options];
}

- (void)signOut {
  // Clear the current user if there is one.
  if (_currentUser) {
    [self willChangeValueForKey:NSStringFromSelector(@selector(currentUser))];
    _currentUser = nil;
    [self didChangeValueForKey:NSStringFromSelector(@selector(currentUser))];
  }
  // Remove all state from the keychain.
  [self removeAllKeychainEntries];
}

- (void)disconnectWithCallback:(nullable GIDDisconnectCallback)callback {
  GIDGoogleUser *user = _currentUser;
  OIDAuthState *authState = user.authentication.authState;
  if (!authState) {
    // Even the user is not signed in right now, we still need to remove any token saved in the
    // keychain.
    authState = [self loadAuthState];
  }
  // Either access or refresh token would work, but we won't have access token if the auth is
  // retrieved from keychain.
  NSString *token = authState.lastTokenResponse.accessToken;
  if (!token) {
    token = authState.lastTokenResponse.refreshToken;
  }
  if (!token) {
    [self signOut];
    // Nothing to do here, consider the operation successful.
    if (callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil);
      });
    }
    return;
  }
  NSString *revokeURLString = [NSString stringWithFormat:kRevokeTokenURLTemplate,
      [GIDSignInPreferences googleAuthorizationServer], token];
  // Append logging parameter
  revokeURLString = [NSString stringWithFormat:@"%@&%@=%@",
                     revokeURLString,
                     kSDKVersionLoggingParameter,
                     GIDVersion()];
  NSURL *revokeURL = [NSURL URLWithString:revokeURLString];
  [self startFetchURL:revokeURL
              fromAuthState:authState
                withComment:@"GIDSignIn: revoke tokens"
      withCompletionHandler:^(NSData *data, NSError *error) {
    // Revoking an already revoked token seems always successful, which helps us here.
    if (!error) {
      [self signOut];
    }
    if (callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        callback(error);
      });
    }
  }];
}

#pragma mark - Custom getters and setters

+ (GIDSignIn *)sharedInstance {
  static dispatch_once_t once;
  static GIDSignIn *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] initPrivate];
  });
  return sharedInstance;
}

#pragma mark - Private methods

- (id)initPrivate {
  self = [super init];
  if (self) {
    // Check to see if the 3P app is being run for the first time after a fresh install.
    BOOL isFreshInstall = [self isFreshInstall];

    // If this is a fresh install, ensure that any pre-existing keychain data is purged.
    if (isFreshInstall) {
      [self removeAllKeychainEntries];
    }

    NSString *authorizationEnpointURL = [NSString stringWithFormat:kAuthorizationURLTemplate,
        [GIDSignInPreferences googleAuthorizationServer]];
    NSString *tokenEndpointURL = [NSString stringWithFormat:kTokenURLTemplate,
        [GIDSignInPreferences googleTokenServer]];
    _appAuthConfiguration = [[OIDServiceConfiguration alloc]
        initWithAuthorizationEndpoint:[NSURL URLWithString:authorizationEnpointURL]
                        tokenEndpoint:[NSURL URLWithString:tokenEndpointURL]];

    // Perform migration of auth state from old versions of the SDK if needed.
    [GIDAuthStateMigration migrateIfNeededWithTokenURL:_appAuthConfiguration.tokenEndpoint
                                          callbackPath:kBrowserCallbackPath
                                          keychainName:kGTMAppAuthKeychainName
                                        isFreshInstall:isFreshInstall];
  }
  return self;
}

// Does sanity check for parameters and then authenticates if necessary.
- (void)signInWithOptions:(GIDSignInInternalOptions *)options {
  // Options for continuation are not the options we want to cache. The purpose of caching the
  // options in the first place is to provide continuation flows with a starting place from which to
  // derive suitable options for the continuation!
  if (!options.continuation) {
    _currentOptions = options;
  }

  if (options.interactive) {
    // Explicitly throw exception for missing client ID here. This must come before
    // scheme check because schemes rely on reverse client IDs.
    [self assertValidParameters];

    [self assertValidPresentingViewController];

    // If the application does not support the required URL schemes tell the developer so.
    GIDSignInCallbackSchemes *schemes =
        [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
    NSArray<NSString *> *unsupportedSchemes = [schemes unsupportedSchemes];
    if (unsupportedSchemes.count != 0) {
      // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
      [NSException raise:NSInvalidArgumentException
                  format:@"Your app is missing support for the following URL schemes: %@",
                         [unsupportedSchemes componentsJoinedByString:@", "]];
    }
  }

  // If this is a non-interactive flow, use cached authentication if possible.
  if (!options.interactive && _currentUser.authentication) {
    [_currentUser.authentication doWithFreshTokens:^(GIDAuthentication *unused, NSError *error) {
      if (error) {
        [self authenticateWithOptions:options];
      } else {
        if (options.callback) {
          dispatch_async(dispatch_get_main_queue(), ^{
            options.callback(self->_currentUser, nil);
            self->_currentOptions = nil;
          });
        }
      }
    }];
  } else {
    [self authenticateWithOptions:options];
  }
}

- (nullable GIDGoogleUser *)restoredGoogleUserFromPreviousSignIn {
  OIDAuthState *authState = [self loadAuthState];

  if (!authState) {
    return nil;
  }

  return [[GIDGoogleUser alloc] initWithAuthState:authState
                                      profileData:nil];
}

# pragma mark - Authentication flow

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
  NSURL *redirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@",
                                             [schemes clientIdentifierScheme],
                                             kBrowserCallbackPath]];
  NSString *emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (options.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = options.configuration.serverClientID;
  }
  if (options.loginHint) {
    additionalParameters[@"login_hint"] = options.loginHint;
  }
  if (options.configuration.hostedDomain) {
    additionalParameters[@"hd"] = options.configuration.hostedDomain;
  }
  [additionalParameters addEntriesFromDictionary:
      [GIDAuthentication parametersWithParameters:options.extraParams
                                       emmSupport:emmSupport
                           isPasscodeInfoRequired:NO]];
  OIDAuthorizationRequest *request =
      [[OIDAuthorizationRequest alloc] initWithConfiguration:_appAuthConfiguration
                                                    clientId:options.configuration.clientID
                                                      scopes:options.scopes
                                                 redirectURL:redirectURL
                                                responseType:OIDResponseTypeCode
                                        additionalParameters:additionalParameters];
  _currentAuthorizationFlow = [OIDAuthorizationService
      presentAuthorizationRequest:request
         presentingViewController:options.presentingViewController
                         callback:^(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                    NSError *_Nullable error) {
    if (self->_restarting) {
      // The auth flow is restarting, so the work here would be performed in the next round.
      self->_restarting = NO;
      return;
    }

    GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];
    authFlow.emmSupport = emmSupport;

    if (authorizationResponse) {
      if (authorizationResponse.authorizationCode.length) {
        authFlow.authState = [[OIDAuthState alloc]
            initWithAuthorizationResponse:authorizationResponse];
        // perform auth code exchange
        [self maybeFetchToken:authFlow fallback:nil];
      } else {
        // There was a failure, convert to appropriate error code.
        NSString *errorString;
        GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
        NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;

        if (authFlow.emmSupport) {
          [authFlow wait];
          BOOL isEMMError = [[GIDEMMErrorHandler sharedInstance]
              handleErrorFromResponse:params
                           completion:^{
                             [authFlow next];
                           }];
          if (isEMMError) {
            errorCode = kGIDSignInErrorCodeEMM;
          }
        }
        errorString = (NSString *)params[kOAuth2ErrorKeyName];
        if ([errorString isEqualToString:kOAuth2AccessDenied]) {
          errorCode = kGIDSignInErrorCodeCanceled;
        }

        authFlow.error = [self errorWithString:errorString code:errorCode];
      }
    } else {
      NSString *errorString = [error localizedDescription];
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      if (error.code == OIDErrorCodeUserCanceledAuthorizationFlow) {
        // The user has canceled the flow at the iOS modal dialog.
        errorString = kUserCanceledError;
        errorCode = kGIDSignInErrorCodeCanceled;
      }
      authFlow.error = [self errorWithString:errorString code:errorCode];
    }

    [self addDecodeIdTokenCallback:authFlow];
    [self addSaveAuthCallback:authFlow];
    [self addCompletionCallback:authFlow];
  }];
}

// Perform authentication with the provided options.
- (void)authenticateWithOptions:(GIDSignInInternalOptions *)options {

  // If this is an interactive flow, we're not going to try to restore any saved auth state.
  if (options.interactive) {
    [self authenticateInteractivelyWithOptions:options];
    return;
  }

  // Try retrieving an authorization object from the keychain.
  OIDAuthState *authState = [self loadAuthState];

  if (![authState isAuthorized]) {
    // No valid auth in keychain, per documentation/spec, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                     userInfo:nil];
    if (options.callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        options.callback(nil, error);
        self->_currentOptions = nil;
      });
    }
    return;
  }

  // Complete the auth flow using saved auth in keychain.
  GIDAuthFlow *authFlow = [[GIDAuthFlow alloc] init];
  authFlow.authState = authState;
  [self maybeFetchToken:authFlow fallback:options.interactive ? ^() {
    [self authenticateInteractivelyWithOptions:options];
  } : nil];
  [self addDecodeIdTokenCallback:authFlow];
  [self addSaveAuthCallback:authFlow];
  [self addCompletionCallback:authFlow];
}

// Fetches the access token if necessary as part of the auth flow. If |fallback|
// is provided, call it instead of continuing the auth flow in case of error.
- (void)maybeFetchToken:(GIDAuthFlow *)authFlow fallback:(nullable void (^)(void))fallback {
  OIDAuthState *authState = authFlow.authState;
  // Do nothing if we have an auth flow error or a restored access token that isn't near expiration.
  if (authFlow.error ||
      (authState.lastTokenResponse.accessToken &&
        [authState.lastTokenResponse.accessTokenExpirationDate timeIntervalSinceNow] >
        kMinimumRestoredAccessTokenTimeToExpire)) {
    return;
  }
  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
  if (_currentOptions.configuration.serverClientID) {
    additionalParameters[kAudienceParameter] = _currentOptions.configuration.serverClientID;
  }
  if (_currentOptions.configuration.openIDRealm) {
    additionalParameters[kOpenIDRealmParameter] = _currentOptions.configuration.openIDRealm;
  }
  NSDictionary<NSString *, NSObject *> *params =
      authState.lastAuthorizationResponse.additionalParameters;
  NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
  [additionalParameters addEntriesFromDictionary:
      [GIDAuthentication parametersWithParameters:@{}
                                       emmSupport:authFlow.emmSupport
                           isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
  OIDTokenRequest *tokenRequest;
  if (!authState.lastTokenResponse.accessToken &&
      authState.lastAuthorizationResponse.authorizationCode) {
    tokenRequest = [authState.lastAuthorizationResponse
        tokenExchangeRequestWithAdditionalParameters:additionalParameters];
  } else {
    [additionalParameters
        addEntriesFromDictionary:authState.lastTokenResponse.request.additionalParameters];
    tokenRequest = [authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  }

  [authFlow wait];
  [OIDAuthorizationService
      performTokenRequest:tokenRequest
                 callback:^(OIDTokenResponse *_Nullable tokenResponse,
                            NSError *_Nullable error) {
    [authState updateWithTokenResponse:tokenResponse error:error];
    authFlow.error = error;

    if (!tokenResponse.accessToken || error) {
      if (fallback) {
        [authFlow reset];
        fallback();
        return;
      }
    }

    if (authFlow.emmSupport) {
      [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *error) {
        authFlow.error = error;
        [authFlow next];
      }];
    } else {
      [authFlow next];
    }
  }];
}

// Adds a callback to the auth flow to save the auth object to |self| and the keychain as well.
- (void)addSaveAuthCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (authState && !handlerAuthFlow.error) {
      if (![self saveAuthState:authState]) {
        handlerAuthFlow.error = [self errorWithString:kKeychainError
                                                 code:kGIDSignInErrorCodeKeychain];
        return;
      }
      [self willChangeValueForKey:NSStringFromSelector(@selector(currentUser))];
      self->_currentUser = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                        profileData:handlerAuthFlow.profileData];
      [self didChangeValueForKey:NSStringFromSelector(@selector(currentUser))];
    }
  }];
}

// Adds a callback to the auth flow to extract user data from the ID token where available and
// make a userinfo request if necessary.
- (void)addDecodeIdTokenCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (!authState || handlerAuthFlow.error) {
      return;
    }
    OIDIDToken *idToken =
        [[OIDIDToken alloc] initWithIDTokenString:authState.lastTokenResponse.idToken];
    if (idToken) {
      // If the picture and name fields are present in the ID token, use them, otherwise make
      // a userinfo request to fetch them.
      if (idToken.claims[kBasicProfilePictureKey] &&
          idToken.claims[kBasicProfileNameKey] &&
          idToken.claims[kBasicProfileGivenNameKey] &&
          idToken.claims[kBasicProfileFamilyNameKey]) {
        handlerAuthFlow.profileData = [[GIDProfileData alloc]
            initWithEmail:idToken.claims[kBasicProfileEmailKey]
                     name:idToken.claims[kBasicProfileNameKey]
                givenName:idToken.claims[kBasicProfileGivenNameKey]
               familyName:idToken.claims[kBasicProfileFamilyNameKey]
                 imageURL:[NSURL URLWithString:idToken.claims[kBasicProfilePictureKey]]];
      } else {
        [handlerAuthFlow wait];
        NSURL *infoURL = [NSURL URLWithString:
            [NSString stringWithFormat:kUserInfoURLTemplate,
                [GIDSignInPreferences googleUserInfoServer],
                authState.lastTokenResponse.accessToken]];
        [self startFetchURL:infoURL
                    fromAuthState:authState
                      withComment:@"GIDSignIn: fetch basic profile info"
            withCompletionHandler:^(NSData *data, NSError *error) {
          if (data && !error) {
            NSError *jsonDeserializationError;
            NSDictionary<NSString *, NSString *> *profileDict =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers
                                                  error:&jsonDeserializationError];
            if (profileDict) {
              handlerAuthFlow.profileData = [[GIDProfileData alloc]
                  initWithEmail:idToken.claims[kBasicProfileEmailKey]
                           name:profileDict[kBasicProfileNameKey]
                      givenName:profileDict[kBasicProfileGivenNameKey]
                     familyName:profileDict[kBasicProfileFamilyNameKey]
                       imageURL:[NSURL URLWithString:profileDict[kBasicProfilePictureKey]]];
            }
          }
          if (error) {
            handlerAuthFlow.error = error;
          }
          [handlerAuthFlow next];
        }];
      }
    }
  }];
}

// Adds a callback to the auth flow to complete the flow by calling the sign-in callback.
- (void)addCompletionCallback:(GIDAuthFlow *)authFlow {
  __weak GIDAuthFlow *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow *handlerAuthFlow = weakAuthFlow;
    if (self->_currentOptions.callback) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self->_currentOptions.callback(self->_currentUser, handlerAuthFlow.error);
        self->_currentOptions = nil;
      });
    }
  }];
}

- (void)startFetchURL:(NSURL *)URL
            fromAuthState:(OIDAuthState *)authState
              withComment:(NSString *)comment
    withCompletionHandler:(void (^)(NSData *, NSError *))handler {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  GTMSessionFetcher *fetcher;
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  id<GTMSessionFetcherServiceProtocol> fetcherService = authorization.fetcherService;
  if (fetcherService) {
    fetcher = [fetcherService fetcherWithRequest:request];
  } else {
    fetcher = [GTMSessionFetcher fetcherWithRequest:request];
  }
  fetcher.retryEnabled = YES;
  fetcher.maxRetryInterval = kFetcherMaxRetryInterval;
  fetcher.comment = comment;
  [fetcher beginFetchWithCompletionHandler:handler];
}

// Parse incoming URL from the Google Device Policy app.
- (BOOL)handleDevicePolicyAppURL:(NSURL *)url {
  OIDURLQueryComponent *queryComponent = [[OIDURLQueryComponent alloc] initWithURL:url];
  NSDictionary<NSString *, NSObject<NSCopying> *> *params = queryComponent.dictionaryValue;
  NSObject<NSCopying> *actionParam = params[@"action"];
  NSString *actionString =
      [actionParam isKindOfClass:[NSString class]] ? (NSString *)actionParam : nil;
  if (![@"restart_auth" isEqualToString:actionString]) {
    return NO;
  }
  if (!_currentOptions.presentingViewController) {
    return NO;
  }
  if (!_currentAuthorizationFlow) {
    return NO;
  }
  _restarting = YES;
  [_currentAuthorizationFlow cancel];
  _currentAuthorizationFlow = nil;
  _restarting = NO;
  NSDictionary<NSString *, NSString *> *extraParameters = @{ kEMMRestartAuthParameter : @"1" };
  // In iOS 13 the presentation of ASWebAuthenticationSession needs an anchor window,
  // so we need to wait until the previous presentation is completely gone to ensure the right
  // anchor window is used here.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                 (int64_t)(kPresentationDelayAfterCancel * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [self signInWithOptions:[self->_currentOptions optionsWithExtraParameters:extraParameters
                                                              forContinuation:YES]];
  });
  return YES;
}

#pragma mark - Key-Value Observing

// Override |NSObject(NSKeyValueObservingCustomization)| method in order to provide custom KVO
// notifications for |clientID| and |currentUser| properties.
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  if ([key isEqual:NSStringFromSelector(@selector(clientID))] ||
      [key isEqual:NSStringFromSelector(@selector(currentUser))]) {
    return NO;
  }
  return [super automaticallyNotifiesObserversForKey:key];
}

#pragma mark - Helpers

- (NSError *)errorWithString:(NSString *)errorString code:(GIDSignInErrorCode)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  return [NSError errorWithDomain:kGIDSignInErrorDomain
                             code:code
                         userInfo:errorDict];
}

+ (BOOL)isOperatingSystemAtLeast9 {
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  return [processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
      [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
}

// Asserts the parameters being valid.
- (void)assertValidParameters {
  if (![_currentOptions.configuration.clientID length]) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"You must specify |clientID| in |GIDConfiguration|"];
  }
}

// Assert that the presenting view controller has been set.
- (void)assertValidPresentingViewController {
  if (!_currentOptions.presentingViewController) {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"|presentingViewController| must be set."];
  }
}

// Checks whether or not this is the first time the app runs.
- (BOOL)isFreshInstall {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults boolForKey:kAppHasRunBeforeKey]) {
    return NO;
  }
  [defaults setBool:YES forKey:kAppHasRunBeforeKey];
  return YES;
}

- (void)removeAllKeychainEntries {
  [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kGTMAppAuthKeychainName];
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  return [GTMAppAuthFetcherAuthorization saveAuthorization:authorization
                                         toKeychainForName:kGTMAppAuthKeychainName];
}

- (OIDAuthState *)loadAuthState {
  GTMAppAuthFetcherAuthorization *authorization =
      [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kGTMAppAuthKeychainName];
  return authorization.authState;
}

@end

NS_ASSUME_NONNULL_END
