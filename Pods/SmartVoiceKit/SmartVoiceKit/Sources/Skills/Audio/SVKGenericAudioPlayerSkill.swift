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

public struct SVKGenericAudioPlayerSkill: SVKAssistantSkill {
    
    /// The skill resourceLink
    public let contentURL: String?
    public let mediaURL: String?
    
    var seek: Float = 0
    var duration: Float = 0
    var status: SVKAudioControllerStatus = SVKAudioControllerStatus.paused
    public var bubbleKey:Int = -1
    
    init(kit: SVKSkillKit, intent: SVKInvokeIntent? = nil) {
        self.contentURL = kit.parameters?.urls?.first
        self.mediaURL = nil
    }
    
    init(card: SVKCard, intent: SVKInvokeIntent? = nil) {
        self.contentURL = card.data?.action
        self.mediaURL = card.data?.mediaUrl
    }
    
    /**
     Execute some actions
     - parameter completionHandler: a completion handler called to indicate that action has been executed or not
     */
    public func execute(completionHandler: ((Bool) -> Void)? = nil) {
        SVKMusicPlayer.shared.playMedia(completionHandler: completionHandler)
    }
    
    func prepare() {
        guard let string = mediaURL,
            let url = URL(string: string)  else { return }
        SVKMusicPlayer.shared.prepareToPlayMedia(at: url, from: self.seek, tag: self.bubbleKey)
    }
}
