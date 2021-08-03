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

public struct SVKMusicPlayerSkill: SVKAssistantSkill {
    
    public enum Action: String {
        case none
        case playStream = "play_stream"
        
        // internal action
        case stop
    }
    
    var seek: Float = 0
    var duration: Float = 0
    var status: SVKAudioControllerStatus = SVKAudioControllerStatus.paused
        
    public var bubbleKey:Int = -1
    
    public var contentURL: String? {
        return kit?.parameters?.url
    }
    
    /// The skill action
    public var action: Action = .none
    
    /// The skill data
    public var kit: SVKSkillKit? = nil
    
    init(kit: SVKSkillKit) {
        self.kit = kit
        if let action = Action(rawValue: kit.action) {
            self.action = action
        }
    }
    
    init(action: SVKMusicPlayerSkill.Action) {
        self.action = action
    }
    
    /**
     Execute some actions
     - parameter completionHandler: a completion handler called to indicate that action has been executed or not
     */
    public func execute(completionHandler: ((Bool) -> Void)? = nil) {
        switch action {
        case .playStream:
            guard let string = contentURL,
                let url = URL(string: string)  else { break }
            SVKMusicPlayer.shared.prepareToPlayMedia(at: url, from: self.seek, tag: self.bubbleKey)
            SVKMusicPlayer.shared.playMedia(completionHandler: completionHandler)
        case .stop:
            SVKMusicPlayer.shared.stop()
            completionHandler?(true)
        default:
            SVKLogger.warn("Action: \(action) not implemented")
            completionHandler?(false)
        }
    }
}

