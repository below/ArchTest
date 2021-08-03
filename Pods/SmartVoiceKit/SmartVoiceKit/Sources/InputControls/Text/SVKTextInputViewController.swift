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

import UIKit

class SVKTextInputViewController: SVKAudioInputViewController {
    
    /// The inut text field
    @IBOutlet var textField: SVKTextField!
    
    /// The preferred contentsize of the view controller
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 375, height: 52)
        }
        set {
            
        }
    }
    
    public var prefixLocalisationKey = "djingo"

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        /// The input mode. Default is [.text, .audio]
        self.inputMode = [.text, .audio]
    }
    
    /// The view animator
    private var springAnimator: UIViewPropertyAnimator?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: SVKNotificationAskAssistant, object: nil, queue: nil) { notification in
            self.textField.text = notification.object as? String
            let button = self.textField.rightView as! UIButton
            button.isEnabled = true
            self.textField.becomeFirstResponder()
            self.state = .idle
        }
        
        textField.sendButton.addTarget(self, action: #selector(handleSendButtonTapped(_:)), for: .touchUpInside)
        
        if inputMode.contains(.audio) {
            textField.talkButton?.addTarget(self, action: #selector(handleTalkButtonTapped(_:)), for: .touchUpInside)
        } else {
            textField.setAudioModeEnabled(false)
        }
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.placeholder = (prefixLocalisationKey + ".input.textfield.placeholder").localized
    }
    
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return textField.resignFirstResponder()
    }
    
    override public var inputAccessoryView: UIView?  {
        return self.lineView
    }

    ///MARK:
    /*
     A view representing the inputAccessoryView
     This view is tracked to correctly layout the toolbar when the user dismiss the keyboard
     interactively
     */
    lazy var lineView: SVKTrackedView = {
        let view = SVKTrackedView(frame: .zero)
        view.isTracked = true
        if let toolbar = self.view.superview?.superview?.superview,
            let conversationView = toolbar.superview {
            // called when the view frame change
            view.frameChangedClosure = { _ in
                // adjust the view layout according to the keyboard position
                
                let frame = conversationView.convert(view.frame, from: view.superview)
                let dy = (frame.minY - toolbar.frame.height) - toolbar.frame.minY

                if let constraint = (conversationView.constraints.first { $0.identifier == "toolbarBottom" }) {
                    constraint.constant = min(0, constraint.constant + dy)
                    conversationView.layoutIfNeeded()
                }
            }
        }
        return view
    }()

    /// Reflect the state of the conversation to the UI
    override var state: SVKConverstationInputState {
        didSet {
            
            switch state {
            case .idle where inputMode.contains(.audio) && isInCall == false && isHistoryRefreshing == false:
                textField.rightView = textField.talkButton
                textField.talkButton?.isEnabled = true
                textField.isEnabled = true
     
            case .idle where inputMode.contains(.audio) && (isInCall == true || isHistoryRefreshing == true):
                textField.rightView = textField.pauseTalkButton
                textField.pauseTalkButton?.isEnabled = true
                textField.isEnabled = true
                
            case .idle where inputMode == .text:
                textField.sendButton.isEnabled = false
                
            case .sttStarting:
                textField.talkButton?.isEnabled = false
                textField.isEnabled = true
                textField.resignFirstResponder()
                showAudioSignalIndicator(animated: true)

            case .sttListening:
                textField.isEnabled = true

            case .sttStopping:
                textField.talkButton?.isEnabled = false
                textField.isEnabled = false
    
            case .sttRecognizing:
                textField.talkButton?.isEnabled = false
                textField.isEnabled = false

            case .kbdSendingText, .sttSendingText:
                textField.rightView = textField.sendButton
                textField.sendButton.isEnabled = false
                textField.text = nil
                audioSignalIndicatorView.setSilentAnimated(true)

            case .kbdTypingText where isHistoryRefreshing == false:
                textField.rightView = textField.sendButton
                textField.sendButton.isEnabled = true
                textField.isEnabled = true
            case .kbdTypingText where isHistoryRefreshing == true:
                textField.rightView = textField.sendButton
                textField.sendButton.isEnabled = false
                textField.isEnabled = true
            default: break
            }
        }
    }
    
    override func updateMicImage() {
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    
    override func updateMuteMicImage() {
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    
    //MARK: SVKTextInputViewController
    override var contentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //
    ////MARK: animations
    //extension SVKTextInputViewController {
    override func hideAudioSignalIndicator(animated: Bool) {
        guard audioSignalIndicatorView.isHidden == false else { return }
        
        let yOffset = self.preferredContentSize.height + self.audioSignalIndicatorView.frame.height / 2
        
        indicatorCenterYConstraint.constant = yOffset
        buttonCenterYConstraint?.constant = 0
        self.textField?.isHidden = false
        
        if animated {
            
            springAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
            
            springAnimator?.addAnimations {
                self.textField?.isHidden = false
                self.view.layoutIfNeeded()
            }
            springAnimator?.addCompletion { position in
                self.audioSignalIndicatorView.isHidden = true
                self.textField?.isHidden = false
            }
            springAnimator?.startAnimation()
        }   else {
            self.audioSignalIndicatorView.isHidden = true
            self.view.layoutIfNeeded()
        }
    }
    
     override func showAudioSignalIndicator(animated: Bool) {
        guard audioSignalIndicatorView.isHidden == true else { return }
        
        let yOffset = self.preferredContentSize.height + textField.frame.height / 2
            
        indicatorCenterYConstraint.constant = 0
        buttonCenterYConstraint?.constant = yOffset
        self.audioSignalIndicatorView.isHidden = false
        
        if springAnimator?.isRunning == true {
            springAnimator?.stopAnimation(true)
        }
        
        springAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
        
        springAnimator?.addAnimations {
            self.view.layoutIfNeeded()
        }
        springAnimator?.addCompletion { _ in
            self.textField.isHidden = true
        }
        
        springAnimator?.startAnimation()
    }

}


//MARK: SVKInputDelegate wrapper for @objc
extension SVKTextInputViewController {
    
    @objc
    public func handleSendButtonTapped(_ sender: Any?) {
        
        guard !self.isHistoryRefreshing else { return }
        delegate?.inputController(self, didAccept: textField.text ?? "", from: .keyboard)
    }
    
    @objc
    public func handleTalkButtonTapped(_ sender: Any?) {
        startSpeechRecognition()
    }
    
    @objc
    public func handlePauseButtonTapped(_ sender: Any?) {
        stopSpeechRecognition()
    }
}


// MARK: UITextFieldDelegate
extension SVKTextInputViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        if let text = textField.text, text.count > 0, !self.isHistoryRefreshing  {
            delegate?.inputController(self, didAccept: text, from: .keyboard)
        }
        return true
    }
    
    public func textFieldShouldClear(_: UITextField) -> Bool {
        return true
    }
    
    /**
     Called when the textField is being editing
     Here we enable or disable the send button according to the resulting text
     */
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard self.state == .idle || self.state == .kbdTypingText else { return false }
        if  let text = textField.text, text.count > 0 {
            state = .kbdTypingText
        } else {
            state = .idle
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        guard state == .idle || state == .kbdTypingText else { return false }
        
        if var currentText = textField.text, currentText.count > 0 {
            if let swiftRange = Range(range, in: currentText) {
                currentText.replaceSubrange(swiftRange, with: string)
                if (currentText.count > 0) {
                    state = .kbdTypingText
                } else {
                    state = .idle
                }
            }
        } else if string.count > 0 {
            self.state = .kbdTypingText
        } else {
            self.state = .idle
        }
        return true
    }
}
