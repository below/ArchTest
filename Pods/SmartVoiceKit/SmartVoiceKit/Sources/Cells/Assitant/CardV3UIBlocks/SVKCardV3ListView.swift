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

class SVKCardV3ListView: UIView, CardV3Viewable {
    
    @UseAutoLayout
    private var stackView = UIStackView()
    var delegate: SVKCardV3Delegate?
    private var bubbleDescription: SVKAssistantBubbleDescription?
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.addSubview(stackView)
        stackView.clipAnchors(to: self)
        stackView.axis = .vertical
        stackView.spacing = SVKAppearanceBox.shared.appearance.cardV3Style.layout.itemList.spacing.section
    }

    func fill(description: SVKAssistantBubbleDescription) {
        guard let listSections = description.card?.data?.listSections else { return }
        
        for section in listSections {
            stackView.addArrangedSubview(SVKCardV3ListSectionView(listSection: section, openLinkAction: open(link:)))
        }
        bubbleDescription = description
    }

    func reset() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func open(link: String) {
        delegate?.open(url: link, bubbleDescription: bubbleDescription)
    }
}


typealias itemClickAction = (String) -> Void

class SVKCardV3ListSectionView: UIView {

    private var listSection: SVKListSection?

    @UseAutoLayout
    private var stackView = UIStackView()
    private var titleLabel = UILabel()
    private var openLinkAction: itemClickAction?

    override init(frame: CGRect) {
        self.listSection = nil
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(listSection: SVKListSection, openLinkAction: @escaping itemClickAction) {
        self.init(frame: CGRect.zero)
        self.listSection = listSection
        self.openLinkAction = openLinkAction
        setup()
    }

    private func setup() {
        let itemListApperance = SVKAppearanceBox.shared.appearance.cardV3Style.layout.itemList
        self.addSubview(stackView)
        stackView.clipAnchors(to: self)
        stackView.axis = .vertical
        stackView.spacing = itemListApperance.spacing.title

        if let title = listSection?.title, !title.isEmpty {
            titleLabel.text = title
            titleLabel.textColor = itemListApperance.title.color.color
            titleLabel.font = itemListApperance.title.font.font
            stackView.addArrangedSubview(titleLabel)
        }

        guard let items = listSection?.items else { return }

        for item in items {
            stackView.addArrangedSubview(SVKCardV3ListItemView(listItem: item, openLinkAction: openLinkAction))
        }
    }
}

class SVKCardV3ListItemView: UIView {

    private var listItem: SVKListSectionItem?

    @UseAutoLayout
    private var stackView = UIStackView()
    private var iconImageView = UIImageView()
    private var textLabel = UILabel()

    private var openLinkAction: itemClickAction?
    private var tapGesture: UITapGestureRecognizer!
    private var itemAction: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(listItem: SVKListSectionItem, openLinkAction: itemClickAction?) {
        self.init(frame: CGRect.zero)
        self.listItem = listItem
        self.openLinkAction = openLinkAction

        setup()
    }

    func setup() {
        let itemListApperance = SVKAppearanceBox.shared.appearance.cardV3Style.layout.itemList
        self.addSubview(stackView)
        stackView.clipAnchors(to: self)
        stackView.axis = .horizontal
        stackView.spacing = itemListApperance.spacing.item
        stackView.alignment = .top

        textLabel.text = listItem?.itemText
        textLabel.numberOfLines = 2
        
        textLabel.font = itemListApperance.itemText.font.font

        if let iconUrl = listItem?.itemIconUrl, !iconUrl.isEmpty {
            setIconImage(with: iconUrl)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
        
        let size = CGSize(width: itemListApperance.image.size.width, height: itemListApperance.image.size.height)
        iconImageView.anchor(size: size)

        handle(itemAction: listItem?.itemAction)
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(textLabel)
    }

    private func setIconImage(with string: String, placeHolderContentMode:UIView.ContentMode = .scaleToFill) {
        guard let iconURL = URL(string: string) else {
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

    private func handle(itemAction: String?) {
        guard let action = itemAction else {
            textLabel.textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.itemList.itemText.color.color
            return
        }

        textLabel.textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.itemList.itemText.actionForegroundColor.color
        self.itemAction = action
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(openLink))
        stackView.addGestureRecognizer(tapGesture)
    }

    @objc
    func openLink() {
        guard let action = itemAction else {
            return
        }
        openLinkAction?(action)
    }
}
