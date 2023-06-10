//
//  Item.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
