#import "GoogleSignIn/Sources/GIDUserAuthFlowController.h"

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDUserAuth.h"

#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDCallbackQueue.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import "GoogleSignIn/Sources/GIDAuthStateMigration.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDUserAuth_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The name of the query parameter used for logging the restart of auth from EMM callback.
static NSString *const kEMMRestartAuthParameter = @"emmres";

// The URL template for the URL to get user info.
static NSString *const kUserInfoURLTemplate = @"https://%@/oauth2/v3/userinfo?access_token=%@";

static NSString *const kEMMPasscodeInfoRequiredKeyName = @"emm_passcode_info_required";

// Expected path in the URL scheme to be handled.
static NSString *const kBrowserCallbackPath = @"/oauth2callback";

// Expected path for EMM callback.
static NSString *const kEMMCallbackPath = @"/emmcallback";

// The EMM support version
static NSString *const kEMMVersion = @"1";

// Basic profile (Fat ID Token / userinfo endpoint) keys
static NSString *const kBasicProfileEmailKey = @"email";
static NSString *const kBasicProfilePictureKey = @"picture";
static NSString *const kBasicProfileNameKey = @"name";
static NSString *const kBasicProfileGivenNameKey = @"given_name";
static NSString *const kBasicProfileFamilyNameKey = @"family_name";

// Parameters for the auth and token exchange endpoints.
static NSString *const kAudienceParameter = @"audience";
// See b/11669751 .
static NSString *const kOpenIDRealmParameter = @"openid.realm";
static NSString *const kIncludeGrantedScopesParameter = @"include_granted_scopes";
static NSString *const kLoginHintParameter = @"login_hint";
static NSString *const kHostedDomainParameter = @"hd";

// Parameters in the callback URL coming back from browser.
static NSString *const kOAuth2ErrorKeyName = @"error";
static NSString *const kOAuth2AccessDenied = @"access_denied";

// Error string for unavailable keychain.
static NSString *const kKeychainError = @"keychain error";

// Error string for user cancelations.
static NSString *const kUserCanceledError = @"The user canceled the sign-in flow.";

// Maximum retry interval in seconds for the fetcher.
static const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

// The delay before the new sign-in flow can be presented after the existing one is cancelled.
static const NSTimeInterval kPresentationDelayAfterCancel = 1.0;

// Minimum time to expiration for a restored access token.
static const NSTimeInterval kMinimumRestoredAccessTokenTimeToExpire = 600.0;

// The callback queue used for authentication flow.
@interface GIDAuthFlow_TEMP : GIDCallbackQueue

@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, copy, nullable) NSString *emmSupport;
@property(nonatomic, nullable) GIDProfileData *profileData;

@end

@implementation GIDAuthFlow_TEMP
@end

// Keychain constants for saving state in the authentication flow.
static NSString *const kGTMAppAuthKeychainName = @"auth";

@implementation GIDUserAuthFlowResult

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData
                   serverAuthCode:(nullable NSString *)serverAuthCode{
  self = [super init];
  if (self) {
    _authState = authState;
    _profileData = profileData;
    _serverAuthCode = [serverAuthCode copy];
  }
  return self;
};

@end


@implementation GIDUserAuthFlowController {
  // represent a sign in continuation.
  GIDSignInInternalOptions *_currentOptions;
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

- (void)signInWithOptions:(GIDSignInInternalOptions *)options
               completion:(GIDUserAuthFlowCompletion)completion {
  // Options for continuation are not the options we want to cache. The purpose of caching the
  // options in the first place is to provide continuation flows with a starting place from which to
  // derive suitable options for the continuation!
  if (!options.continuation) {
    _currentOptions = options;
  }
  
  [self authenticateWithOptions:options completion:completion];
}


- (void)authenticateWithOptions:(GIDSignInInternalOptions *)options
                     completion:(GIDUserAuthFlowCompletion)completion {
  //If this is an interactive flow, we're not going to try to restore any saved auth state.
  if (options.interactive) {
    [self authenticateInteractivelyWithOptions:options
                                    completion:completion];
    return;
  }

  // Try retrieving an authorization object from the keychain.
  OIDAuthState *authState = [self loadAuthState];

  if (![authState isAuthorized]) {
    // No valid auth in keychain, per documentation/spec, notify callback of failure.
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                     userInfo:nil];
    if (options.completion) {
      _currentOptions = nil;
      dispatch_async(dispatch_get_main_queue(), ^{
        options.completion(nil, error);
      });
    }
    return;
  }

  // Complete the auth flow using saved auth in keychain.
  GIDAuthFlow_TEMP *authFlow = [[GIDAuthFlow_TEMP alloc] init];
  authFlow.authState = authState;
  [self maybeFetchToken:authFlow];
  [self addDecodeIdTokenCallback:authFlow];
  [self addSaveAuthCallback:authFlow];
  [self addCompletionCallback:authFlow completion:completion];
}

