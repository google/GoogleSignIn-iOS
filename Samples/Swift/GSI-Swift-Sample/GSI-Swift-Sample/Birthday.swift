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

struct Birthday: Decodable {
  let integerDate: Birthday.IntegerDate

  var date: Date? {
    let now = Date()
    let currentCalendar = Calendar.autoupdatingCurrent
    let currentYear = currentCalendar.dateComponents([.year], from: now)
    let comps = DateComponents(calendar: Calendar.autoupdatingCurrent,
                               timeZone: TimeZone.autoupdatingCurrent,
                               year: currentYear.year,
                               month: integerDate.month,
                               day: integerDate.day)
    guard let d = comps.date else { return nil }
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
}

extension Birthday {
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
  var description: String {
    return date?.description ?? "NA"
  }
}

struct BirthdayResponse: Decodable {
  let birthdays: [Birthday]
  let firstBirthday: Birthday

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.birthdays = try container.decode([Birthday].self, forKey: .birthdays)
    guard let first = birthdays.first else {
      throw Error.failedToDecodeBirthday
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
  enum Error: Swift.Error {
    case failedToDecodeBirthday
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
