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

/**
 A SVKTableViewCell delegation protocol
 */
protocol SVKCardV3Delegate {
    func switchCollapseExpandSubText(for tag: Int)
    func open(url: String, bubbleDescription: SVKAssistantBubbleDescription?)
}

protocol SVKGenericDefaultCardV3TMediaDelegate {
    func playMedia()
    func stopMedia()
    func seek(value: Float)
}

protocol CardV3Viewable where Self: UIView {
    func fill(description: SVKAssistantBubbleDescription)
    func reset()
    func setup()
}

final class SVKGenericDefaultCardV3TableViewCell: SVKTableViewCell, SVKTableViewCellProtocol {
   
    public func concreteBubble<T>() -> T? where T: SVKBubble {
        return bubble as? T
    }
    
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var bubbleTrailingFullSizeConstraint: NSLayoutConstraint!
    @IBOutlet var bubbleTrailingNotFullSizeContraint: NSLayoutConstraint!
    
    @IBOutlet public var bubble: SVKBubble!
    
    @UseAutoLayout
    private var stackView: UIStackView = UIStackView()

    @UseAutoLayout
    private var imageBlockStackView: UIStackView = UIStackView()

    /// Holding the image stackviews top anchor to modify its value if image stackview is empty
    private var imageBlockStackViewTop: NSLayoutConstraint?

    @UseAutoLayout
    private var bottomStackView: UIStackView = UIStackView()
    
    /// Holding the bottom stackviews top anchor to modify its value if bottom stackview is empty
    private var bottomStackViewTop: NSLayoutConstraint?

    // UI blocks
    private var titleView: SVKCardV3TitleView!
    private var cardImageView: SVKCardV3ImageView!
    private var prominentTextView: SVKCardV3ProminentTextView!
    private var cardTextLabelView: SVKCardV3TextLabelView!
    private var cardSubTextView: SVKCardV3SubTextView!

    private var mediaCardView: SVKCardV3MediaView!

    var status: SVKAudioControllerStatus = .unknown {
        didSet {
            titleView?.update(with: status)
        }
    }

    var seek: Float = 0 {
        didSet {
            mediaCardView?.seek = seek
        }
    }

    private var listView: SVKCardV3ListView!

