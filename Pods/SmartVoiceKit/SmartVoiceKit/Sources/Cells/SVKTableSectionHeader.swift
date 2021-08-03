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

import Foundation

protocol SVKTableSectionHeaderDelegate {
    func toggleSelection(section: Int)
}

open class SVKTableSectionHeader: UITableViewHeaderFooterView {
    
    var tapGesture = UITapGestureRecognizer()
    var section: Int?
    
    var delegate: SVKTableSectionHeaderDelegate?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSelection(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    @objc func toggleSelection(_ button: UIButton) {
        if let section = section, let delegate = delegate {
            delegate.toggleSelection(section: section)
        }
    }
    
    @IBOutlet private var background: UIView? {
        didSet {
            super.backgroundView = background
        }
    }
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var selectorImageView: UIImageView!
    
    internal var  isSelectedInternal = false
    
    public var isSelected: Bool {
        get {
            return isSelectedInternal
        }
        set {
            isSelectedInternal = newValue
            selectorImageView?.image = newValue ? SVKAppearanceBox.Assets.checkboxOn : SVKAppearanceBox.Assets.checkBoxOff
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel?.text = nil
        selectorImageView?.image = nil
        section = nil
        delegate = nil
    }
}

