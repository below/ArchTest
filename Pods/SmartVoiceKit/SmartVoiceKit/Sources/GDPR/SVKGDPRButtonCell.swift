//
// Software Name: Smart Voice Kit - SVPocket
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
// Module description: A sample code to use the SDK in a test app
// named SVPocket.
//

import Foundation
import UIKit

public struct SVKGDPRButtonModel {
    public var button: String
    public var id: String
}

public protocol SVKGDPRButtonModelDelegate {

    func tapAction(_ for: SVKGDPRButtonModel)
}

open class SVKGDPRButtonCell: UITableViewCell {
    
    @IBOutlet var button: SVKCustomButton!
    
    @IBOutlet var footerSeparatorView: UIView!
    @IBAction func tapAction(_ sender: Any) {
        if let data = self.data {
            self.delegate?.tapAction(data)
        }
    }
    
    var delegate: SVKGDPRButtonModelDelegate?
    var data: SVKGDPRButtonModel? {
        didSet {
            let cellApparence = SVKAppearanceBox
            .shared
            .appearance
                .tableStyle
                .cell
            
            self.contentView.backgroundColor = cellApparence.backgroundColor.color
            button.setTitleColor(cellApparence.foregroundButtonColor.color, for: .normal)
            button.setTitle(data?.button, for: .normal)
            self.footerSeparatorView.backgroundColor = cellApparence.footerSeparatorColor.color
        }
    }
    
}