    override var delegate: SVKActionDelegate? {
        didSet {
            cardSubTextView.delegate = self.delegate
            prominentTextView?.delegate = self.delegate
            listView?.delegate = self.delegate
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    private func setup() {
        stackView = UIStackView()
        stackView.axis = .vertical
        let verticalSpacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        stackView.spacing = verticalSpacing
        bubble.addSubview(stackView)

        
        // Stack view top block
        let stackInsets = UIEdgeInsets(top: 16, left: 12, bottom: -8, right: -12)
        stackView.anchor(top: bubble.topAnchor, leading: bubble.leadingAnchor, bottom: nil, trailing: bubble.trailingAnchor, edgeInsets: stackInsets, enableInsets: true)

        // Stack view middle Image block
        imageBlockStackView.axis = .vertical
        bubble.addSubview(imageBlockStackView)

        let imageBlockStackInsets = UIEdgeInsets(top: 16, left: 0, bottom: -8, right: 0)
        imageBlockStackView.anchor(top: nil, leading: bubble.leadingAnchor, bottom: nil, trailing: bubble.trailingAnchor, edgeInsets: imageBlockStackInsets, enableInsets: true)
        imageBlockStackViewTop = imageBlockStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor,
                                                                              constant: verticalSpacing)
        imageBlockStackViewTop?.isActive = true

        // Stack view middle Image block
        bottomStackView.axis = .vertical
        bottomStackView.spacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        bubble.addSubview(bottomStackView)

        let bottomStackInsets = UIEdgeInsets(top: 16, left: 12, bottom: -16, right: -12)
        bottomStackView.anchor(top: nil, leading: bubble.leadingAnchor, bottom: bubble.bottomAnchor, trailing: bubble.trailingAnchor, edgeInsets: bottomStackInsets, enableInsets: true)

        bottomStackViewTop = bottomStackView.topAnchor.constraint(equalTo: imageBlockStackView.bottomAnchor,
                                                                  constant: verticalSpacing)
        bottomStackViewTop?.isActive = true

        titleView = SVKCardV3TitleView()
        stackView.addArrangedSubview(titleView)

        let cardImageView = SVKCardV3ImageView()
        imageBlockStackView.addArrangedSubview(cardImageView)
        self.cardImageView = cardImageView

        let prominentTextView = SVKCardV3ProminentTextView()
        bottomStackView.addArrangedSubview(prominentTextView)
        self.prominentTextView = prominentTextView

        cardTextLabelView = SVKCardV3TextLabelView()
        bottomStackView.addArrangedSubview(cardTextLabelView)

        cardSubTextView = SVKCardV3SubTextView()
        bottomStackView.addArrangedSubview(cardSubTextView)

        mediaCardView = SVKCardV3MediaView()
        bottomStackView.addArrangedSubview(mediaCardView)

        let listView = SVKCardV3ListView()
        bottomStackView.addArrangedSubview(listView)
        self.listView = listView

        setupInitialContext()
    }
    
    internal override func updateCellHighlight(highlighted: Bool) {

        let isFullSize = SVKAppearanceBox.shared.appearance.cardV3Style.isFullSizeCard
        if highlighted {
            cellLeadingConstraint?.constant = isFullSize ? 10 : 18
            if isFullSize {
                bubbleTrailingFullSizeConstraint?.constant = -10
            } else {
                bubbleTrailingNotFullSizeContraint?.constant = 51
            }
        } else {
            cellLeadingConstraint?.constant = isFullSize ? 0 : 8

            if isFullSize {
                bubbleTrailingFullSizeConstraint?.constant = 0
            } else {
                bubbleTrailingNotFullSizeContraint?.constant = 61
            }
        }
    }

    override func fill<T>(with content: T) {
        super.fill(with: content)
        guard let svkAssistantBubbleDescription = content as? SVKAssistantBubbleDescription else { return }

        let cardContentProvider = SVKV3CardContentProvider(description: svkAssistantBubbleDescription)
        let cardContents = cardContentProvider.getCardContent()
        bubble.tag = svkAssistantBubbleDescription.bubbleKey
        status = svkAssistantBubbleDescription.audioStatus
        seek = svkAssistantBubbleDescription.seekTime

        if cardContents.isEmpty {
            bubble.foregroundColor = .red
        } else {
            for content in cardContents {
                switch content {
                case .titleText:
                    titleView?.isHidden = false
                    titleView?.fill(description: svkAssistantBubbleDescription)
                    titleView?.mediaDelegate = self

                case .imageUrl:
                    cardImageView?.isHidden = false
                    cardImageView?.fill(description: svkAssistantBubbleDescription)

                case .prominentText:
                    prominentTextView?.isHidden = false
                    prominentTextView?.fill(description: svkAssistantBubbleDescription)
                    prominentTextView?.delegate = self.delegate

                case .text:
                    cardTextLabelView.isHidden = false
                    cardTextLabelView.fill(description: svkAssistantBubbleDescription)

                case .subText:
                    cardSubTextView.isHidden = false
                    cardSubTextView.fill(description: svkAssistantBubbleDescription)
                    cardSubTextView.delegate = self.delegate

                case .mediaUrl:
                    mediaCardView.isHidden = false
                    mediaCardView.mediaDelegate = self
                    mediaCardView.fill(description: svkAssistantBubbleDescription)

                case .listSections:
                    listView?.isHidden = false
                    listView?.fill(description: svkAssistantBubbleDescription)

                default:
                    break
                }
            }
        }

        if !listView.isHidden ||
            !mediaCardView.isHidden ||
            !cardSubTextView.isHidden ||
            !cardTextLabelView.isHidden ||
            !prominentTextView.isHidden {
            bottomStackViewTop?.constant = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        } else {
            bottomStackViewTop?.constant = 0
        }

        imageBlockStackViewTop?.constant = cardImageView.isHidden ? 0 : SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        concreteBubble()?.setNeedsUpdateConstraints()
        concreteBubble()?.layoutIfNeeded()

        layoutAvatar(for: svkAssistantBubbleDescription)

        bubble.style = svkAssistantBubbleDescription.bubbleStyle
        bubble.cornerRadius = SVKAppearanceBox.shared.appearance.cardV3Style.cornerRadius
        bubble.foregroundColor = SVKAppearanceBox.shared.appearance.cardV3Style.backgroundColor.color
        bubble.borderColor = SVKAppearanceBox.shared.appearance.cardV3Style.borderColor.color
        stackView.spacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        bottomStackView.spacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical
        
        if SVKAppearanceBox.shared.appearance.cardV3Style.isFullSizeCard {
            NSLayoutConstraint.deactivate([bubbleTrailingNotFullSizeContraint])
            NSLayoutConstraint.activate([bubbleTrailingFullSizeConstraint])
        } else {
            NSLayoutConstraint.deactivate([bubbleTrailingFullSizeConstraint])
            NSLayoutConstraint.activate([bubbleTrailingNotFullSizeContraint])
        }
        bubble.shapeLayer.setNeedsDisplay()
        bubble.setNeedsDisplay()
    }

    private func setupInitialContext() {
        titleView?.reset()
        titleView?.isHidden = true
        cardImageView?.reset()
        cardImageView?.isHidden = true
        prominentTextView?.reset()
        prominentTextView?.isHidden = true
        cardTextLabelView.reset()
        cardTextLabelView.isHidden = true
        cardSubTextView.reset()
        cardSubTextView.isHidden = true
        mediaCardView.reset()
        mediaCardView.isHidden = true
        listView?.reset()
        listView?.isHidden = true
        imageBlockStackViewTop?.constant = 0
        bottomStackViewTop?.constant = 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setupInitialContext()
    }
}

extension SVKGenericDefaultCardV3TableViewCell: SVKGenericDefaultCardV3TMediaDelegate {

