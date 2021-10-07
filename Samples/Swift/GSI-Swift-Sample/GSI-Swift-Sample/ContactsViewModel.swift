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
import Combine

final class ContactsViewModel: ObservableObject {
  @Published private(set) var allContacts = [Contact]()
  private let contactsLoader = ContactsLoader()
  private(set) var nextPageToken: ContactsLoader.NextPageToken = .firstLoad
  var hasAllContacts: Bool {
    switch nextPageToken {
    case .firstLoad, .nextPageToken:
      return false
    case .noNextPage:
      return true
    }
  }

  func fetchContacts() {
    contactsLoader.loadContacts(nextPageToken: nextPageToken) { [weak self] contactsResult in
      guard let self = self else { return }
      switch contactsResult {
      case .success((let fetchedContacts, let nextPageToken)):
        DispatchQueue.main.async {
          self.allContacts.append(contentsOf: fetchedContacts)
          self.nextPageToken = nextPageToken
        }
      case .failure(let error):
        print("Error while requesting contacts: \(error)")
      }
    }
  }
}

// MARK: - API Response

struct ContactResponse: Decodable {
  let connections: [Contact]
  let nextPageToken: String?

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.connections = try container.decode([Contact].self, forKey: .connections)
    self.nextPageToken = try container.decodeIfPresent(String.self, forKey: .nextPageToken)
  }

  enum CodingKeys: String, CodingKey {
    case connections
    case nextPageToken
  }
}

// MARK: - Models

struct Contact: Equatable, Decodable, Identifiable {
  let name: String?
  let email: String?
  private(set) var id = UUID()

  init(from decoder: Decoder) throws {
    let connections = try decoder.container(keyedBy: ConnectionsKeys.self)
    if var emailAddresses = try? connections.nestedUnkeyedContainer(forKey: .emailAddresses) {
      let emailsContainer = try emailAddresses.nestedContainer(keyedBy: CodingKeys.self)
      self.email = try emailsContainer.decode(String.self, forKey: .email)
    } else {
      self.email = nil
    }
    if var names = try? connections.nestedUnkeyedContainer(forKey: .names) {
      let namesContainer = try names.nestedContainer(keyedBy: CodingKeys.self)
      self.name = try namesContainer.decode(String.self, forKey: .name)
    } else {
      self.name = nil
    }
  }

  enum CodingKeys: String, CodingKey {
    case email = "value"
    case name = "displayName"
  }

  enum ConnectionsKeys: String, CodingKey {
    case emailAddresses
    case names
  }
}
