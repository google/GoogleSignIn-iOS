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

import SwiftUI
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    #if targetEnvironment(simulator)
    guard let apiKey = Bundle.main.infoDictionary!["APP_CHECK_WEB_API_KEY"] as? String else {
      print("Failed to get App_Check_WEB_API_KEY from Bundle.")
      return true
    }
    GIDSignIn.sharedInstance.configureDebugProvider(withAPIKey: apiKey) { error in
      if let error {
        print("Error configuring `GIDSignIn` for Firebase App Check: \(error)")
      }
    }
    #else
    GIDSignIn.sharedInstance.configure { error in
      if let error {
        print("Error configuring `GIDSignIn` for Firebase App Check: \(error)")
      }
    }
    #endif

    return true
  }
}

@main
struct AppAttestExampleApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
