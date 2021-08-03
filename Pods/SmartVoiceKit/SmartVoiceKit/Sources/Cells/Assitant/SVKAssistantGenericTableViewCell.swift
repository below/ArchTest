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
import Kingfisher

class SVKAssistantGenericTableViewCell: SVKTableViewCell, SVKTableViewCellProtocol {

    @IBOutlet public var viewTextBottomConstraint: NSLayoutConstraint!
    @IBOutlet public var viewTextProgressViewConstraint: NSLayoutConstraint!
    @IBOutlet public var viewTextActionViewConstraint: NSLayoutConstraint!
    @IBOutlet public var progressViewActionViewConstraint: NSLayoutConstraint!
    @IBOutlet public var progressViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var subTitleViewSourceViewConstraint: NSLayoutConstraint!
    @IBOutlet var textLabelSubTextLabelConstraint: NSLayoutConstraint!
    @IBOutlet var subTitleViewBottomConstaint: NSLayoutConstraint!
    
    @IBOutlet var actionView: UIView!
    @IBOutlet var textView: UIView!
    @IBOutlet var progressView: UIView!
    @IBOutlet var rafterImageView: UIImageView!
    
    @IBOutlet var iconBottomConstraint: NSLayoutConstraint?
    @IBOutlet public var bubble: SVKGenericBubble!
    @IBOutlet public var playPauseButton: UIButton!{
        didSet {
            playPauseButton.addTarget(self, action: #selector(togglePlayStop(_ :)), for: .touchUpInside)
        }
    }
    
    /// true if state is playing false otherwise
    public var status: SVKAudioControllerStatus = .paused {
        didSet {
            DispatchQueue.main.async {
                self.update(with: self.status)
            }
        }
    }
    
    private(set) var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    /// The image for the pause button
    private var pauseImage: UIImage?
    
    /// The image for the play button
    private var playImage: UIImage?
    
    lazy var internalProgressView: SVKAudioProgressView = {
        let progressView: SVKAudioProgressView = SVKAudioProgressView.load()
        progressView.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        progressView.value = 0
        return progressView
    }()
    
    var isProgressViewVisible = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        rafterImageView?.image = UIImage(named: "chevron_w", in: SVKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        rafterImageView?.tintColor = SVKConversationAppearance.shared.tintColor
        setup()
        setupInitialContext()
    }
    
    private func setup() {
        pauseImage = UIImage(named: "pause", in: SVKBundle, compatibleWith: nil)
        playImage = UIImage(named: "play", in: SVKBundle, compatibleWith: nil)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        if playPauseButton != nil {
            playPauseButton?.superview?.addSubview(activityIndicator)
            status = .unknown
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: playPauseButton.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
                ])
            self.playPauseButton.isHidden = true
        }
    }
    
    /**
     Toggle play and pause
     */
    @objc
    func togglePlayStop(_ button: UIButton) {
        guard let delegate = delegate else { return }
        
        if playPauseButton.image(for: .normal) == playImage {
            status = .prepareToPlay
            delegate.play(sender: self)
        } else {
            delegate.stop()
        }
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        delegate?.seek(for: bubble.tag, to: slider.value)
    }
    
    /**
     Shows the bubble's progressView
     
     The view is added to the bubble
     */
    public func showProgressView() {
        if internalProgressView.superview == nil {
            internalProgressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.addSubview(internalProgressView)
            progressView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[v]-(0)-|",
                                                                 options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                 metrics: nil,
                                                                 views: ["v" : internalProgressView]))
            
            progressView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[v]-(0)-|",
                                                                       options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics: nil,
                                                                       views: ["v" : internalProgressView]))
            
            isProgressViewVisible = true
            internalProgressView.superview?.setNeedsUpdateConstraints()
            updateViewTextAndViewActionConstraint()
            
        }
    }
    
    /**
     Hides the progressView
     
     The view is removed from the bubble
     */
    public func hideProgressView() {
        internalProgressView.removeFromSuperview()
        bubble.sourceLabel?.isHidden = false
        bubble.detailsLabel?.isHidden = false
        isProgressViewVisible = false
        internalProgressView.superview?.setNeedsUpdateConstraints()
        updateViewTextAndViewActionConstraint()
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
    
    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    /**
     Sets the bubble style.
     The function applies the correct bottom layout and set the avatar if needed
     - parameter style: the bubble style
     */
    func setBubbleStyle(_ style: SVKBubbleStyle) {
        bubble.style = style

        switch style {
        case .bottom(.left):
            avatar.image = SVKTools.imageWithName("djingo-avatar")
            topSpaceConstant = 5
        case .default(.left):
            avatar.image = SVKTools.imageWithName("djingo-avatar")
        default: break
        }
        configureColors()
    }
    func configureColors(){
        bubble.foregroundColor = SVKAppearanceBox.cardBackgroundColor
        bubble.borderColor = SVKAppearanceBox.cardBorderColor
        bubble.cornerRadius = SVKAppearanceBox.cardCornerRadius
        bubble.titleLabel.textColor = SVKAppearanceBox.cardTextColor
        bubble.subTextLabel.textColor = SVKAppearanceBox.cardSupplementaryTextColor
        bubble.subTitleLabel.textColor = SVKAppearanceBox.cardTextColor
        bubble.textLabel.textColor = SVKAppearanceBox.cardTextColor
        bubble.sourceLabel?.textColor = SVKAppearanceBox.cardTextColor
        bubble.descriptionLabel.textColor = SVKAppearanceBox.cardTextColor
        bubble.detailsLabel?.textColor = SVKAppearanceBox.cardTextColor
    }
    // Utility function
    internal func setTextLabels(with items: [String]?) {
        bubble.extendSubTextLabel(true)
        
        bubble.textLabel.text = nil
        bubble.subTextLabel.text = nil
        
        guard let items = items else {
            return
        }
        
        var index = 0
        var text = "\u{2022} \(items[index])"
        
        while index < items.count - 1 {
            if index == 9 { break }
            index += 1
            text += "\n\u{2022} \(items[index])"
        }
        bubble.subTextLabel.text = text
        
        let itemsLeft = items.count - 1 - index
        if itemsLeft > 0 {
//            let format = "memolist.items.subtext.format".localized
//            let itemKey = itemsLeft == 1 ? "memolist.item" : "memolist.items"
//            bubble.sourceLabel?.text = text + "\n\n" + String(format: format, itemsLeft, itemKey.localized)
            bubble.sourceLabel?.text = text + "\n\n" + "memolist.items.subtext.format".localized(value: itemsLeft)
            
        }
    }

    private func setupInitialContext() {
        bubble.textLabel.text = nil
        bubble.subTextLabel.text = nil
        bubble.titleLabel.text = nil
        bubble.subTitleLabel.text = nil
        bubble.subTitleLabel.isHidden = false
        bubble.descriptionLabel?.text = nil
        bubble.sourceLabel?.text = nil
        bubble.iconImageView.image = nil
        bubble.imageView?.image = nil
        bubble.detailsLabel?.text = nil
        bubble.extendTextLabel(false)
        bubble.actionView?.alpha = 1.0
        bubble.tapAction = nil
        bubble.extendSubTextLabel(false)
        
        NSLayoutConstraint.deactivate([viewTextBottomConstraint,
                                       viewTextProgressViewConstraint,
                                       viewTextActionViewConstraint,
                                       progressViewActionViewConstraint,
                                       progressViewBottomConstraint,
                                       textLabelSubTextLabelConstraint])

        actionView.alpha = 0
        bubble.sourceLabel?.alpha = 0.0
        bubble.subTitleLabel.textColor = UIColor.black
        
        hideProgressView()
        self.playPauseButton.isHidden = true
        self.activityIndicator.stopAnimating()
        
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        bubble.prepareForReuse()
        setupInitialContext()
    }
    
    private func getType(bubbleDescription:SVKAssistantBubbleDescription) -> SVKCardDataTypeDescription {
        var type = SVKCardDataTypeDescription.case(with: bubbleDescription.card?.data?.typeDescription)
        if type == .unknown {
            if case  SVKCardType.iot? = bubbleDescription.card?.type {
                type = .lights
            }
        }
        return type
    }
    
    //MARK: Reusable conforms
    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let bubbleDescription = content as? SVKAssistantBubbleDescription else { return }

        bubble.tag = bubbleDescription.bubbleKey
        setBubbleStyle(bubbleDescription.bubbleStyle)
        

        
        let type = getType(bubbleDescription: bubbleDescription)
        if isCardHackEnabled && [.date,.currentTime,.lights,.timerDelete, .timerSet, .timerGet].contains(type)  {
            fillGenericHakedCard(with: bubbleDescription)
            return
        }
        
        switch bubbleDescription.contentType {

        case .genericCard, .timerCard, .iotCard,.memolistCard:
            fillGenericCard(with: bubbleDescription)
            return
        case .audioController:
            fillAudioCard(with: bubbleDescription)
            return
        case .musicCard:
            fillMusicCard(with: bubbleDescription)
            return
        default:
            break
        }
        
        // mask the avatar if needed
        let isAvatarMasked = bubbleDescription.appearance.avatarURL == nil && bubbleDescription.appearance.avatarImage == nil
        layoutAvatar(hidden: isAvatarMasked)


        setIconButtomConstraint(defaultConstant: 10, minimumConstant: 6)
    }
    
    /**
     Cancel the current download task.
     
     Calling this function may increase system performance,
     save battery life and network consumption
     */
    func cancelDownloadTask() {
        bubble.iconImageView.kf.cancelDownloadTask()
        bubble.imageView?.kf.cancelDownloadTask()
    }
}

