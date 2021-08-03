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

public struct SVKGDPRSwitchModel {
    public var label: String
    public var value: Bool
    public var id: String
    public var description: String?
    public var isCollapsed: Bool
}

public protocol SVKGDPRSwitchModelDelegate {

    func switchAction(_ for: SVKGDPRSwitchModel)
    func switchCollapseExpand(_ for: SVKGDPRSwitchModel?)
}

open class SVKGDPRSwitchCell: UITableViewCell {
    
    var tapGestureActionView = UITapGestureRecognizer()
    
    var delegate: SVKGDPRSwitchModelDelegate?
    var data: SVKGDPRSwitchModel? {
        didSet {
            let cellApparence = SVKAppearanceBox
                .shared
                .appearance
                .tableStyle
                .cell
//            self.label.font = SVKAppearanceBox.shared.appearance.fontBlocDescription?.font
            self.contentView.backgroundColor = cellApparence.backgroundColor.color
            self.label.textColor = cellApparence.foregroundMainColor.color
            self.descriptionLabel.textColor = cellApparence.foregroundSecondColor.color
            descriptionLabel.numberOfLines = data?.isCollapsed ?? true ? 2 : 0
            self.separatorView.backgroundColor = cellApparence.separatorColor.color
            self.footerSeparatorView.backgroundColor = cellApparence.footerSeparatorColor.color
            self.moreLabel.textColor = cellApparence.actionForegroundColor.color
            self.actionIcon.image = SVKAppearanceBox.Assets.tableCellActionIcon
            self.actionIcon.tintColor = cellApparence.actionForegroundColor.color
            if !(data?.isCollapsed ?? true) {
                self.moreLabel.text = "SVK.GDPR.datas.showless".localized
                self.actionIcon.transform = self.actionIcon.transform.rotated(by: CGFloat(Double.pi))
            } else {
                self.moreLabel.text = "SVK.GDPR.datas.showmore".localized
            }
            label.text = data?.label
            descriptionLabel.text = data?.description
            switchObject.isOn =  data?.value ?? true
        }
    }
    
    @IBOutlet weak var switchObject: UISwitch!
    
    @IBAction func switchAction(_ sender: Any) {
        if var data = data {
            data.value = switchObject.isOn
            delegate?.switchAction(data)
        }
    }
    @IBOutlet var label: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var separatorView: UIView!
    
    @IBOutlet var footerSeparatorView: UIView!
 
    @IBOutlet var moreLabel: UILabel!
    
    @IBOutlet var actionIcon: UIImageView!
    
    @IBOutlet var actionView: UIView!
    open override func awakeFromNib() {
        tapGestureActionView = UITapGestureRecognizer(target: self, action: #selector(toggleFullDescription(tapGestureRecognizer:)))
        tapGestureActionView.numberOfTapsRequired = 1
        tapGestureActionView.numberOfTouchesRequired = 1
        
        actionIcon.isUserInteractionEnabled = true
        actionView.isUserInteractionEnabled = true
        actionView.addGestureRecognizer(tapGestureActionView)
    }
  
    var toggle = false
    
    @objc func toggleFullDescription(tapGestureRecognizer: UITapGestureRecognizer) {
        self.delegate?.switchCollapseExpand(data)
    }
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        label.text = nil
        descriptionLabel.text = nil
        switchObject.isOn = true
        moreLabel.text = nil
        descriptionLabel.numberOfLines = 2
        self.actionIcon.transform = CGAffineTransform.identity
    }

    override open func layoutSubviews() {
        if self.descriptionLabel.maxNumberOfLines <= 2 {
            self.actionView.isHidden = true
        } else {
            self.actionView.isHidden = false
        }
        super.layoutSubviews()
    }
}
