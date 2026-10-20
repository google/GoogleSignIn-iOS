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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDAuthentication.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDToken_Private.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The ID Token claim key for the hosted domain value.
static NSString *const kHostedDomainIDTokenClaimKey = @"hd";

// Key constants used for encode and decode.
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kAuthStateKey = @"authState";

// Parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";

// Minimal time interval before expiration for the access token or it needs to be refreshed.
static NSTimeInterval const kMinimalTimeToExpire = 60.0;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@interface GIDGoogleUser ()

@property (nonatomic, strong) id<GTMAuthSessionDelegate> authSessionDelegate;

@end
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDGoogleUserTokens

- (instancetype)initWithAccessToken:(GIDToken *)accessToken
                       refreshToken:(GIDToken *)refreshToken
                            idToken:(nullable GIDToken *)idToken
                      grantedScopes:(nullable NSArray<NSString *> *)grantedScopes
                      configuration:(GIDConfiguration *)configuration
                            profile:(nullable GIDProfileData *)profile {
  self = [super init];
  if (self) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _idToken = idToken;
    _grantedScopes = [grantedScopes copy];
    _configuration = configuration;
    _profile = profile;
  }
  return self;
}

@end

// Parses the `scope` parameter of a token response, which is authoritative when present
// (https://datatracker.ietf.org/doc/html/rfc6749#section-5.1). Scopes are space-delimited
// (https://datatracker.ietf.org/doc/html/rfc6749#section-3.3); surrounding whitespace and runs of
// spaces are tolerated. Returns nil when the response carries no `scope` parameter.
static NSArray<NSString *> *_Nullable GIDGrantedScopesFromScopeString(
    NSString *_Nullable scopeString) {
  if (!scopeString) {
    return nil;
  }
  // Remove leading and trailing whitespace.
  scopeString =
      [scopeString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  // Tokenize with space as a delimiter.
  NSMutableArray<NSString *> *parsedScopes =
      [[scopeString componentsSeparatedByString:@" "] mutableCopy];
  // Remove empty strings.
  [parsedScopes removeObject:@""];
  return [parsedScopes copy];
}

// Returns the hosted domain claim of the given ID token, if it has one.
static NSString *_Nullable GIDHostedDomainFromIDTokenString(NSString *_Nullable idTokenString) {
  if (!idTokenString) {
    return nil;
  }
  OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
  if (!idTokenDecoded) {
    return nil;
  }
  return idTokenDecoded.claims[kHostedDomainIDTokenClaimKey];
}

@implementation GIDGoogleUser {
  // A queue for pending token refresh handlers so we don't fire multiple requests in parallel.
  // Access to this ivar should be synchronized.
  NSMutableArray<GIDGoogleUserCompletion> *_tokenRefreshHandlerQueue;

  // The profile is not part of the auth state, so a profile supplied to
  // -initWithAuthState:profileData: or -updateWithTokenResponse:authorizationResponse:profileData:
  // is parked here and folded into the next snapshot that -updateTokensWithAuthState: builds.
  // `_hasPendingProfile` distinguishes a supplied nil profile, which replaces the current one,
  // from no profile having been supplied, which keeps the current one.
  GIDProfileData *_pendingProfile;
  BOOL _hasPendingProfile;
}

- (GIDToken *)accessToken {
  return self.tokens.accessToken;
}

- (GIDToken *)refreshToken {
  return self.tokens.refreshToken;
}

- (nullable GIDToken *)idToken {
  return self.tokens.idToken;
}

- (nullable GIDProfileData *)profile {
  return self.tokens.profile;
}

// The token and profile properties are derived from `tokens`, so KVO observers of each one are
// notified whenever `tokens` is replaced (a change to any of them notifies observers of all of
// them).
+ (NSSet<NSString *> *)keyPathsForValuesAffectingAccessToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingRefreshToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIdToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingProfile {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

- (nullable NSString *)userID {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.subject) {
      return [idTokenDecoded.subject copy];
    }
  }
  return nil;
}

- (nullable NSArray<NSString *> *)grantedScopes {
  return self.tokens.grantedScopes;
}

- (GIDConfiguration *)configuration {
  return self.tokens.configuration;
}

