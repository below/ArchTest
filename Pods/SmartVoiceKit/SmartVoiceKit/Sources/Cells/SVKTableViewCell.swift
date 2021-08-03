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

public struct SVKConstant {
    public struct Bubble {
        public struct Margin {
            public static let left: CGFloat = 52
            public static let right: CGFloat = 31
        }
    }
    public struct HeaderHeight {
        public static let defaultHeight: CGFloat = 48
        public static let heightWithSafeArea: CGFloat = 68
    }
    public static let filteredErrorCode = [ "COULDNT_RESOLVE_INTENT", "COULDNT_RESOLVE_INTENT_SESSION", "COULDNT_RESOLVE_SKILL",  "RESOLVE_INTENT_FAILED", "SKILL_INVOCATION_FAILED", "SKILL_TIMED_OUT"]
    public static let noShowfilteredErrorCode = [ "WAKE_UP_PHRASE_VALIDATION_FAILED", "SPEECH_TOTEXT_FAILED", "SPEECH_TO_TEXT_FAILED",  "CLIENT_ABORTED_STREAMING", "DIDNT_UNDERSTOOD_SPEECH", "DIDNT_UNDERSTOOD_SPEECH_SESSION", "TOO_MANY_REPROMPTS"]

    /// default speaker name: it's a kind of empty name, when the source is unknown for server
    public static let defaultDeviceName = "default-fallback"
    
    public static let globalCommand = "skill-global-commands"
    public static let didntUnderstood = "DIDNT_UNDERSTOOD_SPEECH"
    public static let couldntResolvedIntent = "COULDNT_RESOLVE_INTENT"
    public static let couldntResolvedSkill = "COULDNT_RESOLVE_SKILL"
    
    public static func isResponseContainsMisunderstoodError(status: String) -> Bool {
        return status == SVKConstant.didntUnderstood
    }
    
    public static func isResponseContainsSkillError(status: String) -> Bool {
        return ([SVKConstant.couldntResolvedIntent, SVKConstant.couldntResolvedSkill].contains(status))
    }
    
    public static func getKeyAssistantResponse(status: String) -> String {
        return status == SVKConstant.didntUnderstood ? "DC.ContextualRecommendation.DIDNT_UNDERSTOOD_SPEECH.botResponse" : "DC.ContextualRecommendation.COULDNT_RESOLVE_INTENT.botResponse"
    }
}

protocol SVKTableViewCellProtocol {
    func setBubbleStyle(_ style: SVKBubbleStyle)
    func concreteBubble<T>() -> T? where T: SVKBubble
    var bubbleStyle: SVKBubbleStyle { get }
    func cancelDownloadTask()
}

extension SVKTableViewCellProtocol {
    // the default implementation does nothing
    func setBubbleStyle(_: SVKBubbleStyle) {}
    
    var bubbleStyle: SVKBubbleStyle {
        return concreteBubble()?.style ?? .default(.left)
    }
    
    func cancelDownloadTask() {}
}

open class SVKTableViewCell: UITableViewCell, SVKReusable {

    @IBOutlet public var avatar: UIImageView!
    @IBOutlet public var timestamp: UILabel!
    @IBOutlet var bottomConstraint: NSLayoutConstraint?
    @IBOutlet public var timestampDetails: UILabel?
    @IBOutlet public var errorMessage: UILabel?
    @IBOutlet var selectorImageView: UIImageView?
    @IBOutlet var cardLeadingConstraint: NSLayoutConstraint?
    internal let cardLeadingRatioMultiplier: CGFloat = 61 / 375
    @IBOutlet var bubbleLeadingConstraint: NSLayoutConstraint?
    @IBOutlet var cellLeadingConstraint: NSLayoutConstraint?

    internal let expandedTopSpaceConstant: CGFloat = 43
    internal let defaultTopSpaceConstant: CGFloat = 10
    internal var topSpaceConstant: CGFloat = 10 {
        didSet {
            layoutTimestamp()
        }
    }

    var isCellHighlighted: Bool = false
    var isCellSelected: Bool = false
    var isCellSelectable: Bool = false
    var delegate: SVKActionDelegate?
    
    /// true if the cards must be hacked
    var isCardHackEnabled: Bool = false
    
    var dedicatedPreFixLocalisationKey = "djingo"
    
