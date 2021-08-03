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

@IBDesignable
class SVKAudioProgressView: UIView, XIBAble {
    typealias View = SVKAudioProgressView
    
    @IBOutlet public var slider: UISlider! = UISlider() {
        didSet {
            setup()
        }
    }
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    
    /// the audio content duration in seconds
    public var duration: TimeInterval = 0 {
        didSet {
            let minutes = Int(duration) / 60
            let seconds = (Int(duration) % 60) % 60
            durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
            slider.maximumValue = Float(duration)
            slider.isEnabled = duration > 0
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        NSLayoutConstraint.activate([self.heightAnchor.constraint(equalToConstant: frame.height)])
    }

    private func setup() {
        slider.value = 0
        updateApperance()
    }

    open override func prepareForInterfaceBuilder() {
        setup()
    }

    public func setValue(_ value: Float, animated: Bool) {
        slider.setValue(Float(value), animated: true)
        
        let minutes = Int(value) / 60
        let seconds = (Int(value) % 60) % 60
        elapsedTimeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    open func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        slider.addTarget(target, action: action, for: controlEvents)
    }

    public var value: Float {
        set { slider.value = newValue }
        get { return slider.value }
    }

    func updateApperance(minimumTrackTintColor: UIColor = SVKAppearanceBox.shared.appearance.audioProgressView.minimumTrackTintColor.color,
                         maximumTrackTintColor: UIColor = SVKAppearanceBox.shared.appearance.audioProgressView.maximumTrackTintColor.color,
                         backgroundColor: UIColor = SVKAppearanceBox.shared.appearance.cardV3Style.backgroundColor.color,
                         thumbImage: UIImage? = SVKAppearanceBox.progressViewThumbImage,
                         elapsedTimeColor: UIColor = SVKAppearanceBox.shared.appearance.audioProgressView.elapsedTimeColor.color,
                         durationTimeColor: UIColor = SVKAppearanceBox.shared.appearance.audioProgressView.durationTimeColor.color) {
        slider.minimumTrackTintColor = minimumTrackTintColor
        slider.maximumTrackTintColor = maximumTrackTintColor
        elapsedTimeLabel.textColor = elapsedTimeColor
        durationLabel.textColor = durationTimeColor
        self.backgroundColor = backgroundColor
    }
}
