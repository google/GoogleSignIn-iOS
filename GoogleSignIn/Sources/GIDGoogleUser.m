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

#import <os/lock.h>

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

// An immutable snapshot of a user's tokens. It is replaced as a whole, so readers never see a mix
// of old and new tokens.
@interface GIDGoogleUserTokens : NSObject

@property(nonatomic, readonly) GIDToken *accessToken;
@property(nonatomic, readonly) GIDToken *refreshToken;
@property(nonatomic, readonly, nullable) GIDToken *idToken;

- (instancetype)initWithAccessToken:(GIDToken *)accessToken
                       refreshToken:(GIDToken *)refreshToken
                            idToken:(nullable GIDToken *)idToken NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@implementation GIDGoogleUserTokens

- (instancetype)initWithAccessToken:(GIDToken *)accessToken
                       refreshToken:(GIDToken *)refreshToken
                            idToken:(nullable GIDToken *)idToken {
  self = [super init];
  if (self) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _idToken = idToken;
  }
  return self;
}

@end

@interface GIDGoogleUser ()

// The user's current tokens. The getter and setter take `_tokenLock`, so the property is atomic.
@property(atomic, strong, nullable) GIDGoogleUserTokens *tokens;

@end

@interface GIDGoogleUser (Internal)

- (void)getAccessToken:(GIDToken *_Nullable *_Nullable)accessToken
          refreshToken:(GIDToken *_Nullable *_Nullable)refreshToken
               idToken:(GIDToken *_Nullable *_Nullable)idToken;

@end

@implementation GIDGoogleUser {
  GIDConfiguration *_cachedConfiguration;
  
  // A queue for pending token refresh handlers so we don't fire multiple requests in parallel.
  // Access to this ivar should be synchronized.
  NSMutableArray<GIDGoogleUserCompletion> *_tokenRefreshHandlerQueue;

  GIDGoogleUserTokens *_tokens;

  // Guards `_tokens`, `_cachedConfiguration` and `_profile`. It is only ever held for a single
  // read or write of those ivars, never while calling out to other code.
  os_unfair_lock _tokenLock;

  // Serializes every change GoogleSignIn makes to `authState`, as well as the token snapshot
  // updates in -updateTokensWithAuthState:. It is recursive because AppAuth calls
  // -didChangeState: synchronously while an update holds it, and because KVO observers of the
  // token properties run while it is held and may call back into this user on the same thread.
  // The lock order is `_authStateLock`, then `_tokenLock`; `_tokenLock` is never held while
  // taking `_authStateLock`.
  NSRecursiveLock *_authStateLock;
}

// `profile` is readonly and its getter below is hand-written, which turns off autosynthesis, so
// the backing ivar is synthesized explicitly.
@synthesize profile = _profile;

- (nullable GIDGoogleUserTokens *)tokens {
  os_unfair_lock_lock(&_tokenLock);
  GIDGoogleUserTokens *tokens = _tokens;
  os_unfair_lock_unlock(&_tokenLock);
  return tokens;
}

- (void)setTokens:(nullable GIDGoogleUserTokens *)tokens {
  os_unfair_lock_lock(&_tokenLock);
  _tokens = tokens;
  os_unfair_lock_unlock(&_tokenLock);
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
  os_unfair_lock_lock(&_tokenLock);
  GIDProfileData *profile = _profile;
  os_unfair_lock_unlock(&_tokenLock);
  return profile;
}

// The token properties are derived from `tokens`, so KVO observers of each one are notified
// whenever `tokens` is replaced.
+ (NSSet<NSString *> *)keyPathsForValuesAffectingAccessToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingRefreshToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIdToken {
  return [NSSet setWithObject:NSStringFromSelector(@selector(tokens))];
}

- (void)getAccessToken:(GIDToken *_Nullable *_Nullable)accessToken
          refreshToken:(GIDToken *_Nullable *_Nullable)refreshToken
               idToken:(GIDToken *_Nullable *_Nullable)idToken {
  // A single read of `tokens` gives a consistent snapshot of all three.
  GIDGoogleUserTokens *tokens = self.tokens;

  if (accessToken) {
    *accessToken = tokens.accessToken;
  }
  if (refreshToken) {
    *refreshToken = tokens.refreshToken;
  }
  if (idToken) {
    *idToken = tokens.idToken;
  }
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
  NSArray<NSString *> *grantedScopes;
  [_authStateLock lock];
  NSString *grantedScopeString = self.authState.lastTokenResponse.scope;
  [_authStateLock unlock];
  if (grantedScopeString) {
    // If we have a 'scope' parameter from the backend, this is authoritative.
    // Remove leading and trailing whitespace.
    grantedScopeString = [grantedScopeString stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
    // Tokenize with space as a delimiter.
    NSMutableArray<NSString *> *parsedScopes =
        [[grantedScopeString componentsSeparatedByString:@" "] mutableCopy];
    // Remove empty strings.
    [parsedScopes removeObject:@""];
    grantedScopes = [parsedScopes copy];
  }
  return grantedScopes;
}

- (GIDConfiguration *)configuration {
  // Caches the configuration since it would not change for one GIDGoogleUser instance.
  os_unfair_lock_lock(&_tokenLock);
  GIDConfiguration *configuration = _cachedConfiguration;
  os_unfair_lock_unlock(&_tokenLock);
  if (configuration) {
    return configuration;
  }

  // Reads the auth state under `_authStateLock` so the configuration is never computed from a
  // half-updated auth state.
  [_authStateLock lock];

  os_unfair_lock_lock(&_tokenLock);
  configuration = _cachedConfiguration;
  os_unfair_lock_unlock(&_tokenLock);
  if (configuration) {
    // Another thread filled the cache while we waited for `_authStateLock`.
    [_authStateLock unlock];
    return configuration;
  }

  NSString *clientID = self.authState.lastAuthorizationResponse.request.clientID;
  NSString *serverClientID =
      self.authState.lastTokenResponse.request.additionalParameters[kAudienceParameter];
  NSString *openIDRealm =
      self.authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter];

  configuration = [[GIDConfiguration alloc] initWithClientID:clientID
                                              serverClientID:serverClientID
                                                hostedDomain:[self hostedDomain]
                                                 openIDRealm:openIDRealm];

  os_unfair_lock_lock(&_tokenLock);
  _cachedConfiguration = configuration;
  os_unfair_lock_unlock(&_tokenLock);

  [_authStateLock unlock];

  return configuration;
}

