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

final class BirthdayViewModel: ObservableObject {
  @Published private(set) var birthday: Birthday?
  var daysUntilBirthday: String {
    guard let bday = birthday?.date else { return "NA" }
    let now = Date()
    let calendar = Calendar.autoupdatingCurrent
    let dayComps = calendar.dateComponents([.day], from: now, to: bday)
    guard let days = dayComps.day else { return "NA" }
    return String(days)
  }
  private var cancellable: AnyCancellable?
  private let birthdayLoader = BirthdayLoader()

  func fetchBirthday() {
#warning("This uses the 'do with fresh tokens' approach, but crashes the app...")
//    birthdayLoader.birthdayPublisher { publisher in
//      self.cancellable = publisher.sink { completion in
//        switch completion {
//        case .finished:
//          break
//        case .failure(let error):
//          print("Error retrieving birthday: \(error)")
//        }
//      } receiveValue: { birthday in
//        self.birthday = birthday
//      }
//    }
    let bdayPublisher = birthdayLoader.birthday()
    self.cancellable = bdayPublisher.sink { completion in
      switch completion {
      case .finished:
        break
      case .failure(let error):
        // Do something with the error
        print("Error retrieving birthday: \(error)")
      }
    } receiveValue: { birthday in
      self.birthday = birthday
    }
  }
}
