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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthentication.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"

#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDIDToken.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Minimal time interval before expiration for the access token or it needs to be refreshed.
NSTimeInterval kMinimalTimeToExpire = 60.0;

// Key constants used for encode and decode.
static NSString *const kAuthStateKey = @"authState";

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";
static NSString *const kEMMOSVersionParameterName = @"device_os";
static NSString *const kEMMPasscodeInfoParameterName = @"emm_passcode_info";

// Old UIDevice system name for iOS.
static NSString *const kOldIOSSystemName = @"iPhone OS";

// New UIDevice system name for iOS.
static NSString *const kNewIOSSystemName = @"iOS";

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
  [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
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

// A specialized GTMAppAuthFetcherAuthorization subclass with EMM support.
@interface GTMAppAuthFetcherAuthorizationWithEMMSupport : GTMAppAuthFetcherAuthorization
@end

@implementation GTMAppAuthFetcherAuthorizationWithEMMSupport

- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel {
  GTMAppAuthFetcherAuthorizationEMMChainedDelegate *chainedDelegate =
      [[GTMAppAuthFetcherAuthorizationEMMChainedDelegate alloc] initWithDelegate:delegate
                                                                        selector:sel];
  [super authorizeRequest:request
                 delegate:chainedDelegate
        didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
       completionHandler:(GTMAppAuthFetcherAuthorizationCompletion)handler {
  [super authorizeRequest:request completionHandler:^(NSError *_Nullable error) {
    [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      handler(error);
    }];
  }];
}

@end

@implementation GIDAuthentication {
  // A queue for pending authentication handlers so we don't fire multiple requests in parallel.
  // Access to this ivar should be synchronized.
  NSMutableArray *_authenticationHandlerQueue;
}

- (instancetype)initWithAuthState:(OIDAuthState *)authState {
  if (!authState) {
    return nil;
  }
  self = [super init];
  if (self) {
    _authenticationHandlerQueue = [[NSMutableArray alloc] init];
    _authState = authState;
  }
  return self;
}

#pragma mark - Public property accessors

- (NSString *)clientID {
  return _authState.lastAuthorizationResponse.request.clientID;
}

- (NSString *)accessToken {
  return _authState.lastTokenResponse.accessToken;
}

- (NSDate *)accessTokenExpirationDate {
  return _authState.lastTokenResponse.accessTokenExpirationDate;
}

- (NSString *)refreshToken {
  return _authState.refreshToken;
}

- (nullable NSString *)idToken {
  return _authState.lastTokenResponse.idToken;
}

- (nullable NSDate *)idTokenExpirationDate {
  return [[[OIDIDToken alloc] initWithIDTokenString:self.idToken] expiresAt];
}

#pragma mark - Private property accessors

- (NSString *)emmSupport {
  return
      _authState.lastAuthorizationResponse.request.additionalParameters[kEMMSupportParameterName];
}

#pragma mark - Public methods

- (id<GTMFetcherAuthorizationProtocol>)fetcherAuthorizer {
  GTMAppAuthFetcherAuthorization *authorization = self.emmSupport ?
      [[GTMAppAuthFetcherAuthorizationWithEMMSupport alloc] initWithAuthState:_authState] :
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
  authorization.tokenRefreshDelegate = self;
  return authorization;
}

- (void)doWithFreshTokens:(GIDAuthenticationAction)action {
  if (!([self.accessTokenExpirationDate timeIntervalSinceNow] < kMinimalTimeToExpire ||
      (self.idToken && [self.idTokenExpirationDate timeIntervalSinceNow] < kMinimalTimeToExpire))) {
    dispatch_async(dispatch_get_main_queue(), ^{
      action(self, nil);
    });
    return;
  }
  @synchronized (_authenticationHandlerQueue) {
    // Push the handler into the callback queue.
    [_authenticationHandlerQueue addObject:[action copy]];
    if (_authenticationHandlerQueue.count > 1) {
      // This is not the first handler in the queue, no fetch is needed.
      return;
    }
  }
  // This is the first handler in the queue, a fetch is needed.
  OIDTokenRequest *tokenRefreshRequest =
      [_authState tokenRefreshRequestWithAdditionalParameters:
          [GIDAuthentication updatedEMMParametersWithParameters:
              _authState.lastTokenResponse.request.additionalParameters]];
  [OIDAuthorizationService performTokenRequest:tokenRefreshRequest
                 originalAuthorizationResponse:_authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    if (tokenResponse) {
      [self willChangeValueForKey:NSStringFromSelector(@selector(accessToken))];
      [self willChangeValueForKey:NSStringFromSelector(@selector(accessTokenExpirationDate))];
      [self willChangeValueForKey:NSStringFromSelector(@selector(idToken))];
      [self willChangeValueForKey:NSStringFromSelector(@selector(idTokenExpirationDate))];
      [self->_authState updateWithTokenResponse:tokenResponse error:nil];
      [self didChangeValueForKey:NSStringFromSelector(@selector(accessToken))];
      [self didChangeValueForKey:NSStringFromSelector(@selector(accessTokenExpirationDate))];
      [self didChangeValueForKey:NSStringFromSelector(@selector(idToken))];
      [self didChangeValueForKey:NSStringFromSelector(@selector(idTokenExpirationDate))];
    } else {
      if (error.domain == OIDOAuthTokenErrorDomain) {
        [self->_authState updateWithAuthorizationError:error];
      }
    }
    [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      // Process the handler queue to call back.
      NSArray *authenticationHandlerQueue;
      @synchronized(self->_authenticationHandlerQueue) {
        authenticationHandlerQueue = [self->_authenticationHandlerQueue copy];
        [self->_authenticationHandlerQueue removeAllObjects];
      }
      for (GIDAuthenticationAction action in authenticationHandlerQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
          action(error ? nil : self, error);
        });
      }
    }];
  }];
}

#pragma mark - Private methods

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
  allParameters[kSDKVersionLoggingParameter] = GIDVersion();
  return allParameters;
}

+ (NSDictionary *)updatedEMMParametersWithParameters:(NSDictionary *)parameters {
  return [self parametersWithParameters:parameters
                             emmSupport:parameters[kEMMSupportParameterName]
                 isPasscodeInfoRequired:parameters[kEMMPasscodeInfoParameterName] != nil];
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

#pragma mark - GTMAppAuthFetcherAuthorizationTokenRefreshDelegate

- (nullable NSDictionary *)additionalRefreshParameters:
    (GTMAppAuthFetcherAuthorization *)authorization {
  return [GIDAuthentication updatedEMMParametersWithParameters:
      authorization.authState.lastTokenResponse.request.additionalParameters];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _authenticationHandlerQueue = [[NSMutableArray alloc] init];
    _authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthStateKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_authState forKey:kAuthStateKey];
}

@end

NS_ASSUME_NONNULL_END
