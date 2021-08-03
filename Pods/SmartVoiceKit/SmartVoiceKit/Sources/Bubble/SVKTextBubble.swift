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

open class SVKTextBubble: SVKBubble {

    /// The default font
    static public let defaultFont = UIFont.systemFont(ofSize: 16)
    
    /// The default content inset
    static public let defaultContentInset = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
    
    override public var contentInset: UIEdgeInsets {
        didSet {
            setupAutolayout()
        }
    }
    /*
     A label wich display the bubble text
     */
    private let label = UILabel()
    
    open override func setup() {
        super.setup()        
        setupLabel()
        self.contentInset = SVKTextBubble.defaultContentInset
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    open override func layoutSubviews() {
        if label.frame.size == .zero {
            label.frame = self.bounds.insetBy(dx: contentInset.left, dy: contentInset.top)
        }
    }
    
    private func setupAutolayout() {
        if translatesAutoresizingMaskIntoConstraints == false {
            label.translatesAutoresizingMaskIntoConstraints = false
            self.removeConstraints(constraints)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[label]-(right)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["left": contentInset.left + pinStyle.insets.left, "right": contentInset.right + pinStyle.insets.right],
                                                               views: ["label": label]))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[label]-(bottom)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["top": contentInset.top, "bottom": contentInset.bottom],
                                                               views: ["label": label]))
            setNeedsLayout()
        }
    }

    private func setupLabel() {
        label.frame = self.bounds.insetBy(dx: contentInset.left, dy: contentInset.top)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.font = SVKTextBubble.defaultFont

        self.addSubview(label)
        label.text = "Hello !"
    }

    /// the text of the bubble
    public var text: String? {
        get {
            return label.text
        }
        set {
            if let newValue = newValue,
                newValue.contains("<s xml:"),
                let data = newValue.data(using: String.Encoding.unicode) {
                do {
                    let attributedText = try NSMutableAttributedString(data: data,
                                                                       options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                                                                       documentAttributes: nil)

                    let attributes = [NSAttributedString.Key.font: label.font,
                                      NSAttributedString.Key.foregroundColor: label.textColor]
                    attributedText.addAttributes(attributes as [NSAttributedString.Key : Any], range: NSMakeRange(0, attributedText.length))
                    label.attributedText = attributedText
                } catch {
                    label.text = newValue
                }
            } else {
                label.text = newValue
            }
        }
    }
    
    /// the text of the bubble
    public var attributedText: NSAttributedString? {
        get {
            return label.attributedText
        }
        set {
            if let newValue = newValue {
                label.attributedText = newValue
            }
        }
    }

    /// The text color
    public var textColor: UIColor {
        get {
            return label.textColor
        }
        set {
            label.textColor = newValue
        }
    }

    /// The text font
    public var font: UIFont {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }
    
    open override func prepareForInterfaceBuilder() {
        setup()
    }
}

