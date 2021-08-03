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

class SVKCardV3ImageView: UIView, CardV3Viewable {

    @UseAutoLayout
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    

    private var imageHeightConstraint = NSLayoutConstraint()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fill(description: SVKAssistantBubbleDescription) {
        guard let string = description.card?.data?.imageUrl,
              let imageURL = URL(string: string) else {
            return
        }

        imageView.setImage(with: imageURL)
        imageView.isHidden = false
        NSLayoutConstraint.activate([imageHeightConstraint])
        imageHeightConstraint.constant = SVKAppearanceBox.shared.appearance.cardV3Style.layout.cardImage.height
    }

    func reset() {
        imageView.image = nil
        imageView.isHidden = true
        NSLayoutConstraint.deactivate([imageHeightConstraint])
    }

     func setup() {
        self.addSubview(imageView)
        imageView.clipAnchors(to: self)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: SVKAppearanceBox.shared.appearance.cardV3Style.layout.cardImage.height)
    }
}
