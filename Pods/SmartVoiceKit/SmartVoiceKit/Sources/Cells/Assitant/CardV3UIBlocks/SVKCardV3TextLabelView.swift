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

class SVKCardV3TextLabelView: UILabel, CardV3Viewable {
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        numberOfLines = 0
    }

    func fill(description: SVKAssistantBubbleDescription) {
        self.text = description.card?.data?.text
        textColor = SVKAppearanceBox.shared.appearance.cardV3Style.layout.text.color.color
        font = SVKAppearanceBox.shared.appearance.cardV3Style.layout.text.font.font
    }

    func reset() {
        self.text = ""
    }
}
