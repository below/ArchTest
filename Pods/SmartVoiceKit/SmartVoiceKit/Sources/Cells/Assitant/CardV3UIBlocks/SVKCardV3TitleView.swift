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

class SVKCardV3TitleView: UIView, CardV3Viewable {

    private let label = UILabel()
    private let subTextLabel = UILabel()
    @UseAutoLayout
    private var parentstackView = UIStackView()

    @UseAutoLayout
    private var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var playPauseButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(togglePlayStop(_:)), for: .touchUpInside)
        return button
    }()

    private var pauseImage: UIImage?
    private var playImage: UIImage?
    private(set) var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    var mediaDelegate: SVKGenericDefaultCardV3TMediaDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    func fill(description: SVKAssistantBubbleDescription) {
        let layoutApperance = SVKAppearanceBox.shared.appearance.cardV3Style.layout
        let card = description.card
        label.text = card?.data?.titleText
        label.textColor = layoutApperance.header.text.color.color
        label.font = layoutApperance.header.text.font.font

        subTextLabel.text = card?.data?.typeDescription
        subTextLabel.textColor = layoutApperance.header.subText.color.color
        subTextLabel.font = layoutApperance.header.subText.font.font

        if card?.data?.iconUrl?.isEmpty == false {
            iconImageView.isHidden = false
            setIconImage(with: card?.data?.iconUrl, placeHolderContentMode: .scaleAspectFit)
        } else {
            iconImageView.isHidden = true
        }

        parentstackView.spacing = layoutApperance.spacing.horizontal

        pauseImage = UIImage(named: "pause", in: SVKBundle,
                             compatibleWith: nil)?.withColor(layoutApperance.header.image.tintColor.color).withRenderingMode(.alwaysOriginal)
        playImage = UIImage(named: "play", in: SVKBundle,
                            compatibleWith: nil)?.withColor(layoutApperance.header.image.tintColor.color).withRenderingMode(.alwaysOriginal)
        update(with: description.audioStatus)
    }

    func reset() {
        label.text = ""
        subTextLabel.text = ""
        iconImageView.image = nil
    }

     func setup() {
        let layourApperance = SVKAppearanceBox.shared.appearance.cardV3Style.layout
        pauseImage = UIImage(named: "pause", in: SVKBundle,
                             compatibleWith: nil)?.withColor(layourApperance.header.image.tintColor.color).withRenderingMode(.alwaysOriginal)
        playImage = UIImage(named: "play", in: SVKBundle,
                            compatibleWith: nil)?.withColor(layourApperance.header.image.tintColor.color).withRenderingMode(.alwaysOriginal)

        parentstackView.axis = .horizontal
        parentstackView.alignment = .center
        parentstackView.spacing = layourApperance.spacing.horizontal
        addSubview(parentstackView)
        
        parentstackView.clipAnchors(to: self)

        let anchorSize = CGSize(width: layourApperance.header.image.size.width,
                                height: layourApperance.header.image.size.height)
        iconImageView.anchor(size: anchorSize)
        parentstackView.addArrangedSubview(iconImageView)

        let stackView = UIStackView(arrangedSubviews: [label, subTextLabel])
        stackView.axis = .vertical

        parentstackView.addArrangedSubview(stackView)
        parentstackView.addArrangedSubview(playPauseButton)
        playPauseButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        parentstackView.addArrangedSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 40).isActive = true

        update(with: .unknown)
    }

    func update(with status: SVKAudioControllerStatus) {
        switch status {
        case .paused, .unknown:
            playPauseButton.setImage(playImage, for: .normal)
            playPauseButton.isHidden = false
            playPauseButton.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()

        case .prepareToPlay:
            playPauseButton.setImage(pauseImage, for: .normal)
            playPauseButton.isHidden = true
            playPauseButton.isUserInteractionEnabled = false
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

        case .playing:
            playPauseButton.setImage(pauseImage, for: .normal)
            playPauseButton.isHidden = false
            playPauseButton.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()

        case .notMedia:
            playPauseButton.isHidden = true
            playPauseButton.isUserInteractionEnabled = false
            activityIndicator.stopAnimating()
        }
    }

    @objc
    private func togglePlayStop(_ button: UIButton) {
        guard let delegate = mediaDelegate else { return }

        if playPauseButton.image(for: .normal) == playImage {
            update(with: .prepareToPlay)
            delegate.playMedia()
        } else {
            delegate.stopMedia()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setIconImage(with url: String?, placeHolderContentMode:UIView.ContentMode = .center) {
        guard let string = url,
            let iconURL = URL(string: string) else {
                iconImageView.image = SVKTools.imageWithName("imagePlaceHolder")
                iconImageView.contentMode = placeHolderContentMode
                return
        }

        iconImageView.setImage(with: iconURL, placeholder: SVKTools.imageWithName("imagePlaceHolder")) { [weak self] (result) in
            
            if case .failure(_) = result {
                self?.iconImageView.contentMode = placeHolderContentMode
            }
        }
    }
}