    func playMedia() {
        // Need to stop previous media if user directly
        // start another audio without stopping current one
        stopMedia()

        delegate?.play(sender: self)
    }

    func stopMedia() {
        delegate?.stop()
    }

    func seek(value: Float) {
        delegate?.seek(for: bubble.tag, to: value)
    }
}

enum SVKV3CardContent {
    case titleText, typeDescription, imageUrl, text, subText, listSections, prominentText, mediaUrl
}

struct SVKV3CardContentProvider {

    let description: SVKAssistantBubbleDescription

    init(description: SVKAssistantBubbleDescription) {
        self.description = description
    }

    func getCardContent() -> [SVKV3CardContent] {
        var cardContents = [SVKV3CardContent]()
        let cardData = description.card?.data
        if cardData?.titleText?.isEmpty == false ||
            cardData?.typeDescription?.isEmpty == false ||
           cardData?.iconUrl?.isEmpty == false ||
            cardData?.mediaUrl?.isEmpty == false {
            cardContents.append(.titleText)
        }

        if cardData?.imageUrl?.isEmpty == false  {
            cardContents.append(.imageUrl)
        }

        if cardData?.prominentText?.isEmpty == false {
            cardContents.append(.prominentText)
        }

        if cardData?.text?.isEmpty == false {
            cardContents.append(.text)
        }

        if cardData?.subText?.isEmpty == false {
            cardContents.append(.subText)
        }

        if cardData?.listSections?.isEmpty == false {
            cardContents.append(.listSections)
        }

        if cardData?.mediaUrl?.isEmpty == false,
           description.audioDuration > 0 {
            cardContents.append(.mediaUrl)
        }

        return cardContents
    }
}

