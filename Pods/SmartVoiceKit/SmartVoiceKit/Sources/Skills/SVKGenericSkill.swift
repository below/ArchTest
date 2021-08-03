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

public struct SVKGenericSkill: SVKAssistantSkill {
    
    /// The skill resourceLink
    public let contentURL: String?
    
    static func addParameters(url: String?) -> String? {
        if let url = url, url.starts(with: "deezer:") {
            return url + "?autoplay=true&start_index=0"
        } else {
            return url
        }
    }
    
    init(kit: SVKSkillKit, intent: SVKInvokeIntent? = nil) {
        let url = SVKGenericSkill.addParameters(url: kit.parameters?.urls?.first)
        self.contentURL = url
    }
    
    init(card: SVKCard, intent: SVKInvokeIntent? = nil) {
        let url = SVKGenericSkill.addParameters(url: card.data?.action ?? card.data?.serviceLink)
        self.contentURL = url
    }
    
    /**
     Execute some actions
     */
    public func execute(completionHandler: ((Bool) -> Void)? = nil) {
        if let contentURL = self.contentURL, let url = URL(string: contentURL) {
            self.executeOpen(url: url) { (isOpen) in
                if isOpen {
                    if let completionHandler = completionHandler {
                        completionHandler(true)
                    }
                } else {
                    if contentURL.starts(with: "deezer:") {
                        let newcontentURL = contentURL.replacingCharacters(in: contentURL.startIndex..<contentURL.index(contentURL.startIndex, offsetBy: 7), with: "https:")
                        if let url = URL(string: newcontentURL) {
                            self.executeOpen(url: url) { (isOpen) in
                                if !isOpen {
                                    self.showErrorPopup()
                                }
                                if let completionHandler = completionHandler {
                                    completionHandler(isOpen)
                                }
                            }
                        } else {
                            if let completionHandler = completionHandler {
                                self.showErrorPopup()
                                completionHandler(false)
                            }
                        }
                    } else {
                        if let completionHandler = completionHandler {
                            self.showErrorPopup()
                            completionHandler(false)
                        }
                    }
                }
            }
        } else {
            completionHandler?(false)
        }
        
    }
    
}

