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

import Foundation

/// A model type representing the current user's birthday.
struct Birthday: Decodable {
  fileprivate let integerDate: Birthday.IntegerDate

  /// The birthday as a `Date`.
  var date: Date? {
    let now = Date()
    let currentCalendar = Calendar.autoupdatingCurrent
    let currentYear = currentCalendar.dateComponents([.year], from: now)
    let comps = DateComponents(calendar: Calendar.autoupdatingCurrent,
                               timeZone: TimeZone.autoupdatingCurrent,
                               year: currentYear.year,
                               month: integerDate.month,
                               day: integerDate.day)
    guard let d = comps.date, comps.isValidDate else { return nil }
    if d < now {
      var nextYearComponent = DateComponents()
      nextYearComponent.year = 1
      let bdayNextYear = currentCalendar.date(byAdding: .year, value: 1, to: d)
      return bdayNextYear
    } else {
      return d
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.integerDate = try container.decode(IntegerDate.self, forKey: .integerDate)
  }

  init(integerDate: IntegerDate) {
    self.integerDate = integerDate
  }

  static var noBirthday: Birthday? {
    return Birthday(integerDate: IntegerDate(month: .min, day: .min))
  }
}

extension Birthday {
  /// A nested type representing the month and day values of a birthday as integers.
  struct IntegerDate: Decodable {
    let month: Int
    let day: Int
  }
}

extension Birthday {
  enum CodingKeys: String, CodingKey {
    case integerDate = "date"
  }
}

extension Birthday: CustomStringConvertible {
  /// Converts the instances `date` to a `String`.
  var description: String {
    return date?.description ?? "No birthday"
  }
}

/// A model type representing the response from the request for the current user's birthday.
struct BirthdayResponse: Decodable {
  /// The requested user's birthdays.
  let birthdays: [Birthday]
  /// The first birthday in the returned results.
  /// - note: We only care about the birthday's month and day, and so we just use the first
  /// birthday in the results.
  let firstBirthday: Birthday

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.birthdays = try container.decode([Birthday].self, forKey: .birthdays)
    guard let first = birthdays.first else {
      throw Error.noBirthdayInResult
    }
    self.firstBirthday = first
  }
}

extension BirthdayResponse {
  enum CodingKeys: String, CodingKey {
    case birthdays
  }
}

extension BirthdayResponse {
  /// An error representing what may go wrong in processing the birthday request.
  enum Error: Swift.Error {
    /// There was no birthday in the returned results.
    case noBirthdayInResult
  }
}

/*
 {
   "resourceName": "people/111941908710159755740",
   "etag": "%EgQBBy43GgQBAgUHIgxvOUdlOWN5d3lmZz0=",
   "birthdays": [
     {
       "metadata": {
         "primary": true,
         "source": {
           "type": "PROFILE",
           "id": "111941908710159755740"
         }
       },
       "date": {
         "month": 5,
         "day": 31
       }
     },
     {
       "metadata": {
         "source": {
           "type": "ACCOUNT",
           "id": "111941908710159755740"
         }
       },
       "date": {
         "year": 1982,
         "month": 5,
         "day": 31
       }
     }
   ]
 }
 */
