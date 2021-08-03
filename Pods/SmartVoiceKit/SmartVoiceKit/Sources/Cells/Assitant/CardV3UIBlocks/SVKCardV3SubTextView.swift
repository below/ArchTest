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

class SVKCardV3SubTextView: UIView, CardV3Viewable {

    @UseAutoLayout
    private var stackView = UIStackView()

    private let label = UILabel()
    private let showMoreButton = UIButton()

    weak var delegate: SVKActionDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.clipAnchors(to: self)

        label.numberOfLines = 4
        stackView.addArrangedSubview(label)

        showMoreButton.setTitle("SVK.GDPR.datas.showmore".localized, for: .normal)
        showMoreButton.titleLabel?.font = SVKAppearanceBox.shared.appearance.cardV3Style.layout.subText.font.font
        showMoreButton.setImage(SVKAppearanceBox.Assets.tableCellActionIcon, for: .normal)
        showMoreButton.addTarget(self, action: #selector(didTapOnShowMore), for: .touchUpInside)
        if #available(iOS 11.0, *) {
            showMoreButton.contentHorizontalAlignment = .leading
        } else {
            showMoreButton.contentHorizontalAlignment = .left
        }
        stackView.addArrangedSubview(showMoreButton)
    }

    func fill(description: SVKAssistantBubbleDescription) {
        guard let card = description.card else {
            return
        }
        self.tag = description.bubbleKey

        label.text = card.data?.subText
        label.textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.subText.color.color
        label.font = SVKAppearanceBox.shared.appearance.cardV3Style.layout.subText.font.font

        showMoreButton.titleLabel?.font = SVKAppearanceBox.shared.appearance.cardV3Style.layout.subText.font.font
        showMoreButton.setTitleColor(SVKAppearanceBox.shared.appearance.tableStyle.cell.actionForegroundColor.color, for: .normal)
        showMoreButton.setImage(SVKAppearanceBox.Assets.tableCellActionIcon, for: .normal)
        showMoreButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.horizontal)
        showMoreButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.horizontal, bottom: 0, right: 0)
        stackView.spacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.spacing.vertical

        if description.cardV3SubTextIsExpanded {
            label.numberOfLines = 0
            showMoreButton.setTitle("SVK.GDPR.datas.showless".localized, for: .normal)
            if let imageView = showMoreButton.imageView {
                imageView.transform = imageView.transform.rotated(by: CGFloat.pi)
            }
        } else {
            label.numberOfLines = 4
        }
    }

    func reset() {
        label.text = ""
        showMoreButton.setTitle("SVK.GDPR.datas.showmore".localized, for: .normal)
        showMoreButton.imageView?.transform = .identity
        self.showMoreButton.isHidden = true
    }

    @objc func didTapOnShowMore() {
        if self.showMoreButton.alpha != 0 {
            delegate?.switchCollapseExpandSubText(for: tag)
        }
    }

    override open func layoutSubviews() {
        if label.maxNumberOfLines <= 4 {
            self.showMoreButton.isHidden = true
        } else {
            self.showMoreButton.isHidden = false
        }

        super.layoutSubviews()
    }
}
