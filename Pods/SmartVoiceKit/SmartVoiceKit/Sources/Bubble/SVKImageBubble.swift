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

public class SVKImageBubble: SVKBubble {

    /*
     A UIImageView wich display the bubble image
     */
    private var imageView = UIImageView()
    
    override public func setup() {
        
        super.setup()
        clipsToBounds = true
        
        // setup the imageView
        self.contentInset = .zero
        setupImageView()
    }
    
    open override var translatesAutoresizingMaskIntoConstraints: Bool {
        didSet {
            let constraint = self.constraints.first
            constraint?.isActive = false
        }
    }

    override open func layoutSubviews() {
        imageView.frame = self.bounds.inset(by: contentInset)
    }

    private func setupImageView() {
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        self.layer.addSublayer(imageView.layer)
       }
    
    /// The image of the bubble
    public var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
    /// Set the property if the image is animated
    public var animationImages: [UIImage]? {
        get {
            return imageView.animationImages
        }
        set {
            imageView.animationImages = newValue
        }
    }
    
    /// Sets the imageView contentMode
    public var imageViewContentMode: UIView.ContentMode {
        get {
            return imageView.contentMode
        }
        set {
            imageView.contentMode = newValue
        }
    }
    
    /// Starts the animation
    public func startAnimating() {
        imageView.startAnimating()
    }

    /// Stop the animation
    public func stopAnimating() {
        imageView.stopAnimating()
    }

    override open func prepareForInterfaceBuilder() {
        setup()
    }

}
