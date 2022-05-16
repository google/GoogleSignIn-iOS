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

import Combine
import Foundation

/// An observable class representing the current user's `Birthday` and the number of days until that date.
final class BirthdayViewModel: ObservableObject {
  /// The `Birthday` of the current user.
  /// - note: Changes to this property will be published to observers.
  @Published private(set) var birthday: Birthday?
  /// Computed property calculating the number of days until the current user's birthday.
  var daysUntilBirthday: String {
    guard let bday = birthday?.date else {
      return NSLocalizedString("No birthday", comment: "User has no birthday")
    }
    let now = Date()
    let calendar = Calendar.autoupdatingCurrent
    let dayComps = calendar.dateComponents([.day], from: now, to: bday)
    guard let days = dayComps.day else {
      return NSLocalizedString("No birthday", comment: "User has no birthday")
    }
    return String(days)
  }
  private var cancellable: AnyCancellable?
  private let birthdayLoader = BirthdayLoader()

  /// Fetches the birthday of the current user.
  func fetchBirthday() {
    birthdayLoader.birthdayPublisher { publisher in
      self.cancellable = publisher.sink { completion in
        switch completion {
        case .finished:
          break
        case .failure(let error):
          self.birthday = Birthday.noBirthday
          print("Error retrieving birthday: \(error)")
        }
      } receiveValue: { birthday in
        self.birthday = birthday
      }
    }
  }
}
