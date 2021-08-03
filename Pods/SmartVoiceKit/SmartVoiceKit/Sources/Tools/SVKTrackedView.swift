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

class SVKTrackedView: UIView {
    
    /// true if frame and center observers have been added
    var isObserverAdded = false

    /// A closure called when the frame has changed
    public var frameChangedClosure: ((CGRect) -> Void)? = nil

    /// true if frameChanged should be called
    public var isTracked = false

    /// the view content size
    public var contentSize: CGSize = .zero
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentSize = frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(frame: .zero)
    }
    
    deinit {
        if isObserverAdded {
            superview?.removeObserver(self, forKeyPath: "frame", context: nil)
            superview?.removeObserver(self, forKeyPath: "center", context: nil)
            isTracked = false
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        
        if isObserverAdded {
            superview?.removeObserver(self, forKeyPath: "frame", context: nil)
            superview?.removeObserver(self, forKeyPath: "center", context: nil)
        }
        newSuperview?.addObserver(self, forKeyPath: "frame", options:NSKeyValueObservingOptions(rawValue: 0), context: nil)
        newSuperview?.addObserver(self, forKeyPath: "center", options:NSKeyValueObservingOptions(rawValue: 0), context: nil)
        isObserverAdded = true
        
        super.willMove(toSuperview: newSuperview)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let view = object as? UIView, view == superview {
            if keyPath == "frame" || keyPath == "center" {
                if isTracked {
                    self.frameChangedClosure?((self.superview?.frame)!)
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isTracked {
            frameChangedClosure?(superview!.frame)
        }
    }
}
