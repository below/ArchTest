//
//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2021 Orange
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

class SVKCardV3ProminentTextView: UIView, UITextViewDelegate, CardV3Viewable {

    private let scrollView = UIScrollView()
    private let label = UILabel()

    private var scrollAnimateDL: CADisplayLink?
    private var scrollViewPointX: CGFloat = 0
    private var heightConstraint: NSLayoutConstraint?
    private var tapGesture: UITapGestureRecognizer!
    private var prominentTextURL: String?

    weak var delegate: SVKActionDelegate?
    private var bubbleDescription: SVKAssistantBubbleDescription?
    
    //TODO: This will be removed; please use SVKAppearanceSettings and dedicated json file or incode configuration
    private var textScrollingSpeed: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fill(description: SVKAssistantBubbleDescription) {
        guard let card = description.card,
              let prominentText = card.data?.prominentText else {
            return
        }

        label.font = SVKAppearanceBox.shared.appearance.cardV3Style.layout.prominentText.font.font
        label.text = prominentText

        if let string = card.data?.actionProminentText, !string.isEmpty {
            label.textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.prominentText.actionForegroundColor.color
            self.prominentTextURL = string
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(openLink))
            label.addGestureRecognizer(tapGesture)
        } else {
            label.textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.prominentText.color.color

            if tapGesture != nil {
                label.removeGestureRecognizer(tapGesture)
            }
        }

        bubbleDescription = description
        heightConstraint?.constant = label.font.lineHeight
        NSLayoutConstraint.activate([heightConstraint!])
    }

    func reset() {
        label.text = ""
        removeDisplayLink()
        scrollViewPointX = 0
        scrollView.setContentOffset(CGPoint(x: 0,
                                            y: scrollView.contentOffset.y), animated: false)
        if tapGesture != nil {
            label.removeGestureRecognizer(tapGesture)
        }
        NSLayoutConstraint.deactivate([heightConstraint!])
        prominentTextURL = nil
    }

     func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = false
        addSubview(scrollView)
        // place constrains
        scrollView.clipAnchors(to: self)
        heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: 30)

        NSLayoutConstraint.deactivate([heightConstraint!])

        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        scrollView.addSubview(label)
        label.clipAnchors(to: scrollView)
        scrollView.layoutIfNeeded()
    }

    private func handleMarqueeTextEffect(text: String) {
        let lines = text.numberOfLines(for: self.frame.width, and: label.font)
        scrollViewPointX = 0

        if lines > 1 {
            // If text is multiple line, set the timer to
            // start scrolling scrollView on horizontal axis.
            setDisplayLink()
        } else {
            removeDisplayLink()
        }
    }

    private func setDisplayLink() {
        let scrollAnimateDL = CADisplayLink(target: self, selector: #selector(scrollScrollViewHorizontally))
        scrollAnimateDL.add(to: .current, forMode: .common)
        self.scrollAnimateDL = scrollAnimateDL
    }

    @objc
    private func scrollScrollViewHorizontally() {
        if scrollView.contentOffset.x >= (label.frame.size.width) {
            scrollViewPointX = -self.frame.size.width
        } else {
            // Speed of scroll
            scrollViewPointX += textScrollingSpeed
        }
        
        self.scrollView.contentOffset = CGPoint(x: scrollViewPointX, y: self.scrollView.contentOffset.y)
    }

    @objc
    private func openLink() {
        guard let url = prominentTextURL, !url.isEmpty else {
            return
        }
        self.delegate?.open(url: url, bubbleDescription: bubbleDescription)
    }

    private func removeDisplayLink() {
        scrollAnimateDL?.invalidate()
        scrollAnimateDL = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let text = label.text else {
            return
        }

        removeDisplayLink()
        handleMarqueeTextEffect(text: text)
    }
}
