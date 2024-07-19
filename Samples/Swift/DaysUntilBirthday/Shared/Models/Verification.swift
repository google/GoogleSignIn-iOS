/*
 * Copyright 2024 Google LLC
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

struct Verification: Decodable {
  let signal: String

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.signal = try container.decode(String.self)
  }

  init(signal: String) {
    self.signal = signal
  }

  static var noVerificationSignal: Verification? {
    return Verification(signal: "No signal found")
  }
}

struct VerificationResponse: Decodable {
  let verifications: [Verification]
  let firstVerification: Verification

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.verifications = try container.decode([Verification].self, forKey:.ageVerificationResults)
    guard let first = verifications.first else {
      throw Error.noVerificationInResult
    }
    self.firstVerification = first
  }
}

extension VerificationResponse {
  enum CodingKeys: String, CodingKey {
    case ageVerificationResults
  }
}

extension VerificationResponse {
  enum Error: Swift.Error {
    case noVerificationInResult
  }
}

/*
 {
   "name": "ageVerification",
   "verificationId": "A verification id string",
   "ageVerificationResults": [
     "AGE_PENDING"
   ]
 }
 */
