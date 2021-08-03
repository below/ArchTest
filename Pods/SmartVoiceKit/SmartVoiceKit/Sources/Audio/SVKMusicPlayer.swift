//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2020 Orange
//
// This software is confidential and proprietary information of Orange.
// You are not allowed to disclose such Confidential Information nor to copy, use,
// modify, or distribute it in whole or in part without the prior written
// consent of Orange.
//
// Author: The current developers of this code can be
// found in the authors.txt file at the root of the project
//
// Software description: Smart Voice Kit is the iOS SDK that allows to
// integrate the Smart Voice Hub voice assistant into your app.
//
// Module description: The main framework for the Smart Voice Kit is the iOS SDK
// to integrate the Smart Voice Hub Audio Assistant inside your App.
//
import Foundation
import AVKit
import MediaPlayer


// A wrapper for AVAudioPlayer
final class SVKMusicPlayer: UIResponder, SVKAudioControllerDelegate {
    
    /// The audio player
    private var audioPlayer: AVPlayer? = nil
    
    /// Return the total duration of the audio content
    public var contentDuration: TimeInterval {
        guard let audioPlayer = audioPlayer,
            let time = audioPlayer.currentItem?.duration.seconds,
            !time.isNaN else {
                return 0
        }
        return TimeInterval(time)
    }
    
    private var isObservingPlayStatus = false
    private(set) var tag: Int = -1
    
    private var seek: Float = 0
    
    public var playbackState: SVKMusicPlayerPlaybackState = .stopped
    
    /// true if the player is playing some content
    public var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else { return false }
        return audioPlayer.timeControlStatus == .playing
    }
    
    /// a singleton
    static let shared: SVKMusicPlayer = {
        let player = SVKMusicPlayer()
//        player.addRemoteControlEventsTarget()
        return player
    }()
    
    // The URL of the content currently played
    private(set) var currentURL: URL?
    
    private var currentCompletionHandler: ((Bool) -> Void)?
    
    /**
     Prepare a media to be played
     - parameter url: the URL of the media to play
     - parameter position: the seek of the media to play
     - parameter tag: the media identifier (same as bubblekey)
     */
    func prepareToPlayMedia(at url: URL, from position: Float, tag: Int) {
        stop()
        self.tag = tag
        currentURL = url
        NotificationCenter.default.post(name: AudioPlayerPreparingToPlay, object: self.tag)
        
        if audioPlayer != nil {
            audioPlayer?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            audioPlayer?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
            audioPlayer?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: nil)
            stopObservePlayStatus()
        }
        let item = AVPlayerItem(url: url)
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        
        audioPlayer = AVPlayer(playerItem: item)

        audioPlayer?.seek(to: CMTime(seconds: Double(position), preferredTimescale: 1))
        audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.global(), using: { [weak self] (time) in
            self?.seek = Float(time.seconds)
            let notification = Notification(name: AudioPlayerValueChanged, object: self?.tag, userInfo: ["time":time.seconds])
            NotificationCenter.default.post(notification)
        })
        
        audioPlayer?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        audioPlayer?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        playbackState = .paused
    }
    
    func playMedia(completionHandler: ((Bool) -> Void)?) {
        currentCompletionHandler = completionHandler
        audioPlayer?.play()
    }
    
    /**
     Pause the current audio stream
     */
    func pause() {
        playbackState = .paused
        stopObservePlayStatus()
        audioPlayer?.pause()
        NotificationCenter.default.post(name: AudioPlayerPlaybackPaused, object: self.tag)
    }
    
    /**
     Stop the current audio stream
     */
    func stop() {
        playbackState = .stopped
        stopObservePlayStatus()
        audioPlayer?.pause()
        NotificationCenter.default.post(name: AudioPlayerPlaybackStopped, object: self.tag)
    }
    
    /**
     Play the current item
     */
    func play() {
        playbackState = .playing
        startObservePlayStatus()
        audioPlayer?.play()
        NotificationCenter.default.post(name: AudioPlayerPlaybackStarted, object: self.tag)
    }
    
    func play(sender: Any?) {
        play()
    }
    
    
    /**
     Seek at a specified point
     - parameter time: the point where to start playing
     */
    func seek(for tag:Int , to time: Float) {
        if tag == self.tag {
            audioPlayer?.seek(to: CMTime(seconds: Double(time), preferredTimescale: 1))
        }
    }
    
    //MARK: Remote Command

