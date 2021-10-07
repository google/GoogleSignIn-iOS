//
//  Birthday.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 10/6/21.
//

import Foundation

struct Birthday: Decodable {
  let integerDate: Birthday.IntegerDate

  var date: Date? {
    let comps = DateComponents(calendar: Calendar.autoupdatingCurrent,
                               timeZone: TimeZone.autoupdatingCurrent,
                               month: integerDate.month,
                               day: integerDate.day)
    return comps.date
}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.integerDate = try container.decode(IntegerDate.self, forKey: .integerDate)
  }
}

extension Birthday {
  enum Error: Swift.Error {
    case failedToDecodeBirthday
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
