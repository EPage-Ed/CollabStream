//
//  CollabStreamApp.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct CollabStreamApp: App {
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .task {
          do {
            // Configure the audio session for movie playback.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
          } catch {
            print("Unable to set the audio session category: \(error)")
          }
        }
    }
    .modelContainer(for: Note.self)
  }
}