// Fetches the access token if necessary as part of the auth flow.
- (void)maybeFetchToken:(GIDAuthFlow_TEMP *)authFlow {
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
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  NSDictionary<NSString *, NSObject *> *params =
      authState.lastAuthorizationResponse.additionalParameters;
  NSString *passcodeInfoRequired = (NSString *)params[kEMMPasscodeInfoRequiredKeyName];
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport parametersWithParameters:@{}
                                   emmSupport:authFlow.emmSupport
                       isPasscodeInfoRequired:passcodeInfoRequired.length > 0]];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    if (authFlow.emmSupport) {
      [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *error) {
        authFlow.error = error;
        [authFlow next];
      }];
    } else {
      [authFlow next];
    }
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    [authFlow next];
#endif // TARGET_OS_OSX || TARGET_OS_MACCATALYST
  }];
}

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options
                                  completion:(GIDUserAuthFlowCompletion)completion{
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
  NSURL *redirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@",
                                             [schemes clientIdentifierScheme],
                                             kBrowserCallbackPath]];
  NSString *emmSupport;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  emmSupport = [[self class] isOperatingSystemAtLeast9] ? kEMMVersion : nil;
#elif TARGET_OS_MACCATALYST || TARGET_OS_OSX
  emmSupport = nil;
#endif // TARGET_OS_MACCATALYST || TARGET_OS_OSX

  NSMutableDictionary<NSString *, NSString *> *additionalParameters = [@{} mutableCopy];
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

  OIDServiceConfiguration *appAuthConfiguration = [GIDSignInPreferences appAuthConfiguration];
  OIDAuthorizationRequest *request =
      [[OIDAuthorizationRequest alloc] initWithConfiguration:appAuthConfiguration
                                                    clientId:options.configuration.clientID
                                                      scopes:options.scopes
                                                 redirectURL:redirectURL
                                                responseType:OIDResponseTypeCode
                                        additionalParameters:additionalParameters];

  _currentAuthorizationFlow = [OIDAuthorizationService
      presentAuthorizationRequest:request
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
         presentingViewController:options.presentingViewController
#elif TARGET_OS_OSX
                 presentingWindow:options.presentingWindow
#endif // TARGET_OS_OSX
                        callback:^(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                   NSError *_Nullable error) {
    [self processAuthorizationResponse:authorizationResponse
                                 error:error
                            emmSupport:emmSupport
                            completion:completion];
  }];
}

- (void)processAuthorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                               error:(NSError *)error
                          emmSupport:(NSString *)emmSupport
                          completion:(GIDUserAuthFlowCompletion)completion {
  if (_restarting) {
    // The auth flow is restarting, so the work here would be performed in the next round.
    _restarting = NO;
    return;
  }

  GIDAuthFlow_TEMP *authFlow = [[GIDAuthFlow_TEMP alloc] init];
  authFlow.emmSupport = emmSupport;

  if (authorizationResponse) {
    if (authorizationResponse.authorizationCode.length) {
      authFlow.authState = [[OIDAuthState alloc]
          initWithAuthorizationResponse:authorizationResponse];
      // perform auth code exchange
      [self maybeFetchToken:authFlow];
    } else {
      // There was a failure, convert to appropriate error code.
      NSString *errorString;
      GIDSignInErrorCode errorCode = kGIDSignInErrorCodeUnknown;
      NSDictionary<NSString *, NSObject *> *params = authorizationResponse.additionalParameters;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
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
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
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
  [self addCompletionCallback:authFlow
                   completion:completion];
}


// Adds a callback to the auth flow to extract user data from the ID token where available and
// make a userinfo request if necessary.
- (void)addDecodeIdTokenCallback:(GIDAuthFlow_TEMP *)authFlow {
  __weak GIDAuthFlow_TEMP *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow_TEMP *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (!authState || handlerAuthFlow.error) {
      return;
    }
    OIDIDToken *idToken =
        [[OIDIDToken alloc] initWithIDTokenString: authState.lastTokenResponse.idToken];
    // If the profile data are present in the ID token, use them.
    if (idToken) {
      handlerAuthFlow.profileData = [self profileDataWithIDToken:idToken];
    }

    // If we can't retrieve profile data from the ID token, make a userInfo request to fetch them.
    if (!handlerAuthFlow.profileData) {
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
  }];
}

// Adds a callback to the auth flow to save the auth object to |self| and the keychain as well.
- (void)addSaveAuthCallback:(GIDAuthFlow_TEMP *)authFlow {
  __weak GIDAuthFlow_TEMP *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow_TEMP *handlerAuthFlow = weakAuthFlow;
    OIDAuthState *authState = handlerAuthFlow.authState;
    if (authState && !handlerAuthFlow.error) {
      if (![self saveAuthState:authState]) {
        handlerAuthFlow.error = [self errorWithString:kKeychainError
                                                 code:kGIDSignInErrorCodeKeychain];
      }

//      if (self->_currentOptions.addScopesFlow) {
//        [self->_currentUser updateWithTokenResponse:authState.lastTokenResponse
//                              authorizationResponse:authState.lastAuthorizationResponse
//                                        profileData:handlerAuthFlow.profileData];
//      } else {
//        GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState
//                                                           profileData:handlerAuthFlow.profileData];
//        self.currentUser = user;
//      }
    }
  }];
}