- (void)refreshTokensIfNeededWithCompletion:(GIDGoogleUserCompletion)completion {
  // A single read here avoids accidentally reading tokens from multiple snapshots.
  GIDGoogleUserTokens *tokens = self.tokens;

  if (!([tokens.accessToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire ||
      (tokens.idToken &&
       [tokens.idToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire))) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(self, nil);
    });
    return;
  }
  if (tokens.refreshToken.expirationDate &&
      [tokens.refreshToken.expirationDate timeIntervalSinceNow] <= 0) {
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeRefreshTokenExpired
                                     userInfo:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(nil, error);
    });
    return;
  }

  @synchronized (_tokenRefreshHandlerQueue) {
    // Push the handler into the callback queue.
    [_tokenRefreshHandlerQueue addObject:[completion copy]];
    if (_tokenRefreshHandlerQueue.count > 1) {
      // This is not the first handler in the queue, no fetch is needed.
      return;
    }
  }
  // This is the first handler in the queue, a fetch is needed.
  NSMutableDictionary *additionalParameters = [@{} mutableCopy];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport updatedEMMParametersWithParameters:
          self.authState.lastTokenResponse.request.additionalParameters]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      self.authState.lastTokenResponse.request.additionalParameters];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:[GIDSignInPreferences loggingParameters]];

  OIDTokenRequest *tokenRefreshRequest =
      [self.authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  [OIDAuthorizationService performTokenRequest:tokenRefreshRequest
                 originalAuthorizationResponse:self.authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    if (tokenResponse) {
      [self.authState updateWithTokenResponse:tokenResponse error:nil];
    } else {
      if (error.domain == OIDOAuthTokenErrorDomain) {
        [self.authState updateWithAuthorizationError:error];
      }
    }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      // Process the handler queue to call back.
      NSArray<GIDGoogleUserCompletion> *refreshTokensHandlerQueue;
      @synchronized(self->_tokenRefreshHandlerQueue) {
        refreshTokensHandlerQueue = [self->_tokenRefreshHandlerQueue copy];
        [self->_tokenRefreshHandlerQueue removeAllObjects];
      }
      for (GIDGoogleUserCompletion completion in refreshTokensHandlerQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(error ? nil : self, error);
        });
      }
    }];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    NSArray<GIDGoogleUserCompletion> *refreshTokensHandlerQueue;
    @synchronized(self->_tokenRefreshHandlerQueue) {
      refreshTokensHandlerQueue = [self->_tokenRefreshHandlerQueue copy];
      [self->_tokenRefreshHandlerQueue removeAllObjects];
    }
    for (GIDGoogleUserCompletion completion in refreshTokensHandlerQueue) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(error ? nil : self, error);
      });
    }
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  }];
}

- (OIDAuthState *)authState {
  return ((GTMAuthSession *)self.fetcherAuthorizer).authState;
}

- (void)addScopes:(NSArray<NSString *> *)scopes
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    presentingViewController:(UIViewController *)presentingViewController
#elif TARGET_OS_OSX
            presentingWindow:(NSWindow *)presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                  completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                NSError *_Nullable error))completion {
  if (self != GIDSignIn.sharedInstance.currentUser) {
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeMismatchWithCurrentUser
                                     userInfo:nil];
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
    }
    return;
  }
  
  [GIDSignIn.sharedInstance addScopes:scopes
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
             presentingViewController:presentingViewController
#elif TARGET_OS_OSX
                     presentingWindow:presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                           completion:completion];
}

#pragma mark - Private Methods

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (nullable NSString *)emmSupport {
  return self.authState.lastAuthorizationResponse
      .request.additionalParameters[kEMMSupportParameterName];
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    _tokenRefreshHandlerQueue = [[NSMutableArray alloc] init];

    // Park the profile for the first snapshot, built by -updateTokensWithAuthState: below.
    _pendingProfile = profileData;
    _hasPendingProfile = YES;
    
    GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    _authSessionDelegate = [[GIDEMMSupport alloc] init];
    authSession.delegate = _authSessionDelegate;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    authSession.authState.stateChangeDelegate = self;
    _fetcherAuthorizer = authSession;
    
    [self updateTokensWithAuthState:authState];
  }
  return self;
}

- (void)updateWithTokenResponse:(OIDTokenResponse *)tokenResponse
          authorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                    profileData:(nullable GIDProfileData *)profileData {
  @synchronized(self) {
    // Park the profile for the snapshot built when the token response update below calls back
    // through -didChangeState:.
    _pendingProfile = profileData;
    _hasPendingProfile = YES;

    // We don't want to trigger the delegate before we update authState completely. So we unset the
    // delegate before the first update. Also the order of updates is important because
    // `updateWithAuthorizationResponse` would clear the last token reponse and refresh token.
    // TODO: Rewrite authState update logic when the issue is addressed.(openid/AppAuth-iOS#728)
    self.authState.stateChangeDelegate = nil;
    [self.authState updateWithAuthorizationResponse:authorizationResponse error:nil];
    self.authState.stateChangeDelegate = self;
    [self.authState updateWithTokenResponse:tokenResponse error:nil];
    // AppAuth does not call -didChangeState: for a nil token response, so if the profile was not
    // folded into a snapshot above, build one here.
    if (_hasPendingProfile) {
      [self updateTokensWithAuthState:self.authState];
    }
  }
}

