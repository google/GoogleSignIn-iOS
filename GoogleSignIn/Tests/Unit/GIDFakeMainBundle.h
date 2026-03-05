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

#import <Foundation/Foundation.h>

/**
 * @class GIDFakeMainBundle
 * @brief Helps fake [NSBundle mainBundle]
 */
@interface GIDFakeMainBundle : NSObject

/**
 * @fn startFakingWithClientID:
 * @brief Starts faking [NSBundle mainBundle]
 * @param clientID The fake client idenfitier for the app.
 */
- (void)startFakingWithClientID:(NSString *)clientID;

/**
 * @fn stopFaking
 * @brief Stops faking [NSBundle mainBundle]
 */
- (void)stopFaking;

#pragma mark - URL Schemes

/**
 * @fn fakeAllSchemesSupported
 * @brief Fakes all URL schemes in the info.plist.
 */
- (void)fakeAllSchemesSupported;

/**
 * @fn fakeAllSchemesSupportedAndMerged
 * @brief Fakes all URL schemes in the info.plist as a single scheme definition.
 */
- (void)fakeAllSchemesSupportedAndMerged;

/**
 * @fn fakeAllSchemesSupportedWithCasesMangled
 * @brief Fakes all URL schemes in the info.plist but flips A-Z with a-z and vice-versa.
 */
- (void)fakeAllSchemesSupportedWithCasesMangled;

/**
 * @fn fakeMissingClientIdScheme
 * @brief Fakes a missing client ID scheme in the info.plist.
 */
- (void)fakeMissingClientIdScheme;

/**
 * @fn fakeMissingAllSchemes
 * @brief Fakes missing the CFBundleURLTypes section of the info.plist entirely.
 */
- (void)fakeMissingAllSchemes;

/**
 * @fn fakeOtherSchemes
 * @brief Fakes other irrelevant schemes in the info.plist.
 */
- (void)fakeOtherSchemes;

/**
 * @fn fakeOtherSchemesAndAllSchemes
 * @brief Fakes other irrelevant schemes in the info.plist.
 */
- (void)fakeOtherSchemesAndAllSchemes;

/**
 * @fn fakeWithClientID:serverClientID:hostedDomain:openIDRealm:
 * @brief Sets values for faked Info.plist params.
 * @param clientID The fake client idenfitier for the app.
 * @param serverClientID The fake server client idenfitier for the app.
 * @param hostedDomain The fake hosted domain for the app.
 * @param openIDRealm The fake OpenID realm for the app.
 */
- (void)fakeWithClientID:(id)clientID
          serverClientID:(id)serverClientID
            hostedDomain:(id)hostedDomain
             openIDRealm:(id)openIDRealm;

@end
