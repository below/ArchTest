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

internal class SVKTextField: UITextField, UITextFieldDelegate {
    
    public var sendButton: UIButton!
    public var talkButton: UIButton?
    public var pauseTalkButton: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.sendButton = UIButton(type: .custom)
        sendButton.setImage(SVKTools.imageWithName("sendMessageButton")?.withRenderingMode(.alwaysTemplate), for: .normal)
        sendButton.sizeToFit()
        sendButton.frame = sendButton.frame.insetBy(dx: -10, dy: 0)
        sendButton.isEnabled = false
        
        setAudioModeEnabled(true)
        
        self.rightViewMode = .always
        self.backgroundColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1)
        self.borderStyle = .none
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = 18
        self.layer.masksToBounds = true
        
        self.placeholder = "Ask to Djingo...".localized
    }
    
    public func setAudioModeEnabled(_ enabled: Bool) {
        if enabled {
            var button = UIButton(type: .custom)
            button.setImage(SVKTools.imageWithName("tapToTalkButton")?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.sizeToFit()
            button.frame = button.frame.insetBy(dx: -10, dy: 0)
            button.isEnabled = true
            talkButton = button
            
            button = UIButton(type: .custom)
            button.setImage(SVKTools.imageWithName("mic-mute-small")?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.sizeToFit()
            button.frame = button.frame.insetBy(dx: -15, dy: 0)
            button.isEnabled = true
            pauseTalkButton = button
            
            self.rightView = talkButton
        } else {
            talkButton = nil
            pauseTalkButton = nil
            self.rightView = sendButton
        }
    }
    
    
    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return CGRect(x: 16, y: 0, width: rect.width - 16, height: rect.height)
    }
    
    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return CGRect(x: 16, y: 0, width: rect.width - 16, height: rect.height)
    }
    
    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.rightViewRect(forBounds: bounds)
        if #available(iOS 13.0, *){
            return CGRect(x: rect.minX - 4, y: rect.minY, width: rect.width, height: rect.height)
        }
        return CGRect(x: rect.minX + 6, y: rect.minY, width: rect.width, height: rect.height)
    }
}