//MARK filling functions
extension SVKAssistantGenericTableViewCell {
    
    private func fillAudioCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        
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
                bubble.iconImageView.image = SVKTools.imageWithName("iconRadio")
            }
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        } else  {
            bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        }
        updateViewTextAndViewActionConstraint()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
        
    }
    
    private func fillMusicCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        
        if isCardHackEnabled {
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.titleLabel.text = "music.Deezer.subTitle".localized
            if let key = bubbleDescription.card?.type {
                bubble.descriptionLabel.text = "music.playing.\(key)".localized
            }
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
        } else {
            bubble.textLabel.text = bubbleDescription.card?.data?.text
            bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
            bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
            bubble.descriptionLabel.text = bubbleDescription.card?.data?.typeDescription
            bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
            bubble.detailsLabel?.text =  bubbleDescription.card?.data?.actionText
        }
        
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
        updateViewTextAndViewActionConstraint()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
    }
    
    // .generic
    private func fillGenericCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        guard isCardHackEnabled == false || bubbleDescription.contentType == .genericCard || bubbleDescription.contentType == .memolistCard
            || bubbleDescription.contentType == .timerCard else {    fillGenericHakedCard(with: bubbleDescription)
            return
        }
        
        bubble.titleLabel.text = bubbleDescription.card?.data?.titleText
        bubble.subTitleLabel.text = bubbleDescription.card?.data?.subTitle
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)
        bubble.detailsLabel?.text = bubbleDescription.card?.data?.actionText
        
        if let layout = bubbleDescription.card?.data?.layout {
            switch layout {
            case .genericFullText:
                bubble.subTextLabel.text = bubbleDescription.card?.data?.fullText
               // bubble.subTextLabel.textColor = UIColor.greyishBrown
                bubble.extendSubTextLabel(true)
            case .genericList:
                if let items = bubbleDescription.card?.data?.items  {
                    
                    var index = 0
                    var text = "\u{2022} \(items[index])"
                    
                    while index < items.count - 1 {
                        index += 1
                        text += "\n\u{2022} \(items[index])"
                    }
                    bubble.subTextLabel.text  = text
                    bubble.sourceLabel?.text = bubbleDescription.card?.data?.subText
                } else {
                    bubble.subTextLabel.text = nil
                }
               // bubble.subTextLabel.textColor = UIColor.black
                bubble.extendSubTextLabel(true)
                
            case .mediaPlayer:
                bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
               // bubble.subTextLabel.textColor = UIColor.black
                bubble.extendSubTextLabel(false)
                bubble.subTitleLabel.isHidden = true
                
                if let skill = bubbleDescription.skill as? SVKGenericAudioPlayerSkill {
                    self.status = skill.status
                    if skill.duration > 0 {
                        self.internalProgressView.setValue(skill.seek, animated: true)
                        self.internalProgressView.duration = Double(skill.duration)
                        showProgressView()
                    } else {
                        hideProgressView()
                    }
                }
            // .generic
            default:
                bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
               // bubble.subTextLabel.textColor = UIColor.black
                bubble.extendSubTextLabel(false)
            }
            updateViewTextAndViewActionConstraint()
            concreteBubble()?.setNeedsUpdateConstraints()
            concreteBubble()?.layoutIfNeeded()
        }
        
        bubble.tapAction = { (bubble, userInfo) in
            if let userInfo = userInfo as? [String:Any],
                let description = userInfo["description"] as? SVKAssistantBubbleDescription {
                SVKAnalytics.shared.log(event: "myactivity_card_click")
                self.delegate?.executeAction(from: description)
            }
        }
    }
    
    override func updateConstraints() {
        updateViewTextAndViewActionConstraint()
        super.updateConstraints()
    }
    override func layoutSubviews() {
        updateViewTextAndViewActionConstraint()
        super.layoutSubviews()
    }
    func updateViewTextAndViewActionConstraint() {
        
        var isActionViewVisible = true
        var isSourceViewVisible = true
        
        if (bubble.detailsLabel?.text ?? "").isEmpty {
            isActionViewVisible = false
        }
        if (bubble.sourceLabel?.text ?? "").isEmpty {
            isSourceViewVisible = false
        }
        var constraintsDesactivated:[NSLayoutConstraint] = []
        var constraintsActivated:[NSLayoutConstraint] = []

        if isSourceViewVisible {
            bubble.sourceLabel?.alpha = 1.0
            constraintsActivated.append(subTitleViewSourceViewConstraint)
            constraintsDesactivated.append(subTitleViewBottomConstaint)
        } else {
            constraintsActivated.append(subTitleViewBottomConstaint)
            constraintsDesactivated.append(subTitleViewSourceViewConstraint)
        }
        if (bubble.textLabel?.text ?? "").isEmpty {
            constraintsDesactivated.append(textLabelSubTextLabelConstraint)
        } else {
            constraintsActivated.append(textLabelSubTextLabelConstraint)
        }
        
        switch (isProgressViewVisible,isActionViewVisible) {
        case (true,true):
            progressView.alpha = 1.0
            actionView.alpha = 1.0
            constraintsDesactivated.append(contentsOf: [viewTextBottomConstraint,viewTextActionViewConstraint,progressViewBottomConstraint])
            constraintsActivated.append(contentsOf: [viewTextProgressViewConstraint,progressViewActionViewConstraint])
        case (true,false):
            actionView.alpha = 0.0
            progressView.alpha = 1.0
            constraintsDesactivated.append(contentsOf: [viewTextBottomConstraint,viewTextActionViewConstraint,progressViewActionViewConstraint])
            constraintsActivated.append(contentsOf: [viewTextProgressViewConstraint,progressViewBottomConstraint])
            
        case (false,true):
            actionView.alpha = 1.0
            progressView.alpha = 0.0
            constraintsDesactivated.append(contentsOf: [viewTextBottomConstraint,viewTextProgressViewConstraint,progressViewBottomConstraint,progressViewActionViewConstraint])
            constraintsActivated.append(contentsOf: [viewTextActionViewConstraint])
            
        case (false,false):
            actionView.alpha = 0.0
            progressView.alpha = 0.0
            constraintsDesactivated.append(contentsOf: [viewTextProgressViewConstraint,progressViewBottomConstraint,progressViewActionViewConstraint,viewTextActionViewConstraint])
            constraintsActivated.append(contentsOf: [viewTextBottomConstraint])
            
        }
        NSLayoutConstraint.deactivate(constraintsDesactivated)
        NSLayoutConstraint.activate(constraintsActivated)
    }

    // .generic hacked card
    private func fillGenericHakedCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        
        bubble.detailsLabel?.text = nil
        bubble.subTitleLabel.text = bubbleDescription.card?.data?.subTitle
        bubble.sourceLabel?.text = bubbleDescription.card?.data?.requesterSource
        bubble.textLabel.text = bubbleDescription.card?.data?.text
        bubble.descriptionLabel.text = nil
        bubble.subTextLabel.text = bubbleDescription.card?.data?.subText
        var type = SVKCardDataTypeDescription.case(with: bubbleDescription.card?.data?.typeDescription)
        if type == .unknown {
            if case  SVKCardType.iot? = bubbleDescription.card?.type {
                type = .lights
            }
        }
        switch type {
        case .date:
            bubble.titleLabel.text = "currentDate.title".localized
            bubble.iconImageView.image = UIImage(named: "iconCalendar", in: SVKBundle, compatibleWith: nil)

        case .currentTime:
            bubble.titleLabel.text = "currentTime.title".localized
            if let hour = bubbleDescription.card?.data?.text?.replacingOccurrences(of: "CURRENT_TIME_CARD_TIME", with: "") {
                bubble.textLabel.text = hour
            }
            bubble.iconImageView.image = UIImage(named: "iconAlarmBlack", in: SVKBundle, compatibleWith: nil)

        case .lights:
            bubble.titleLabel.text = "iot.device.lights".localized
            bubble.setIconImage(with: bubbleDescription.card?.data?.iconUrl)

        case .timerDelete, .timerSet, .timerGet:
            fillTimerHackedCard(with: bubbleDescription)
            
        default:
            break
        }
        updateViewTextAndViewActionConstraint()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
    }
    
    // .genericDate, .timer
    private func fillTimerHackedCard(with bubbleDescription:SVKAssistantBubbleDescription) {

        var imageName = "iconMinuteur"
        let type = SVKCardDataTypeDescription.case(with: bubbleDescription.card?.data?.typeDescription)
        switch type {
        case .timerSet:
            bubble.subTitleLabel.text = "timer.added".localized
            imageName = "iconMinuteurAdd"
        case .timerDelete:
            bubble.subTitleLabel.text = "timer.deleted".localized
            imageName = "iconMinuteurDelete"
        default: bubble.subTitleLabel.text = ""
        }
        bubble.titleLabel.text = "timer.title".localized
        bubble.iconImageView.image = UIImage(named: imageName, in: SVKBundle, compatibleWith: nil)
        
        let duration = (type == .timerSet) || (type == .timerDelete) ? bubbleDescription.card?.data?.duration : Int(bubbleDescription.card?.data?.timeLeft?.first ?? 0)
        bubble.textLabel.text = SVKTools.timerString(from: duration)
    }

    private func fillMemolistHackedCard(with bubbleDescription:SVKAssistantBubbleDescription) {
        bubble.extendSubTextLabel(true)
        setTextLabels(with: bubbleDescription.card?.data?.items)
        
        var imageName = "iconRemindersBlack"
        switch bubbleDescription.card?.type {
        case .memolistAdd?:
            bubble.subTitleLabel.text = "memolist.added".localized
            imageName = "iconRemindersBlackAdd"
        case .memolistGet?:
            bubble.subTitleLabel.text = ""
            imageName = "iconRemindersBlack"
        case .memolistDelete?:
            bubble.subTitleLabel.text = "memolist.deleted".localized
            imageName = "iconRemindersBlackDelete"
        default: bubble.subTitleLabel.text = ""
        }
        bubble.titleLabel.text = "memolist.shoppingList".localized
        bubble.iconImageView.image = UIImage(named: imageName, in: SVKBundle, compatibleWith: nil)
        #if SHOPPING_LIST_ACTION_ENABLED
        bubble.tapAction = { (bubble, userInfo) in
            DispatchQueue.main.async {
                let urlS = "djingo://services/memolist"
                if let url = URL(string: urlS) {
                    UIApplication.shared.open(url, completionHandler:  nil)
                }
            }
        }
        #endif
        updateViewTextAndViewActionConstraint()
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()
    }

    internal func setIconButtomConstraint(defaultConstant: CGFloat, minimumConstant: CGFloat) {
        // Let's help autolayout
        self.iconBottomConstraint?.constant = defaultConstant
        if let _ = bubble.detailsLabel?.text,
            bubble.sourceLabel?.text == nil {
            bubble.sourceLabel?.text = " "
        } else if bubble.detailsLabel?.text == nil, bubble.sourceLabel?.text == nil {
            self.iconBottomConstraint?.constant = minimumConstant
        }
    }
}