- (void)updateTokensWithAuthState:(OIDAuthState *)authState {
  @synchronized(self) {
    GIDGoogleUserTokens *current = self.tokens;
    GIDProfileData *profile = _hasPendingProfile ? _pendingProfile : current.profile;
    _pendingProfile = nil;
    _hasPendingProfile = NO;

    // Build the access token
    GIDToken *accessToken =
        [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                               expirationDate:authState.lastTokenResponse.accessTokenExpirationDate];

    // Build the refresh token
    NSDictionary *additionalParameters = authState.lastTokenResponse.additionalParameters;
    NSNumber *refreshTokenExpiresIn = nil;
    NSDate *refreshTokenExpirationDate = nil;
    id expiresInValue = additionalParameters[@"refresh_token_expires_in"];
    if ([expiresInValue isKindOfClass:[NSNumber class]]) {
      refreshTokenExpiresIn = (NSNumber *)expiresInValue;
      NSTimeInterval interval = [refreshTokenExpiresIn doubleValue];
      refreshTokenExpirationDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    }
    GIDToken *refreshToken = [[GIDToken alloc] initWithTokenString:authState.refreshToken
                                                    expirationDate:refreshTokenExpirationDate];

    // Build the ID token
    GIDToken *idToken;
    NSString *idTokenString = authState.lastTokenResponse.idToken;
    if (idTokenString) {
      NSDate *idTokenExpirationDate =
          [[[OIDIDToken alloc] initWithIDTokenString:idTokenString] expiresAt];
      idToken = [[GIDToken alloc] initWithTokenString:idTokenString
                                       expirationDate:idTokenExpirationDate];
    } else {
      idToken = nil;
    }

    NSArray<NSString *> *grantedScopes =
        GIDGrantedScopesFromScopeString(authState.lastTokenResponse.scope);

    GIDConfiguration *configuration;
    if (current.configuration) {
      // The configuration is fixed for the lifetime of a user, so it is computed once.
      configuration = current.configuration;
    } else {
      NSString *clientID = authState.lastAuthorizationResponse.request.clientID;
      NSString *serverClientID =
          authState.lastTokenResponse.request.additionalParameters[kAudienceParameter];
      NSString *openIDRealm =
          authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter];

      configuration = [[GIDConfiguration alloc]
          initWithClientID:clientID
            serverClientID:serverClientID
              hostedDomain:GIDHostedDomainFromIDTokenString(idToken.tokenString)
               openIDRealm:openIDRealm];
    }

    // If the computed values are equal to the existing ones, keep the existing ones. In that case,
    // an update leaves `tokens` untouched and sends no KVO notifications.
    if ([current.accessToken isEqualToToken:accessToken]) {
      accessToken = current.accessToken;
    }
    if ([current.refreshToken isEqualToToken:refreshToken]) {
      refreshToken = current.refreshToken;
    }
    if ([current.idToken isEqualToToken:idToken]) {
      idToken = current.idToken;
    }
    // Both nil must be checked explicitly: isEqualToArray: returns NO when either side is nil.
    if ((!grantedScopes && !current.grantedScopes) ||
        [grantedScopes isEqualToArray:current.grantedScopes]) {
      grantedScopes = current.grantedScopes;
    }

    if (!current ||
        accessToken != current.accessToken ||
        refreshToken != current.refreshToken ||
        idToken != current.idToken ||
        grantedScopes != current.grantedScopes ||
        profile != current.profile) {
      // Replacing `tokens` notifies KVO observers of the derived properties while the lock is
      // held; see the key-value observing note on GIDGoogleUser in GIDGoogleUser.h.
      self.tokens = [[GIDGoogleUserTokens alloc] initWithAccessToken:accessToken
                                                        refreshToken:refreshToken
                                                             idToken:idToken
                                                       grantedScopes:grantedScopes
                                                       configuration:configuration
                                                             profile:profile];
    }
  }
}

#pragma mark - OIDAuthStateChangeDelegate

- (void)didChangeState:(OIDAuthState *)state {
   [self updateTokensWithAuthState:state];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  GIDProfileData *profile =
      [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];

  OIDAuthState *authState;
  if ([decoder containsValueForKey:kAuthStateKey]) { // Current encoding
    authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthStateKey];
  } else { // Old encoding
    GIDAuthentication *authentication = [decoder decodeObjectOfClass:[GIDAuthentication class]
                                                              forKey:@"authentication"];
    authState = authentication.authState;
  }

  return [self initWithAuthState:authState profileData:profile];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.profile forKey:kProfileDataKey];
  [encoder encodeObject:self.authState forKey:kAuthStateKey];
}

@end

NS_ASSUME_NONNULL_END