//    private func addRemoteControlEventsTarget() {
//        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.play()
//            return self.audioPlayer?.timeControlStatus == .playing ? .success : .commandFailed
//        }
//
//        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.stop()
//            return self.audioPlayer?.timeControlStatus == .paused ? .success : .commandFailed
//        }
//
//        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            if self.audioPlayer?.timeControlStatus == .paused {
//                self.play()
//                return self.audioPlayer?.timeControlStatus == .playing ? .success : .commandFailed
//            } else {
//                self.stop()
//                return self.audioPlayer?.timeControlStatus == .paused ? .success : .commandFailed
//            }
//        }
//    }
//
//    private func removeRemoteControlEventsTarget() {
//        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
//        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
//        MPRemoteCommandCenter.shared().togglePlayPauseCommand.removeTarget(nil)
//
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
//    }
}

//MARK: KeyValue Observing
extension SVKMusicPlayer {
    /**
     observe the rate property to detect when the content has been entirely played
     */
    func startObservePlayStatus() {
        if !isObservingPlayStatus && audioPlayer != nil {
            isObservingPlayStatus = true
            audioPlayer?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        }
    }
    
    func stopObservePlayStatus() {
        if let _ = audioPlayer?.observationInfo, isObservingPlayStatus == true {
            isObservingPlayStatus = false
            audioPlayer?.removeObserver(self, forKeyPath: "rate")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if let playRate = audioPlayer?.rate {
                if playRate == 0.0, isPlaying {
                    // For ios 13
                    self.seek = 0.0
                    let notification = Notification(name: AudioPlayerValueChanged, object: self.tag, userInfo: ["time":0.0])
                    NotificationCenter.default.post(notification)
                    // end
                    stop()
                }
            }
        }
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if self.contentDuration != 0 {
                let notification = Notification(name: AudioPlayerValueChanged, object: self.tag, userInfo: ["duration":self.contentDuration])
                NotificationCenter.default.post(notification)
            }
            if self.audioPlayer?.timeControlStatus == .playing {
                DispatchQueue.main.async {
                    self.startObservePlayStatus()
                    NotificationCenter.default.post(name: AudioPlayerPlaybackStarted, object: self.tag)
                    self.currentCompletionHandler?(true)
                }
            } else if self.audioPlayer?.timeControlStatus == .paused && self.playbackState != .stopped {
                // For ios 10
                self.seek = 0.0
                let notification = Notification(name: AudioPlayerValueChanged, object: self.tag, userInfo: ["time":0.0])
                NotificationCenter.default.post(notification)
                // end
                self.stop()
            }
        }
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status = self.audioPlayer!.status
            let itemStatus = audioPlayer?.currentItem?.status
            // Switch over status value
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                if self.contentDuration != 0 {
                    let notification = Notification(name: AudioPlayerValueChanged, object: self.tag, userInfo: ["duration":self.contentDuration])
                    NotificationCenter.default.post(notification)
                }
                if itemStatus == AVPlayerItem.Status.failed {
                    self.stop()
                    DispatchQueue.main.async {
                        self.currentCompletionHandler?(false)
                    }
                }
                break
            case .failed:
                // Player item failed. See error.
                self.stop()
                DispatchQueue.main.async {
                    self.currentCompletionHandler?(false)
                }
                break
            case .unknown:
                // Player item is not yet ready.
                break
            @unknown default:
                break
            }
        }
        
        
    }
}