//
// A Generic Bubble builded from SVKBubble
//
final class SVKGenericBubble: SVKBubble {
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var subTitleLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var textLabel: UILabel!
    @IBOutlet public var subTextLabel: UILabel!
    @IBOutlet public var sourceLabel: UILabel?
    @IBOutlet public var iconImageView: UIImageView!
    @IBOutlet public var imageView: UIImageView?
    @IBOutlet public var detailsLabel: UILabel?
    @IBOutlet public var actionView: UIView?
    @IBOutlet public var textView: UIView?
    
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var subTitleViewSourceViewConstraint: NSLayoutConstraint!
    
    
    @IBOutlet private var textLabelHeightContraint: NSLayoutConstraint?
    @IBOutlet private var textLabelBottomConstraint: NSLayoutConstraint?
    @IBOutlet private var textLabelTopConstraint: NSLayoutConstraint? {
        didSet {
            guard let constraint = textLabelTopConstraint else { return }
            textLabelTopConstant = constraint.constant
        }
    }
    
    // Cunning to make IBInspectable work with SVKBubble defined outside of SmartVoiceKit module
    @IBInspectable var isIBInspectableActivated: Bool = true {
        didSet {
            //SVKAppearanceBox.shared.appearance.backgroundColor.color
            self.foregroundColor = .white
        }
    }
    fileprivate var textLabelTopConstant: CGFloat = 0
    fileprivate var textLabelFontPointSize: CGFloat = 0
    fileprivate var textLabelMinimumScaleFactor: CGFloat = 0
    
