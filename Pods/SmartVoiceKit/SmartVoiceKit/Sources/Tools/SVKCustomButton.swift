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

@IBDesignable
@objc 
open class SVKCustomButton: UIButton {

    private let shapeLayer = CAShapeLayer()
    
    // IB customization
    @IBInspectable open dynamic var layerBorderWidth: CGFloat {
        set { shapeLayer.lineWidth = newValue }
        get { return shapeLayer.lineWidth }
    }
    
    @IBInspectable open dynamic var layerCornerRadius: CGFloat = 0
    @IBInspectable open dynamic var drawShape: Bool = false
    @IBInspectable open dynamic var fillColor: UIColor = {
        if #available(iOS 13.0, *){
            return .systemBackground
        }
        return .white
    }()
    @IBInspectable open dynamic var shapeColor: UIColor = {
        if #available(iOS 13.0, *){
            return .label
        }
        return .black
    }()
    @IBInspectable open dynamic var shapeDisabledColor: UIColor = .lightGray
    @IBInspectable open dynamic var highlightedFillColor: UIColor = {
        if #available(iOS 13.0, *){
            return .label
        }
        return .black
    }()
    @IBInspectable open dynamic var selectedFillColor: UIColor = .clear
    
    @objc public var isMultipleLineEnabled: Bool = false {
        didSet {
            titleLabel?.numberOfLines = isMultipleLineEnabled ? 0 : 1
            titleLabel?.textAlignment = .center
            setNeedsLayout()
        }
    }
    
    private func initialize() {
        isOpaque = true
        tintColor = .clear
        
        shapeLayer.borderColor = shapeColor.cgColor
        self.layer.insertSublayer(shapeLayer, at: 0)
        isHighlighted = false
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    

    override open func layoutSubviews() {
        super.layoutSubviews()

        if layerCornerRadius > 0 {
            shapeLayer.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners:[.topLeft, .topRight, .bottomLeft, .bottomRight],
                                     cornerRadii: CGSize(width: layerCornerRadius, height: layerCornerRadius)).cgPath
        } else {
            shapeLayer.path = UIBezierPath(rect: self.bounds).cgPath
        }
        shapeLayer.frame = self.bounds
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    private func updateLayer() {
        if isHighlighted {
            shapeLayer.strokeColor = highlightedFillColor.cgColor
            shapeLayer.fillColor =  self.highlightedFillColor.cgColor
        }
        else if isSelected {
            shapeLayer.strokeColor = selectedFillColor.cgColor
            shapeLayer.fillColor =  self.selectedFillColor.cgColor
        }
        else {
            shapeLayer.strokeColor = self.isEnabled ? shapeColor.cgColor : shapeDisabledColor.cgColor
            shapeLayer.fillColor = self.fillColor.cgColor
        }
    }

    override open func layoutSublayers(of layer: CALayer) {
        updateLayer()
        super.layoutSublayers(of: layer)
    }

    override open var isHighlighted: Bool {
        didSet {
            updateLayer()
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            updateLayer()
        }
    }

    override open var isEnabled: Bool {
        didSet {
            shapeLayer.strokeColor = self.isEnabled ? shapeColor.cgColor : shapeDisabledColor.cgColor
            shapeLayer.fillColor = self.fillColor.cgColor
        }
    }

    override open var buttonType: UIButton.ButtonType {
        return .custom
    }
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *){
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection){
                updateDark()
            }
        }
    }
    private func updateDark(){
        shapeLayer.strokeColor = highlightedFillColor.cgColor
        shapeLayer.fillColor =  fillColor.cgColor
    }
}



extension SVKCustomButton {
    @objc public dynamic var titleLabelFont: UIFont! {
        get { return self.titleLabel?.font }
        set { self.titleLabel?.font = newValue }
    }
}
