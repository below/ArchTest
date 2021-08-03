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

/**
    A protocol that allow to interact with a Djingo local skill
 */
protocol SVKAssistantSkill {
    
    /**
     Prepare an action to be executed
     */
    func prepare()
    
    /**
     Execute an action of the skill
     
     The action associated to the skill is executed and then the completionHandler is called.
     - parameter completionHandler: A closure call at the end of the execution. It's called with
     an argument representing the status of the execution, true if the execution succeeded false otherwise
     */
    func execute(completionHandler: ((Bool) -> Void)?)

    /// The skill urlScheme
    var urlScheme: String? { get }
    
    /// The skill content URL
    var contentURL: String? { get }
}

/// Default implementation of DjingoSkill
extension SVKAssistantSkill {
    var urlScheme: String? { return nil }
    func prepare() {
    }
    
    func executeOpen(url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            let canOpen = UIApplication.shared.canOpenURL(url)
            if canOpen {
                UIApplication.shared.open(url, completionHandler:
                    { (isOpen) in
                        if isOpen {
                                completionHandler?(true)
                        } else {
                            completionHandler?(false)
                        }
                })
            } else {
                completionHandler?(false)
            }
        }
    }
    
    func showErrorPopup() {
        let alert = UIAlertController(title: "DCalert.execute.error.title".localized,
                                      message: "DCalert.execute.error.message".localized, preferredStyle:  .alert)
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(alert, animated: true)
            let genericSkillAlertControl = SVKGenericSkillAlertControl()
            genericSkillAlertControl.perform(#selector(genericSkillAlertControl.closeErrorPopup), with: alert, afterDelay: 2.0)
        }
    }
}

private class SVKGenericSkillAlertControl:NSObject {
    @objc  func closeErrorPopup(_ alert:UIAlertController) {
        alert.dismiss(animated: true, completion: nil)
    }
}

public enum SVKDeezerMedia: String {
    case album
    case artist
}

public struct SVKDeezerSkill: SVKAssistantSkill {

    public enum Action: String {
        case none
        case playURL = "play_urls"
    }

    /// The skill action
    public var action: Action = .none

    /// The skill resourceLink
    public let contentURL: String?
    
    init(kit: SVKSkillKit, intent: SVKInvokeIntent? = nil) {
        self.contentURL = kit.parameters?.urls?.first
        
        if let action = Action(rawValue: kit.action) {
            self.action = action
        }
    }

    init(card: SVKCard, intent: SVKInvokeIntent? = nil) {
        self.contentURL = card.data?.serviceLink        
    }

    /**
     Execute some actions
     */
    
    public func execute(completionHandler: ((Bool) -> Void)? = nil) {
        
        if let contentURL = urlScheme, let url = URL(string: contentURL) {
            executeOpen(url: url) { (isOpen) in
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
    
    /// The skill formatted scheme
    public var urlScheme: String? {
        guard let link = contentURL else { return nil }
        
        let parameters = "?autoplay=true&start_index=0"
        
        if link.starts(with: "https://") {
            let url = link.replacingOccurrences(of: "https://", with: "deezer://") + parameters
            guard let URL = URL(string: url), !UIApplication.shared.canOpenURL(URL) else {
                return url
            }
            return link + parameters
        } else if link.starts(with: "dzradio:///") {
            return link.replacingOccurrences(of: "dzradio://", with: "deezer://www.deezer.com/radio") + parameters
        } else if link.starts(with: "dzmedia:///") {
            return link.replacingOccurrences(of: "dzmedia://", with: "deezer://www.deezer.com") + parameters
        }
        return nil
    }
}

