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
 The global SmartVoiceKit context
 */
public class SVKContext {
    static public var locale = Locale.current {
        didSet {
            SVKTools.locale = locale
        }
    }
    /**
     This struct represents the data used to handle a conversation
     context.
     */
    internal var sessionId: String? = nil /// The id of the conversation current session

    /// Speech configuration
    public var speechConfiguration: SVKSpeechConfiguration?
    
    /// Set to false to disable developmentMode. Default is false
    public var isDevelopmentEnabled: Bool = false

    /// Set to false to disable developmentMode. Default is true
    public var isCardHackEnabled: Bool = false

    public var isSuppressErrorHistory: Bool = false
    /// Sound configuration
    private var _soundConfiguration: SVKSoundConfiguration?
    public internal(set) var soundConfiguration: SVKSoundConfiguration {
        get {
            if _soundConfiguration == nil {
                _soundConfiguration = SVKSoundConfiguration()
                _soundConfiguration?.resources = [
                    SVKSoundConfiguration.SVKSpeechRecognitionKeys.startListening : "Start_Listening_Orange.wav",
                    SVKSoundConfiguration.SVKSpeechRecognitionKeys.stopListening : "End_Listening_Orange.wav"
                ]
                if dedicatedPreFixLocalisationKey != "djingo"{
                    _soundConfiguration?.resources = [
                        SVKSoundConfiguration.SVKSpeechRecognitionKeys.startListening : "Start_Listening_DT.wav",
                        SVKSoundConfiguration.SVKSpeechRecognitionKeys.stopListening : "End_Listening_DT.wav"
                    ]
                }
            }
            return self._soundConfiguration!
        }
        set {
            self._soundConfiguration = newValue
        }
    }
        
    public var dedicatedPreFixLocalisationKey: String = "djingo" {
        didSet {
            dedicatedPreFixLocalisationKey = dedicatedPreFixLocalisationKey.lowercased()
        }
    }
    public var emptyScreenfontType: (UIFont, UIFont) {
        var fonts = ( UIFont.systemFont(ofSize: 20, weight: .medium),
                      UIFont.systemFont(ofSize: 16))
        if dedicatedPreFixLocalisationKey != "djingo"{
            fonts = (SVKHeaderTitleLabel.appearance().font,
                     SVKBlocDescriptionLabel.appearance().font)
        }
        return fonts
    }
    
    public var feedbackScreenfontType: (UIFont, UIFont) {
        var fonts = ( UIFont.systemFont(ofSize: 20, weight: .bold),
                      UIFont.systemFont(ofSize: 16))
        if dedicatedPreFixLocalisationKey != "djingo"{
            fonts = (SVKHeaderTitleLabel.appearance().font,
                     SVKBlocDescriptionLabel.appearance().font)
        }
        return fonts
    }
    public var isEmptyRequestRecommendationHackEnable: Bool = false
    public var isMisunderstoodRequestRecommendationHackEnable: Bool = false
    public var isShowGlobalCommandsConfirmationEnable: Bool = false
    public var isVocaliseGlobalCommandsConfirmationEnable: Bool = false
    
    static public var consentFeedbackCheck: [SVKTNCId] = []
    static public var consentFeedbackCheckRaw: [String] {
        get {
            var values: [String] = []
            consentFeedbackCheck.forEach { (id) in
                values.append(id.rawValue)
            }
            return values
        }
    }
    
    static public var consentPage: [SVKTNCId] = []
    static public var consentPageRaw: [String] {
        get {
            var values: [String] = []
            consentPage.forEach { (id) in
                values.append(id.rawValue)
            }
            return values
        }
    }

    public init() {
    }
}

public class SVKSoundConfiguration {

    public var resources: [SVKSpeechRecognitionKeys:String] = [:]
    public struct SVKSpeechRecognitionKeys : Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
extension SVKSoundConfiguration.SVKSpeechRecognitionKeys {
    public static let startListening = SVKSoundConfiguration.SVKSpeechRecognitionKeys(rawValue: "startListening")
    public static let stopListening = SVKSoundConfiguration.SVKSpeechRecognitionKeys(rawValue: "stopListening")
}

