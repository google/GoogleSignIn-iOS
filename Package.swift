// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

import PackageDescription

let googleSignInVersion = "8.0.0"

let package = Package(
  name: "GoogleSignIn",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "GoogleSignIn",
      targets: [
        "GoogleSignIn",
      ]
    ),
    .library(
      name: "GoogleSignInSwift",
      targets: [
        "GoogleSignInSwift",
      ]
    ),
  ],
  dependencies: [
    .package(
      name: "AppAuth",
      url: "https://github.com/openid/AppAuth-iOS.git",
      from: "1.7.3"),
    .package(
      name: "AppCheck",
      url: "https://github.com/google/app-check.git",
      from: "11.0.0"),
    .package(
      name: "GTMAppAuth",
      url: "https://github.com/google/GTMAppAuth.git",
      from: "4.1.1"),
    .package(
      name: "GTMSessionFetcher",
      url: "https://github.com/google/gtm-session-fetcher.git",
      from: "3.3.0"),
    .package(
      name: "OCMock",
      url: "https://github.com/firebase/ocmock.git",
      .revision("7291762d3551c5c7e31c49cce40a0e391a52e889")),
    .package(
      name: "GoogleUtilities",
      url: "https://github.com/google/GoogleUtilities.git",
      from: "8.0.0"),
  ],
  targets: [
    .target(
      name: "GoogleSignIn",
      dependencies: [
        .product(name: "AppAuth", package: "AppAuth"),
        .product(name: "AppCheckCore", package: "AppCheck"),
        .product(name: "GTMAppAuth", package: "GTMAppAuth"),
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
      ],
      path: "GoogleSignIn/Sources",
      resources: [
        .process("Resources"),
        .process("Strings"),
      ],
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("GID_SDK_VERSION", to: googleSignInVersion),
      ],
      linkerSettings: [
        .linkedFramework("CoreGraphics"),
        .linkedFramework("CoreText"),
        .linkedFramework("Foundation"),
        .linkedFramework("LocalAuthentication"),
        .linkedFramework("Security"),
        .linkedFramework("AppKit", .when(platforms: [.macOS])),
        .linkedFramework("UIKit", .when(platforms: [.iOS])),
      ]
    ),
    .target(
      name: "GoogleSignInSwift",
      dependencies: [
        "GoogleSignIn",
      ],
      path: "GoogleSignInSwift/Sources",
      resources: [
        .copy("Resources/PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "GoogleSignIn-UnitTests",
      dependencies: [
        "GoogleSignIn",
        "OCMock",
        .product(name: "AppAuth", package: "AppAuth"),
        .product(name: "AppCheckCore", package: "AppCheck"),
        .product(name: "GTMAppAuth", package: "GTMAppAuth"),
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
        .product(name: "GULMethodSwizzler", package: "GoogleUtilities"),
        .product(name: "GULSwizzlerTestHelpers", package: "GoogleUtilities"),
      ],
      path: "GoogleSignIn/Tests/Unit",
      cSettings: [
        .headerSearchPath("../../../"),
        .define("GID_SDK_VERSION", to: googleSignInVersion),
      ]
    ),
    .testTarget(
      name: "GoogleSignInSwift-UnitTests",
      dependencies: ["GoogleSignInSwift"],
      path: "GoogleSignInSwift/Tests/Unit"
    )
  ]
)