// Adds a callback to the auth flow to complete the flow by calling the sign-in callback.
- (void)addCompletionCallback:(GIDAuthFlow_TEMP *)authFlow
                   completion:(GIDUserAuthFlowCompletion)completion {
  __weak GIDAuthFlow_TEMP *weakAuthFlow = authFlow;
  [authFlow addCallback:^() {
    GIDAuthFlow_TEMP *handlerAuthFlow = weakAuthFlow;
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (handlerAuthFlow.error) {
          completion(nil, handlerAuthFlow.error);
        } else {
          OIDAuthState *authState = handlerAuthFlow.authState;
          GIDProfileData *profileData = handlerAuthFlow.profileData;
          NSString *_Nullable serverAuthCode =
              [authState.lastTokenResponse.additionalParameters[@"server_code"] copy];
          
          GIDUserAuthFlowResult *authFlowResult =
              [[GIDUserAuthFlowResult alloc] initWithAuthState:authState
                                                   profileData:profileData
                                                serverAuthCode:serverAuthCode];
          completion(authFlowResult, nil);
        }
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
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  if (!_currentOptions.presentingViewController) {
    return NO;
  }
#elif TARGET_OS_OSX
  if (!_currentOptions.presentingWindow) {
    return NO;
  }
#endif // TARGET_OS_OSX
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

# pragma mark - Helpers

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
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
  if (!_currentOptions.presentingViewController)
#elif TARGET_OS_OSX
  if (!_currentOptions.presentingWindow)
#endif // TARGET_OS_OSX
  {
    // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
    [NSException raise:NSInvalidArgumentException
                format:@"|presentingViewController| must be set."];
  }
}

- (OIDAuthState *)loadAuthState {
  GTMAppAuthFetcherAuthorization *authorization =
      [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kGTMAppAuthKeychainName
                                             useDataProtectionKeychain:YES];
  return authorization.authState;
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  return [GTMAppAuthFetcherAuthorization saveAuthorization:authorization
                                         toKeychainForName:kGTMAppAuthKeychainName
                                 useDataProtectionKeychain:YES];
}

// Generates user profile from OIDIDToken.
- (GIDProfileData *)profileDataWithIDToken:(OIDIDToken *)idToken {
  if (!idToken ||
      !idToken.claims[kBasicProfilePictureKey] ||
      !idToken.claims[kBasicProfileNameKey] ||
      !idToken.claims[kBasicProfileGivenNameKey] ||
      !idToken.claims[kBasicProfileFamilyNameKey]) {
    return nil;
  }

  return [[GIDProfileData alloc]
      initWithEmail:idToken.claims[kBasicProfileEmailKey]
               name:idToken.claims[kBasicProfileNameKey]
          givenName:idToken.claims[kBasicProfileGivenNameKey]
          familyName:idToken.claims[kBasicProfileFamilyNameKey]
            imageURL:[NSURL URLWithString:idToken.claims[kBasicProfilePictureKey]]];
}

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

NS_ASSUME_NONNULL_END
