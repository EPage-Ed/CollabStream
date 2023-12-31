//
//  Manager.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import Foundation
import Combine
import GroupActivities

class CoordinationManager {
  
  static let shared = CoordinationManager()
  
  private var subscriptions = Set<AnyCancellable>()
  
  // Published values that the player, and other UI items, observe.
  @Published var enqueuedMovie: Movie?
  @Published var groupSession: GroupSession<NotesActivity>?
  
  private init() {
    Task {
      // Await new sessions to watch movies together.
      for await groupSession in NotesActivity.sessions() {
        // Set the app's active group session.
        self.groupSession = groupSession
        
        // Remove previous subscriptions.
        subscriptions.removeAll()
        
        // Observe changes to the session state.
        groupSession.$state.sink { [weak self] state in
          if case .invalidated = state {
            // Set the groupSession to nil to publish
            // the invalidated session state.
            self?.groupSession = nil
            self?.subscriptions.removeAll()
          }
        }.store(in: &subscriptions)
        
        // Join the session to participate in playback coordination.
        groupSession.join()
        
        // Observe when the local user or a remote participant starts an activity.
        groupSession.$activity.sink { [weak self] activity in
          // Set the movie to enqueue it in the player.
          self?.enqueuedMovie = activity.movie
        }.store(in: &subscriptions)
      }
    }
  }
  
  // Prepares the app to play the movie.
  func prepareToPlay(_ selectedMovie: Movie) {
    // Return early if the app enqueues the movie.
    guard enqueuedMovie != selectedMovie else { return }
    
    if let groupSession = groupSession {
      // If there's an active session, create an activity for the new selection.
      if groupSession.activity.movie != selectedMovie {
        groupSession.activity = NotesActivity(movie: selectedMovie)
      }
    } else {
      
      Task {
        // Create a new activity for the selected movie.
        let activity = NotesActivity(movie: selectedMovie)
        
        // Await the result of the preparation call.
        switch await activity.prepareForActivation() {
          
        case .activationDisabled:
          // Playback coordination isn't active, or the user prefers to play the
          // movie apart from the group. Enqueue the movie for local playback only.
          self.enqueuedMovie = selectedMovie
          
        case .activationPreferred:
          // The user prefers to share this activity with the group.
          // The app enqueues the movie for playback when the activity starts.
          do {
            _ = try await activity.activate()
          } catch {
            print("Unable to activate the activity: \(error)")
          }
          
        case .cancelled:
          // The user cancels the operation. Do nothing.
          break
          
        default: ()
        }
      }
    }
  }
}

