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
import Kingfisher

extension SVKConversationViewController: SVKAudioControllerDelegate {
    
    public func play(sender: Any?) {
        if (sender is SVKAssistantAudioControllerTableViewCell || sender is SVKAssistantGenericTableViewCell),
           let cell = sender as? SVKAssistantGenericTableViewCell,
           let bubble = cell.concreteBubble() as? SVKGenericBubble,
           bubble.tag != -1 {
            let description = self.conversation.firstElement { $0.bubbleKey == bubble.tag }
            if let description = description as? SVKAssistantBubbleDescription {
                self.executeAction(from: description)
            }
        } else if let cell = sender as? SVKGenericDefaultCardV3TableViewCell,
                  let bubble = cell.concreteBubble(),
                  bubble.tag != -1 {
            let description = self.conversation.firstElement { $0.bubbleKey == bubble.tag }
            if let description = description as? SVKAssistantBubbleDescription,
               let mediaUrlString = description.card?.data?.mediaUrl,
               let url = URL(string: mediaUrlString) {
                playMedia(at: url, from: description.seekTime, tag: bubble.tag)
            }
        }
    }

    private func playMedia(at url: URL, from: Float, tag: Int) {
        SVKMusicPlayer.shared.prepareToPlayMedia(at: url, from: from, tag: tag)
        SVKMusicPlayer.shared.playMedia(completionHandler: nil)
    }

    public func play() {
        SVKMusicPlayer.shared.play()
    }

    public func play(from description: SVKAssistantBubbleDescription) {
        if let mediaUrlString = description.card?.data?.mediaUrl,
           let url = URL(string: mediaUrlString) {
            playMedia(at: url, from: description.seekTime, tag: description.bubbleKey)
        }
    }

    public func stop() {
        SVKMusicPlayer.shared.stop()
    }
    
    public func pause() {
        SVKMusicPlayer.shared.pause()
    }
    
    public func seek(for tag: Int, to time: Float) {
        if let indexPath = self.conversation.firstIndex(where: { $0.bubbleKey == tag }),
            var description = self.conversation[indexPath.section].elements[indexPath.row] as? SVKAssistantBubbleDescription {
            if var s = description.skill as? SVKMusicPlayerSkill {
                s.seek = time
                description.skill = s
                self.conversation[indexPath.section].elements[indexPath.row] = description
            } else if var s = description.skill as? SVKGenericAudioPlayerSkill {
                s.seek = time
                description.skill = s
                self.conversation[indexPath.section].elements[indexPath.row] = description
            } else if description.card?.version == 3 ||
                        description.card?.version == 2 ||
                        (description.card?.version == 1 && description.card?.type == .genericDefault) {
                description.seekTime = time
                self.conversation[indexPath.section].elements[indexPath.row] = description
            }
            SVKMusicPlayer.shared.seek(for: tag,to: time)
        }
    }

    public var audioContentURL: URL? {
        return SVKMusicPlayer.shared.currentURL
    }

    private func updateStatus(_ status:SVKAudioControllerStatus, at indexPath: IndexPath) {
        let description = self.conversation[indexPath.section].elements[indexPath.row]
        if var description = description as? SVKAssistantBubbleDescription {
            if var s = description.skill as? SVKMusicPlayerSkill {
                s.status = status
                description.skill = s
                self.conversation[indexPath.section].elements[indexPath.row] = description
            } else if var s = description.skill as? SVKGenericAudioPlayerSkill {
                s.status = status
                description.skill = s
                self.conversation[indexPath.section].elements[indexPath.row] = description
            }

            // To update the status stored in bubble description - only for Card v3
            if description.card?.version == 3 || description.card?.version == 2 || (description.card?.version == 1 && description.card?.type == .genericDefault) {
                description.audioStatus = status
                self.conversation[indexPath.section].elements[indexPath.row] = description
            }
        }
    }

