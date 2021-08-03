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
import MediaPlayer

public let AudioPlayerValueChanged = Notification.Name(rawValue: "AudioPlayerValueChanged")
public let AudioPlayerPlaybackStopped = Notification.Name(rawValue: "AudioPlayerPlaybackStopped")
public let AudioPlayerPlaybackStarted = Notification.Name(rawValue: "AudioPlayerPlaybackStarted")
public let AudioPlayerPlaybackPaused = Notification.Name(rawValue: "AudioPlayerPlaybackPaused")
public let AudioPlayerPreparingToPlay = Notification.Name(rawValue: "AudioPlayerPreparingToPlay")

public enum SVKAudioControllerStatus {
    case unknown
    case paused
    case prepareToPlay
    case playing
    case notMedia
    //case recording

    public init(notification: Notification) {
        switch notification.name.rawValue {
        case AudioPlayerPlaybackPaused.rawValue: self = .paused
        case AudioPlayerPreparingToPlay.rawValue: self = .prepareToPlay
        case AudioPlayerPlaybackStarted.rawValue: self = .playing
        case AudioPlayerPlaybackStopped.rawValue: self = .paused
        default: self = .unknown
        }
    }
}

@objc
public protocol SVKAudioControllerDelegate {
    /**
    Called when the audio contents should be played
     - parameter sender: the sender
    */
    func play(sender: Any?)

    /// Called when the audio contents should be played
    func play()

    /// Called when the audio contents must be stopped
    func stop()

    /// Called when the audio contents must be paused
    func pause()

    /// Seek to a particular point in the audio content for a tagged cell
    func seek(for tag: Int, to time: Float)

    /// the audio content URL
    @objc optional var audioContentURL: URL? { get }
}


typealias SVKMusicPlayerPlaybackState = MPMusicPlaybackState
