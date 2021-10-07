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

import SwiftUI
import GoogleSignIn

struct BirthdayView: View {
  @ObservedObject var birthdayViewModel: BirthdayViewModel

  var body: some View {
    if let birthday = birthdayViewModel.birthday {
      VStack {
        Text(NSLocalizedString("Your birthday:", comment: "Your birthday label"))
          .accessibilityLabel("Your birthday label")
        Text(birthday.description)
          .accessibilityLabel("Your birthday text")
        Text(NSLocalizedString("Days until your birthday:", comment: "Days until birthday label"))
      }
      .navigationTitle("Your Birthday")
    } else {
      ProgressView()
        .navigationTitle("Your Birthday")
    }
  }
}
