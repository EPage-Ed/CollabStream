//
//  Item.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import Foundation
import SwiftData

@Model
final class Note : Codable {
  var date: Date
  var text: String

  init(text: String, date: Date) {
    self.text = text
    self.date = date
  }
  
  enum CodingKeys: CodingKey {
//    case id
    case text
    case date
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
//    try container.encode(id, forKey: .id)
    try container.encode(text, forKey: .text)
    try container.encode(date, forKey: .date)
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
//    self.id = try container.decode(UUID.self, forKey: .id)
    self.text = try container.decode(String.self, forKey: .text)
    self.date = try container.decode(Date.self, forKey: .date)
  }

}
