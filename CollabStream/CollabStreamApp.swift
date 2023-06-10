//
//  CollabStreamApp.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import SwiftUI
import SwiftData

@main
struct CollabStreamApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
