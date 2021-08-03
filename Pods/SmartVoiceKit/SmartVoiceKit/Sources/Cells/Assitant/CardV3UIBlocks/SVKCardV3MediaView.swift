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


import Foundation

class SVKCardV3MediaView: UIView, CardV3Viewable {

    @UseAutoLayout
    private var stackView = UIStackView()

    private var progressView: SVKAudioProgressView = {
        let progressView: SVKAudioProgressView = SVKAudioProgressView.load()
        progressView.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return progressView
    }()

    var mediaDelegate: SVKGenericDefaultCardV3TMediaDelegate?
    var bubbleTag: Int = 0
    var seek: Float = 0 {
        didSet {
            self.progressView.setValue(self.seek, animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.addSubview(stackView)
        stackView.axis = .vertical
        stackView.clipAnchors(to: self)
        stackView.addArrangedSubview(progressView)
        seek = 0
        addTapGesture()
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnSlider))
        progressView.slider.addGestureRecognizer(tap)
    }

    func fill(description: SVKAssistantBubbleDescription) {
        progressView.updateApperance()
        progressView.duration = Double(description.audioDuration)
        seek = description.seekTime
    }

    func reset() {
        seek = 0
    }

    @objc
    private func sliderValueChanged(_ slider: UISlider) {
        mediaDelegate?.seek(value: slider.value)
    }

    @objc
    private func didTapOnSlider(gestureRecognizer: UITapGestureRecognizer) {
        let tappedPoint = gestureRecognizer.location(in: self)
        let positionOfSlider = progressView.slider.frame.origin
        let widthOfSlider = progressView.slider.frame.width
        let newValue = ((tappedPoint.x - positionOfSlider.x) * CGFloat(progressView.slider.maximumValue) / widthOfSlider)
        progressView.setValue(Float(newValue), animated: true)
        mediaDelegate?.seek(value: Float(newValue))
        mediaDelegate?.playMedia()
    }
}
