//
//  Activity.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import Foundation
import GroupActivities
import AVFoundation

struct NotesActivity : GroupActivity {
  static let activityIdentifier = "com.epage.CollabStream.GroupNotes"

  // The movie to watch.
  let movie: Movie
  
  var metadata: GroupActivityMetadata {
    var metadata = GroupActivityMetadata()
    
    metadata.fallbackURL = movie.url
    metadata.title = movie.title
//    metadata.previewImage = UIImage(named: "ActivityImage")?.cgImage
//    metadata.type = .createTogether
    metadata.type = .watchTogether

    return metadata
  }

}

// A type that represents a movie to watch with others.
struct Movie: Hashable, Codable {
    var url: URL
    var title: String
    var description: String
    var posterTime: TimeInterval
}

/*
class NotesShare {
  private var groupSession: GroupSession<NotesActivity>?

  private func prepareSharePlay() {
    let activity = NotesActivity()
    
    Task {
      switch await activity.prepareForActivation() {
      case .activationDisabled:
        break
      case .activationPreferred:
        try? await activity.activate()
      case .cancelled:
        break
      default: ()
      }
    }
  }
  
  private func listenForGroupSession() {
    Task {
      for await session in NotesActivity.sessions() {
        groupSession = session
//        AVPlayer().playbackCoordinator.coordinateWithSession(session)
        session.join()
      }
    }
  }

}
*/