- (void)refreshTokensIfNeededWithCompletion:(GIDGoogleUserCompletion)completion {
  GIDToken *accessToken;
  GIDToken *refreshToken;
  GIDToken *idToken;
  [self getAccessToken:&accessToken refreshToken:&refreshToken idToken:&idToken];

  if (!([accessToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire ||
      (idToken && [idToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire))) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(self, nil);
    });
    return;
  }
  if (refreshToken.expirationDate && [refreshToken.expirationDate timeIntervalSinceNow] <= 0) {
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
  // Read the auth state under `_authStateLock` so building the request cannot interleave with
  // -updateWithTokenResponse:authorizationResponse:profileData:.
  [_authStateLock lock];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport updatedEMMParametersWithParameters:
          self.authState.lastTokenResponse.request.additionalParameters]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      self.authState.lastTokenResponse.request.additionalParameters];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:[GIDSignInPreferences loggingParameters]];

  OIDAuthorizationResponse *authorizationResponse = self.authState.lastAuthorizationResponse;
  OIDTokenRequest *tokenRefreshRequest =
      [self.authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  [_authStateLock unlock];

  [OIDAuthorizationService performTokenRequest:tokenRefreshRequest
                 originalAuthorizationResponse:authorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    // Update the auth state under `_authStateLock` so this refresh cannot interleave with
    // -updateWithTokenResponse:authorizationResponse:profileData:.
    [self->_authStateLock lock];
    if (tokenResponse) {
      [self.authState updateWithTokenResponse:tokenResponse error:nil];
    } else {
      if (error.domain == OIDOAuthTokenErrorDomain) {
        [self.authState updateWithAuthorizationError:error];
      }
    }
    [self->_authStateLock unlock];
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
  [_authStateLock lock];
  NSString *emmSupport = self.authState.lastAuthorizationResponse
      .request.additionalParameters[kEMMSupportParameterName];
  [_authStateLock unlock];
  return emmSupport;
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    // Initialize the locks first, -updateTokensWithAuthState: below takes `_authStateLock` and
    // `_tokenLock`.
    _tokenLock = OS_UNFAIR_LOCK_INIT;
    _authStateLock = [[NSRecursiveLock alloc] init];

    _tokenRefreshHandlerQueue = [[NSMutableArray alloc] init];
    _profile = profileData;
    
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
  [_authStateLock lock];
  os_unfair_lock_lock(&_tokenLock);
  _profile = profileData;
  os_unfair_lock_unlock(&_tokenLock);

  // We don't want to trigger the delegate before we update authState completely. So we unset the
  // delegate before the first update. Also the order of updates is important because
  // `updateWithAuthorizationResponse` would clear the last token reponse and refresh token.
  // TODO: Rewrite authState update logic when the issue is addressed.(openid/AppAuth-iOS#728)
  self.authState.stateChangeDelegate = nil;
  [self.authState updateWithAuthorizationResponse:authorizationResponse error:nil];
  self.authState.stateChangeDelegate = self;
  [self.authState updateWithTokenResponse:tokenResponse error:nil];
  [_authStateLock unlock];
}

- (void)updateTokensWithAuthState:(OIDAuthState *)authState {
  [_authStateLock lock];
  GIDGoogleUserTokens *current = self.tokens;

  GIDToken *accessToken =
      [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                             expirationDate:authState.lastTokenResponse.accessTokenExpirationDate];

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

  // Keep the existing token objects when they are unchanged, so an update that changes nothing
  // leaves `tokens` untouched and sends no KVO notifications.
  if ([current.accessToken isEqualToToken:accessToken]) {
    accessToken = current.accessToken;
  }
  if ([current.refreshToken isEqualToToken:refreshToken]) {
    refreshToken = current.refreshToken;
  }
  if ([current.idToken isEqualToToken:idToken]) {
    idToken = current.idToken;
  }

  if (!current || accessToken != current.accessToken ||
      refreshToken != current.refreshToken || idToken != current.idToken) {
    self.tokens = [[GIDGoogleUserTokens alloc] initWithAccessToken:accessToken
                                                      refreshToken:refreshToken
                                                           idToken:idToken];
  }
  [_authStateLock unlock];
}

#pragma mark - Helpers

- (nullable NSString *)hostedDomain {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.claims[kHostedDomainIDTokenClaimKey]) {
      return idTokenDecoded.claims[kHostedDomainIDTokenClaimKey];
    }
  }
  return nil;
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
  self = [super init];
  if (self) {
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
    
    self = [self initWithAuthState:authState profileData:profile];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  // Holds `_authStateLock` so the encoded profile and auth state come from the same update.
  [_authStateLock lock];
  [encoder encodeObject:self.profile forKey:kProfileDataKey];
  [encoder encodeObject:self.authState forKey:kAuthStateKey];
  [_authStateLock unlock];
}

@end

NS_ASSUME_NONNULL_END
