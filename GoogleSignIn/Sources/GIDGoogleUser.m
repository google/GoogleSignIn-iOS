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

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The ID Token claim key for the hosted domain value.
static NSString *const kHostedDomainIDTokenClaimKey = @"hd";

// Key constants used for encode and decode.
static NSString *const kAuthenticationKey = @"authentication";
static NSString *const kGrantedScopesKey = @"grantedScopes";
static NSString *const kUserIDKey = @"userID";
static NSString *const kServerAuthCodeKey = @"serverAuthCode";
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kHostedDomainKey = @"hostedDomain";

// Parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";


@implementation GIDGoogleUser

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    _authentication = [[GIDAuthentication alloc] initWithAuthState:authState];

    NSArray<NSString *> *grantedScopes;
    NSString *grantedScopeString = authState.lastTokenResponse.scope;
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
    _grantedScopes = grantedScopes;

    _serverAuthCode = [authState.lastTokenResponse.additionalParameters[@"server_code"] copy];
    _profile = [profileData copy];

    NSString *idToken = authState.lastTokenResponse.idToken;
    if (idToken) {
      OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idToken];
      if (idTokenDecoded.subject) {
        _userID = [idTokenDecoded.subject copy];
      }
      if (idTokenDecoded.claims[kHostedDomainIDTokenClaimKey]) {
        _hostedDomain = [idTokenDecoded.claims[kHostedDomainIDTokenClaimKey] copy];
      }
    }

    _serverClientID =
        [authState.lastTokenResponse.request.additionalParameters[kAudienceParameter] copy];
    _openIDRealm =
        [authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter] copy];
  }
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _authentication = [decoder decodeObjectOfClass:[GIDAuthentication class]
                                            forKey:kAuthenticationKey];
    _grantedScopes = [decoder decodeObjectOfClass:[NSArray class] forKey:kGrantedScopesKey];
    _userID = [decoder decodeObjectOfClass:[NSString class] forKey:kUserIDKey];
    _serverAuthCode = [decoder decodeObjectOfClass:[NSString class] forKey:kServerAuthCodeKey];
    _profile = [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];
    _hostedDomain = [decoder decodeObjectOfClass:[NSString class] forKey:kHostedDomainKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_authentication forKey:kAuthenticationKey];
  [encoder encodeObject:_grantedScopes forKey:kGrantedScopesKey];
  [encoder encodeObject:_userID forKey:kUserIDKey];
  [encoder encodeObject:_serverAuthCode forKey:kServerAuthCodeKey];
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:_hostedDomain forKey:kHostedDomainKey];
}

@end

NS_ASSUME_NONNULL_END
