/*
 * Copyright 2023 Google LLC
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

#import "GoogleSignIn/Sources/GIDAuthorizationUtil.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation GIDAuthorizationUtil

+ (OIDAuthorizationRequest *)
    authorizationRequestWithOptions:(GIDSignInInternalOptions *)options
                         emmSupport:(nullable NSString *)emmSupport {
  GIDSignInCallbackSchemes *schemes =
      [[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:options.configuration.clientID];
  NSString *urlString = [NSString stringWithFormat:@"%@:%@",
      [schemes clientIdentifierScheme], kBrowserCallbackPath];
  NSURL *redirectURL = [NSURL URLWithString:urlString];

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
  
  NSURL *authorizationEndpointURL = [GIDSignInPreferences authorizationEndpointURL];
  NSURL *tokenEndpointURL = [GIDSignInPreferences tokenEndpointURL];
  OIDServiceConfiguration *appAuthConfiguration =
      [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authorizationEndpointURL
                                                       tokenEndpoint:tokenEndpointURL];
  OIDAuthorizationRequest *request =
      [[OIDAuthorizationRequest alloc] initWithConfiguration:appAuthConfiguration
                                                    clientId:options.configuration.clientID
                                                      scopes:options.scopes
                                                 redirectURL:redirectURL
                                                responseType:OIDResponseTypeCode
                                        additionalParameters:additionalParameters];
  
  return request;
}

+ (nullable NSArray<NSString *> *)
    resolvedScopesFromGrantedScoped:(NSArray<NSString *> *)scopes
                      withNewScopes:(NSArray<NSString *> *)newScopes
                              error:(NSError * __autoreleasing *)error {
  NSMutableSet<NSString *> *grantedScopes = [NSMutableSet setWithArray:scopes];
  NSSet<NSString *> *requestedScopes = [NSSet setWithArray:newScopes];
  
  if ([requestedScopes isSubsetOfSet:grantedScopes]) {
    // All requested scopes have already been granted, generate an error.
    *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                 code:kGIDSignInErrorCodeScopesAlreadyGranted
                             userInfo:nil];
    return nil;
  }
  
  // Use the union of granted and requested scopes.
  [grantedScopes unionSet:requestedScopes];
  return [grantedScopes allObjects];
}

@end

NS_ASSUME_NONNULL_END
