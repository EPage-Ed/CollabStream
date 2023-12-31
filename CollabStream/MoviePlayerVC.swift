//
//  MoviePlayerVC.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import AVKit
import Combine
import GroupActivities

class PosterImageView: UIImageView {
  
  private var poster: Poster?
  
  init() {
    super.init(frame: .zero)
    backgroundColor = .black
    translatesAutoresizingMaskIntoConstraints = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var movie: Movie? {
    didSet {
      updateImage(image: nil)
      guard let movie = movie else { return }
      poster = Poster(url: movie.url, posterTime: movie.posterTime)
      poster!.loadImage { [weak self] image in
        self?.updateImage(image: image)
      }
    }
  }
  
  private func updateImage(image: UIImage?) {
    DispatchQueue.main.async {
      self.image = image
    }
  }
}

extension AVCoordinatedPlaybackSuspension.Reason {
  static var whatHappened = AVCoordinatedPlaybackSuspension.Reason(rawValue: "com.example.groupwatching.suspension.what-happened")
}

class MoviePlayerViewController: UIViewController {
  
  // The app's player object.
  private let player = AVPlayer()
  
  // The group session to coordinate playback with.
  private var groupSession: GroupSession<NotesActivity>? {
    didSet {
      guard let session = groupSession else {
        // Stop playback if a session terminates.
        player.rate = 0
        return
      }
      // Coordinate playback with the active session.
      player.playbackCoordinator.coordinateWithSession(session)
    }
  }
  
  // The movie the player enqueues for playback.
  private var movie: Movie? {
    didSet {
      guard let movie = movie else { return }
      updatePoster(for: movie)
      let playerItem = AVPlayerItem(url: movie.url)
      player.replaceCurrentItem(with: playerItem)
      print("🍿 \(movie.title) enqueued for playback.")
    }
  }
  
  var isWhatHappenedEnabled = false
  
  // Start a custom suspension. Rewind 10 seconds and play at double speed
  // until the viewer catches up with the group, and then end the suspension.
  func performWhatHappened() {
    
    // Rewind 10 seconds.
    let rewindDuration = CMTime(value: 10, timescale: 1)
    let rewindTime = player.currentTime() - rewindDuration
    
    // Start a custom suspension.
    let suspension = player.playbackCoordinator.beginSuspension(for: .whatHappened)
    player.seek(to: rewindTime)
    player.rate = 2.0
    
    DispatchQueue.main.asyncAfter(deadline: .now() + rewindDuration.seconds) {
      // End the suspension and resume playback with the group.
      suspension.end()
    }
  }
  
  init() {
    super.init(nibName: nil, bundle: nil)
    
    // The movie subscriber.
    CoordinationManager.shared.$enqueuedMovie
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .assign(to: \.movie, on: self)
      .store(in: &subscriptions)
    
    // The group session subscriber.
    CoordinationManager.shared.$groupSession
      .receive(on: DispatchQueue.main)
      .assign(to: \.groupSession, on: self)
      .store(in: &subscriptions)
    
    player.publisher(for: \.timeControlStatus, options: [.initial])
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        if [.playing, .waitingToPlayAtSpecifiedRate].contains($0) {
          // Only show the poster view if playback is in a paused state.
          self?.posterView.isHidden = true
        }
      }
      .store(in: &subscriptions)
    
    // Observe audio session interruptions.
    NotificationCenter.default
      .publisher(for: AVAudioSession.interruptionNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        
        // Wrap the notification in helper type that extracts the interruption type and options.
        guard let result = InterruptionResult(notification) else { return }
        
        // Resume playback, if appropriate.
        if result.type == .ended && result.options == .shouldResume {
          self?.player.play()
        }
      }.store(in: &subscriptions)
  }
  
  private var subscriptions = Set<AnyCancellable>()
  private let posterView = PosterImageView()
  
  private lazy var playerViewController: AVPlayerViewController = {
    let controller = AVPlayerViewController()
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.player = player
    return controller
  }()
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    modalPresentationStyle = .fullScreen
    guard let playerView = playerViewController.view else {
      fatalError("Unable to get player view controller view.")
    }
    addChild(playerViewController)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(playerView)
    playerViewController.didMove(toParent: self)
    playerView.pinToSuperviewEdges()
    
    playerViewController.contentOverlayView?.addSubview(posterView)
    posterView.pinToSuperviewEdges()
  }
  
  func updatePoster(for movie: Movie) {
    posterView.movie = movie
    guard let currentRate = player.currentItem?.timebase?.rate else { return }
    DispatchQueue.main.async {
      self.posterView.isHidden = currentRate > 0
    }
  }
}

struct InterruptionResult {
  
  let type: AVAudioSession.InterruptionType
  let options: AVAudioSession.InterruptionOptions
  
  init?(_ notification: Notification) {
    // Determine the interruption type and options.
    guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
          let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else {
      return nil
    }
    self.type = type
    self.options = options
  }
}


extension UIColor {
  static let baseBackground = UIColor(white: 0.05, alpha: 1.0)
  static let contentBackground = UIColor(white: 0.08, alpha: 1.0)
  
  static let selectedBackground = UIColor(white: 0.15, alpha: 1.0)
  static let highlightedBackground = UIColor(white: 0.20, alpha: 1.0)
}

public extension UIView {
  
  func pinToSuperviewEdges(padding: CGFloat = 0.0) {
    guard let superview = superview else { return }
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
      leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding),
      trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding)
    ])
  }
}