    var isEditingEnabled = false
    var isCellCardType = false

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = .clear
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        isTimestampHidden = true
        timestamp.text = nil
    }

    /// True if the timestamp is hidden
    public var isTimestampHidden: Bool = false {
        didSet {
            layoutTimestamp()
        }
    }

    fileprivate func layoutTimestamp() {
        contentView.constraints.first { $0.identifier == "TopSpace" }?.constant = isTimestampHidden ? topSpaceConstant : expandedTopSpaceConstant
        timestamp.isHidden = isTimestampHidden
        contentView.setNeedsLayout()
    }
    
    public var isTimestampDetailsHidden: Bool = false {
        didSet {
            bottomConstraint?.constant = isTimestampDetailsHidden ? 0 : 19
            UIView.animate(withDuration: 0.1, animations: {
                self.timestampDetails?.alpha = self.isTimestampDetailsHidden ? 0 : 1
            }) { (finished) in
                if finished {
                    self.timestampDetails?.isHidden = self.isTimestampDetailsHidden                    
                }
            }
            contentView.layoutIfNeeded()
        }
    }
    open override func prepareForReuse() {
        super.prepareForReuse()
        avatar.image = nil
        timestamp.text = nil
        bottomConstraint?.constant = 0
        isTimestampHidden = true
        isTimestampDetailsHidden = true
        timestampDetails?.text = nil
        topSpaceConstant = defaultTopSpaceConstant
        selectorImageView?.image = nil
    }

    open override func layoutSubviews() {
        cardLeadingConstraint?.constant = frame.width * cardLeadingRatioMultiplier
        super.layoutSubviews()
    }
    /**
     Format and set the timestamp label's text
     - parameter text: the timestamp unformatted value
     */
    public func setTimestampText(_ text: String) {
        
        guard let spacePosition = text.firstIndex(of: " ") else {
            timestamp.text = text
            return
        }
        
        let attributedString = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: timestamp.font.pointSize, weight: .medium),
            .kern: 0.07
            ])
        
        let length = text.distance(from: spacePosition, to: text.endIndex) - 1
        let location = text.distance(from: text.startIndex, to: spacePosition) + 1
        attributedString.addAttribute(.font,
                                      value: UIFont.systemFont(ofSize: timestamp.font.pointSize, weight: .regular),
                                      range: NSRange(location: location, length: length))
        
        timestamp.attributedText = attributedString
    }
    
    public func setTimestampDetailsText(_ text: String) {
        timestampDetails?.text = text
    }
    
    /**
    Set the error message text
    - parameter text: the error message text
    */
    public func setErrorMessageText(_ text: String?) {
        errorMessage?.text = text

        if let _ = text  {
            errorMessage?.isHidden = false
            timestampDetails?.text = nil
            bottomConstraint?.constant = 19
        } else {
            bottomConstraint?.constant = 0
            errorMessage?.isHidden = true
        }
        contentView.layoutIfNeeded()
    }
    
    override open func setEditing(_ editing: Bool, animated: Bool) {
        isEditingEnabled = editing
        guard let tableView = self.superview as? UITableView,
            avatar.image != nil else {
                super.setEditing(false, animated: animated)
                return
        }
        
        if editing, tableView.allowsMultipleSelectionDuringEditing {
            avatar.isHidden = true
            if isCellSelectable {
                selectorImageView?.isHidden = false
                selectorImageView?.image = isCellSelected ? SVKAppearanceBox.Assets.checkboxOn : SVKAppearanceBox.Assets.checkBoxOff
            }
        } else {
            avatar.isHidden = false
        }
        
        super.setEditing(false, animated: animated)
    }
    
    internal func layoutAvatar(hidden: Bool) {
        if hidden { avatar.image = nil }
        if isEditingEnabled {
            self.bubbleLeadingConstraint?.constant = 16
        } else {
            let constant: CGFloat = isCellCardType ? -33 : -25
            bubbleLeadingConstraint?.constant = hidden ? constant : 8
        }
        contentView.setNeedsLayout()
    }
        
    internal func updateCellBeforeDisplay() {
        updateCellHighlight(highlighted: isCellHighlighted)
    }
    
    internal func updateCellHighlight(highlighted: Bool) {
        if highlighted {
            cellLeadingConstraint?.constant = 18
        } else {
            cellLeadingConstraint?.constant = 8
        }
    }
        
    internal func layoutAvatar(for bubbleDescription: SVKAssistantBubbleDescription) {
        if dedicatedPreFixLocalisationKey == "djingo" {
            let appearance = bubbleDescription.appearance
            if let iconURL = appearance.avatarURL {
                if bubbleDescription.shoudDisplayAvatar() {
                    avatar.setImage(with: iconURL)
                }
                layoutAvatar(hidden: false)
            } else if let image = appearance.avatarImage {
                if bubbleDescription.shoudDisplayAvatar() {
                    avatar.image = image
                }
                layoutAvatar(hidden: false)
            } else {
                layoutAvatar(hidden: true)
            }
        } else {
            layoutAvatar(hidden: true)
        }
    }

    func fill<T>(with content: T) {
        guard let bubbleDescription = content as? SVKBubbleDescription else { return }
        setTimestampText(SVKTools.formattedDateTime(from: bubbleDescription.timestamp))
        isCellSelected = bubbleDescription.isSelected
        isCellHighlighted = bubbleDescription.isHighlighted
        isCellSelectable = bubbleDescription.bubbleIndex == 0
        isCellCardType = bubbleDescription.contentType == .genericCard
        if bubbleDescription.bubbleIndex == nil {
            isCellSelectable = true
        }
    }
}
