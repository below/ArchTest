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

import AVKit
import MediaPlayer

public typealias AudioData = Data

class SVKAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    public static let shared = SVKAudioPlayer()
    
    var audioPlayerQueue = OperationQueue()
    
    var player: AVAudioPlayer?
    var semaphore: DispatchSemaphore?
    
    private var musicPlayerPlaybackState: SVKMusicPlayerPlaybackState = .stopped
    
    /// The sound & effects configuration
    public var soundConfiguration = SVKSoundConfiguration()
    
    /// **true** to enable sounds to be played
//    public var isEnabled: Bool = false
    
    private override init() {
        self.audioPlayerQueue.maxConcurrentOperationCount = 1
    }
    
    internal var audioSessionCategory: AVAudioSession.Category = .playAndRecord {
        didSet {
            do {
                try AVAudioSession.sharedInstance().setCategory(audioSessionCategory, mode: .default, options: [.allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch let error {
                SVKLogger.error("\(error)")
            }
        }
    }
    
    /**
     Play a sound
     
     The function plays an audio resource
     - parameter resource: The name of the audio file to play
     */
    func play(resource: String) {
//        guard isEnabled else { return }
        audioSessionCategory = .playAndRecord
        var components = resource.components(separatedBy: ".")
        let type = components.removeLast()
        let name = components.joined()
        if let path = SVKTools.path(forResource: name, ofType: type, in: SVKBundle) {
            let soundURL = URL(fileURLWithPath: path)
            do {
                player = try AVAudioPlayer(contentsOf: soundURL)
                self.play()
            } catch {}
        }
    }
    
    /**
     Sends a sample data for play.
     - parameter data: A PCM block of data to play
     */
    @discardableResult
    func enqueue(_ data: AudioData) -> DispatchSemaphore {
        let semaphore = DispatchSemaphore(value: 0)
        let semaphoreExternal = DispatchSemaphore(value: 0)
        audioPlayerQueue.addOperation {
            self.semaphore = semaphore
            self.playStream(data)
            if self.semaphore?.wait(timeout: .now() + .seconds(25)) == .timedOut {
                SVKLogger.warn("play timeout")
            }
            semaphoreExternal.signal()
        }
        return semaphoreExternal
    }

    private func play() {
        pauseMusicPlayer()
        player?.play()
    }

    /**
     Stop playback and removes all entries from the queue
     */
    func stop(resumeMusic:Bool = true) {
        if (player != nil) {
            SVKAnalytics.shared.log(event: "conversation_answer_stop")
        }
        player?.stop()
        player = nil
        audioPlayerQueue.cancelAllOperations()
        semaphore?.signal()
        if resumeMusic {
            resumeSystemMusicPlayer()
        }
    }
 
    /**
     Play a stream
     - parameter stream: The audio stream to play
     */
    func playStream(_ stream: AudioData) {
        do {
            audioSessionCategory = .playAndRecord
            player = try AVAudioPlayer(data: stream.wrapIntoWAVContainer())
            player?.delegate = self
            self.play()
        } catch let e {
            SVKLogger.error("Fail to initialize AVAudioPlayer: \(e)")
            semaphore?.signal()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        semaphore?.signal()
        resumeSystemMusicPlayer()
    }
    
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        semaphore?.signal()
        SVKLogger.error("error \(String(describing: error))")
        resumeSystemMusicPlayer()
    }
    
    
    /* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        semaphore?.signal()
        SVKLogger.error("Interrupted")
        resumeSystemMusicPlayer()
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        SVKLogger.error("Interrupted")
    }
}

//MARK: SystemMusicPlaer
extension SVKAudioPlayer {

    func resumeSystemMusicPlayer(_ completionHandler: (()->Void)? = nil) {
        let resumeOperation = BlockOperation {
            if self.musicPlayerPlaybackState == .interrupted {
                SVKMusicPlayer.shared.play()
                self.musicPlayerPlaybackState = .playing
                DispatchQueue.main.async {
                    completionHandler?()
                }
            } else if self.musicPlayerPlaybackState == .stopped {
                if self.player?.isPlaying ?? false {
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
                            
                            if !(self.player?.isPlaying ?? false) {
                                timer.invalidate()
                                self.player?.stop()
                                do {
                                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                                } catch {}
                                DispatchQueue.main.async {
                                    completionHandler?()
                                }                            }
                        }
                    }
                } else {
                    do {
                        
                        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                        
                    } catch {}
                    DispatchQueue.main.async {
                        completionHandler?()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler?()
                }
            }
            
        }
        resumeOperation.queuePriority = .veryLow
        self.audioPlayerQueue.addOperation(resumeOperation)
    }
    
    func pauseMusicPlayer() {
        
        if musicPlayerPlaybackState != .interrupted {
            musicPlayerPlaybackState = SVKMusicPlayer.shared.isPlaying ? .playing : .stopped
        }

        if musicPlayerPlaybackState == .playing {
            SVKMusicPlayer.shared.pause()
            self.musicPlayerPlaybackState = .interrupted
        }
    }
}