    fileprivate var iconImageViewContentMode: UIView.ContentMode = .center
    fileprivate var imageViewContentMode: UIView.ContentMode = .center

    // override to prevent super.awakeFromNib to be called
    public override func awakeFromNib() {
        setup()
        textLabelFontPointSize = textLabel.font.pointSize
        textLabelMinimumScaleFactor = textLabel.minimumScaleFactor
        iconImageViewContentMode = iconImageView.contentMode
        imageViewContentMode = imageView?.contentMode ?? .center
    }
    
    public override func setup() {
        super.setup()
        self.contentInset = .zero
        foregroundColor = .white
        style = .bottom(.left)
    }
    
    public override func prepareForInterfaceBuilder() {
        setup()
    }
    
    public func prepareForReuse() {
        iconImageView?.contentMode = iconImageViewContentMode
        imageView?.contentMode = imageViewContentMode
        imageView?.image = nil
        iconImageView?.image = nil
    }
    
    /**
     Extends or unextends the SubtextLabel
     - parameter extented: true if subTextLabel should be extented, false to unextend
     */
    public func extendSubTextLabel(_ extended: Bool) {
        
        if extended {
            subTextLabel.numberOfLines = 0
            subTextLabel.minimumScaleFactor = 1
//            subTextLabel.textColor = UIColor.greyishBrown
        } else {
            subTextLabel.numberOfLines = 1
            subTextLabel.minimumScaleFactor = textLabelMinimumScaleFactor
//            subTextLabel.textColor = UIColor.black
        }
    }
    /**
     Extends or unextends the textLabel by masking bubbleDescriptionLabel and subTextLabel
     - parameter extented: true if textLabel should be extented, false to unextend
     */
    public func extendTextLabel(_ extended: Bool) {
        
    }
    
    func setIconImage(with url: String?, placeHolderContentMode:UIView.ContentMode = .center, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        guard let string = url,
            let iconURL = URL(string: string) else {
                iconImageView?.image = SVKTools.imageWithName("imagePlaceHolder")
                iconImageView?.contentMode = placeHolderContentMode
                return
        }
        iconImageView.setImage(with: iconURL, placeholder: SVKTools.imageWithName("imagePlaceHolder")) { [weak self] (result) in
            
            if case .failure(_) = result {
                self?.iconImageView.contentMode = placeHolderContentMode
            }
            completionHandler?(result)
        }
    }
    
    func setImage(with url: String?) {
        guard let string = url,
            let imageURL = URL(string: string) else {
                imageView?.image = SVKTools.imageWithName("imagePlaceHolder")
                imageView?.contentMode = .center
                return
        }
        
        imageView?.setImage(with: imageURL, placeholder: SVKTools.imageWithName("imagePlaceHolder")) { [weak self] (result) in
            if case .failure(_) = result {
                self?.iconImageView.contentMode = .center
            }
        }
    }
}
