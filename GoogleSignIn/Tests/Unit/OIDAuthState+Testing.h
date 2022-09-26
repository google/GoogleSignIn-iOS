/*
 * Copyright 2021 Google LLC
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

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#endif

@interface OIDAuthState (Testing)

+ (instancetype)testInstance;

+ (instancetype)testInstanceWithIDToken:(NSString *)idToken;

+ (instancetype)testInstanceWithTokenResponse:(OIDTokenResponse *)tokenResponse;

/**
 * @idToken The ID token.
 * @accessToken The access token string.
 * @accessTokenExipresIn The life time of the access token starting from the moment when `OIDTokenResponse` is created.
 * @refreshToken The refresh token string.
 */
+ (instancetype)testInstanceWithIDToken:(NSString *)idToken
                            accessToken:(NSString *)accessToken
                   accessTokenExpiresIn:(NSTimeInterval)accessTokenExpiresIn
                           refreshToken:(NSString *)refreshToken;

@end
