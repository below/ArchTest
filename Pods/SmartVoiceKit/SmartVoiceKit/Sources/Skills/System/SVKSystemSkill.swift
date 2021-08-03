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


public struct SVKSystemSkill: SVKAssistantSkill {
    
    public enum Action: String {
        case none
        case stop
    }

    public var contentURL: String? = nil

    /// The skill action
    public var action: Action = .none
    
    /// The skill data
    public let kit: SVKSkillKit
    
    init(kit: SVKSkillKit) {
        self.kit = kit
        if let action = Action(rawValue: kit.action) {
            self.action = action
        }
    }
    
    /**
     Execute some actions
     */
    public func execute(completionHandler: ((Bool) -> Void)? = nil) {
        switch action {
        case .stop:
            SVKMusicPlayerSkill(action: SVKMusicPlayerSkill.Action.stop).execute(completionHandler: completionHandler)            
        default:
            completionHandler?(false)
            break
        }
    }
}

