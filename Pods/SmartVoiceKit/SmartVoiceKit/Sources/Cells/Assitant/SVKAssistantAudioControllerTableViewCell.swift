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

class SVKAssistantAudioControllerTableViewCell: SVKAssistantGenericTableViewCell {
    
    /// The image for the pause button
    private var pauseImage: UIImage?
    
    /// The image for the play button
    private var playImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        pauseImage = UIImage(named: "pause-button", in: SVKBundle, compatibleWith: nil)
        playImage = UIImage(named: "play-button", in: SVKBundle, compatibleWith: nil)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = playPauseButton.center
        playPauseButton.superview?.addSubview(activityIndicator)
        
        status = .prepareToPlay
    }
    
    private func update(with status: SVKAudioControllerStatus) {
        switch self.status {
        case .playing:
            self.playPauseButton.isHidden = false
            self.playPauseButton.setImage(self.pauseImage, for: .normal)
            self.activityIndicator.stopAnimating()
            self.isUserInteractionEnabled = true
            self.bubble.descriptionLabel.text = "music.playing".localized
        case .paused:
            self.playPauseButton.isHidden = false
            self.playPauseButton.setImage(self.playImage, for: .normal)
            self.activityIndicator.stopAnimating()
            self.isUserInteractionEnabled = true
            self.bubble.descriptionLabel.text = nil
        case .prepareToPlay:
            self.playPauseButton.isHidden = true
            self.activityIndicator.startAnimating()
            self.isUserInteractionEnabled = false
            self.bubble.descriptionLabel.text = nil
        default: break
        }
    }
    
    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription else {
            return
        }
        
        let intent = bubbleDescription.invokeResult?.intent?.intent ?? "Radio"
        let audioPlayerSkill = bubbleDescription.skill as? SVKMusicPlayerSkill
        if intent == "news_play" {
            showProgressView()
            if let audioPlayerSkill = audioPlayerSkill {
                self.status = audioPlayerSkill.status
                
                self.internalProgressView.setValue(audioPlayerSkill.seek, animated: true)
                self.internalProgressView.duration = Double(audioPlayerSkill.duration)
            }
        } else {
            hideProgressView()
            if let audioPlayerSkill = audioPlayerSkill {
                self.status = audioPlayerSkill.status
            }
        }
        
        if isCardHackEnabled {
            bubble.titleLabel.text = intent == "news_play" ? "News" : "Radio"
            bubble.textLabel.text = "Flash Info 13h"
            bubble.subTextLabel.text = "France Info"
            bubble.iconImageView.image = SVKTools.imageWithName("iconRadio")
            if intent == "news_play" {
                bubble.iconImageView.image = SVKTools.imageWithName("franceinfoAvatar")
            } else {
                if let station = bubbleDescription.invokeResult?.intent?.entities?["station"]?.first {
                    bubble.textLabel.text = station
                    bubble.subTextLabel.text = station
                }
                bubble.iconImageView.image = SVKTools.imageWithName("iconRadio")
            }
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        } else if let bubbleDescription = content as? SVKAssistantBubbleDescription {
            bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        }
        
        self.setIconButtomConstraint(defaultConstant: 10, minimumConstant: 6)
        update(with: status)
    }
    
    /**
     Shows the bubble's progressView
     
     The view is added to the bubble
    */
    public override func showProgressView() {
        if internalProgressView.superview == nil {
            internalProgressView.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(internalProgressView)
            bubble.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(20)-[v]-(20)-|",
                                                                 options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                 metrics: nil,
                                                                 views: ["v" : internalProgressView]))
            bubble.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[i]-(20)-[v]-(10)-|",
                                                                 options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                 metrics: nil,
                                                                 views: ["v" : internalProgressView, "i": bubble.iconImageView as Any]))
            bubble.sourceLabel?.isHidden = true
            bubble.detailsLabel?.isHidden = true
        }
    }
    /**
     Hides the progressView
     
     The view is removed from the bubble
     */
    public override func hideProgressView() {
        internalProgressView.removeFromSuperview()
        bubble.sourceLabel?.isHidden = false
        bubble.detailsLabel?.isHidden = false
    }
    
    /**
     Toggle play and pause
     */
    @objc
    override func togglePlayStop(_ button: UIButton) {
        guard let delegate = delegate else { return }
        
        if playPauseButton.image(for: .normal) == playImage {
            status = .prepareToPlay
                delegate.play(sender: self)
        } else {
            delegate.pause()
        }
    }
    
    @objc override func sliderValueChanged(_ slider: UISlider) {
        delegate?.seek(for: tag, to: slider.value)
    }
    
}