    func reloadNowPlayingInfo(title:String, subtitle:String, seek:Float, duration:Float, image:UIImage? = nil) {
//        var info = [String : Any]()
//        info[MPMediaItemPropertyTitle] = title
//        info[MPMediaItemPropertyPlaybackDuration] = duration
//        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seek
//        info[MPMediaItemPropertyArtist] = subtitle
//        if let image = image {
//            info[MPMediaItemPropertyArtwork] =
//                MPMediaItemArtwork(boundsSize: image.size) { size in
//                    return image
//            }
//        }
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func registerNotifications() {
        
        NotificationCenter.default.removeObserver(self)
        
        func updateStatus(with notification: Notification) {
            guard let tag = notification.object as? Int,
                let index = self.conversation.firstIndex(where: { $0.bubbleKey == tag }) else { return }
            
            let status =  SVKAudioControllerStatus(notification: notification)
            self.updateStatus(status, at: index)
            DispatchQueue.main.safeAsync {
                if let cell = self.tableView.cellForRow(at: index) as? SVKAssistantGenericTableViewCell {
                    cell.status = status
                } else if let cell = self.tableView.cellForRow(at: index) as? SVKGenericDefaultCardV3TableViewCell {
                    cell.status = status
                }
            }
        }

        NotificationCenter.default.addObserver(forName: SVKKitNotificationConfigurationChanged, object: nil, queue: nil) { [weak self] (notification) in
            if let info = notification.userInfo,
               let isDeleted = info["deleteHistoryAll"] as? Bool,
               isDeleted  {
                self?.loadNewerControl?.trigger()
            }
        }
        
        NotificationCenter.default.addObserver(forName: AudioPlayerPlaybackPaused, object: nil, queue: nil) { (notification) in
            updateStatus(with: notification)
        }
        NotificationCenter.default.addObserver(forName: AudioPlayerPlaybackStopped, object: nil, queue: nil) { (notification) in
            updateStatus(with: notification)
        }
        NotificationCenter.default.addObserver(forName: AudioPlayerPlaybackStarted, object: nil, queue: nil) { (notification) in
            updateStatus(with: notification)
        }
        NotificationCenter.default.addObserver(forName: AudioPlayerPreparingToPlay, object: nil, queue: nil) { (notification) in
            updateStatus(with: notification)
        }
        
        NotificationCenter.default.addObserver(forName: AudioPlayerValueChanged, object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                if let tag = notification.object as? Int {
                    let index = self.conversation.firstIndex(where: { $0.bubbleKey == tag })
                    if let index = index {
                        let description = self.conversation[index.section].elements[index.row]
                        if var description = description as? SVKAssistantBubbleDescription {
                            if var s = description.skill as? SVKMusicPlayerSkill {
                                let cell = self.tableView.cellForRow(at: index) as? SVKAssistantGenericTableViewCell
                                if let value = notification.userInfo?["time"] as? Double {
                                    s.seek = Float(value)
                                    cell?.internalProgressView.setValue(Float(value), animated: true)
                                } else if let value = notification.userInfo?["duration"] as? Double {
                                    s.duration = Float(value)
                                    
                                    cell?.internalProgressView.duration = value
                                }
                                if self.context.isCardHackEnabled {
                                    var iconName = "iconRadio"
                                    if description.invokeResult?.intent?.intent == "news_play" {
                                        iconName = "franceinfoAvatar"
                                    }
                                    let image = UIImage(named: iconName,in: SVKBundle, compatibleWith: nil)
                                    self.reloadNowPlayingInfo(title: "Flash Info 13h", subtitle: "France Info", seek: s.seek, duration: s.duration,image: image)
                                } else {
                                    if let url = description.card?.data?.iconUrl {
                                        ImageCache.default.retrieveImageInDiskCache(forKey: url, options: [.preloadAllAnimationData]) { (result) in
                                            
                                            if case .success(let image) = result {
                                                self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                          subtitle: description.card?.data?.subText ?? "",
                                                                          seek: s.seek,
                                                                          duration: s.duration,
                                                                          image: image)
                                            } else {
                                                self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                          subtitle: description.card?.data?.subText ?? "",
                                                                          seek: s.seek,
                                                                          duration: s.duration)
                                            }
                                        }
                                    } else {
                                        self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                  subtitle: description.card?.data?.subText ?? "",
                                                                  seek: s.seek,
                                                                  duration: s.duration)
                                    }
                                }
                                
                                description.skill = s
                                self.conversation[index.section].elements[index.row] = description
                            } else if var s = description.skill as? SVKGenericAudioPlayerSkill {
                                let cell = self.tableView.cellForRow(at: index) as? SVKAssistantGenericTableViewCell
                                if let value = notification.userInfo?["time"] as? Double {
                                    s.seek = Float(value)
                                    cell?.internalProgressView.setValue(Float(value), animated: true)
                                } else if let value = notification.userInfo?["duration"] as? Double {
                                    if s.duration != Float(value) && Float(value) > 0 {
                                        s.duration = Float(value)
                                        DispatchQueue.main.async {
                                            self.tableView.reloadRows(at: [index], with: .automatic)
                                        }
                                    }
                                }
                                if self.context.isCardHackEnabled, description.contentType != .genericCard {
                                    var iconName = "iconRadio"
                                    if description.invokeResult?.intent?.intent == "news_play" {
                                        iconName = "franceinfoAvatar"
                                    }
                                    let image = UIImage(named: iconName,in: SVKBundle, compatibleWith: nil)
                                    self.reloadNowPlayingInfo(title: "Flash Info 13h", subtitle: "France Info", seek: s.seek, duration: s.duration,image: image)
                                } else {
                                    if let url = description.card?.data?.iconUrl {
                                        ImageCache.default.retrieveImageInDiskCache(forKey: url, options: [.preloadAllAnimationData]) { (result) in
                                            
                                            if case .success(let image) = result {
                                                self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                          subtitle: description.card?.data?.subText ?? "",
                                                                          seek: s.seek,
                                                                          duration: s.duration,
                                                                          image: image)
                                            } else {
                                                self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                          subtitle: description.card?.data?.subText ?? "",
                                                                          seek: s.seek,
                                                                          duration: s.duration)
                                            }
                                        }
                                    } else {
                                        self.reloadNowPlayingInfo(title: description.card?.data?.text ?? "",
                                                                  subtitle: description.card?.data?.subText ?? "",
                                                                  seek: s.seek,
                                                                  duration: s.duration)
                                    }
                                }
                                
                                description.skill = s
                                self.conversation[index.section].elements[index.row] = description
                            } else {
                                if let cell = self.tableView.cellForRow(at: index) as? SVKGenericDefaultCardV3TableViewCell {
                                    if let value = notification.userInfo?["time"] as? Double {
                                        description.seekTime = Float(value)
                                        self.conversation[index.section].elements[index.row] = description
                                        cell.seek = Float(value)
                                    } else if let value = notification.userInfo?["duration"] as? Double {
                                        if description.audioDuration != Float(value) && Float(value) > 0 {
                                            description.audioDuration = Float(value)
                                            self.conversation[index.section].elements[index.row] = description
                                            DispatchQueue.main.async {
                                                self.tableView.reloadRows(at: [index], with: .automatic)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
