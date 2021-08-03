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
public class SVKAudioSignalIndicatorView: UIView {
    
    private var stackView: UIStackView = UIStackView()
    private var channelViews = [ChannelView]()
    
    /// The content inset
    public let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    /// The number of channels. Default is 5
    @IBInspectable public var numberOfChannels: Int {
        set {
            guard newValue != channelViews.count else { return }
            setNumberOfChannels(max(1, newValue))
        }
        get {
            return channelViews.count
        }
    }
    
    /// The size of a channel. Default is 10
    @IBInspectable public var channelWidth: CGFloat = 5 {
        didSet {
            setNumberOfChannels(numberOfChannels)
        }
    }
    
    /// The channel background color
    @IBInspectable
    public var channelColor: UIColor = UIColor(red: 239/255, green: 110/255, blue: 29/255, alpha: 1) {
        didSet {
            channelViews.forEach {
                $0.backgroundColor = channelColor
            }
        }
    }
    
    /// The space between channels. Default is 5.
    @IBInspectable public var spacing: CGFloat = 5 {
        didSet {
            stackView.spacing = spacing
        }
    }
    
    /// The time for a channel to reach 0 db from rest position. Default is 300 ms.
    public var levelUpDuration = 0.03
    
    /// The time for a channel to reach the rest position from the current level. Default is 1s.
    public var levelDownDuration = 1.0
    
    /// The mininum decibel level representing the dynamic range [0..minimumDB] Default is -80
    public let minumumDB: Float = -80.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        
        backgroundColor = .clear
        numberOfChannels = 5
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        self.addSubview(stackView)
        NSLayoutConstraint.activate(
            [stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: contentInset.left),
             stackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: contentInset.right),
             stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: contentInset.top),
             stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: contentInset.bottom)]
        )
    }
    
    private func setNumberOfChannels(_ count: Int) {
        
        stackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        channelViews.removeAll()
        
        let frame = CGRect(x: 0, y: 0, width: channelWidth, height: self.frame.height)
        for _ in 0..<count {
            let channelView = ChannelView(frame: frame)
            channelView.setLevel(0, animated: false)
            channelView.backgroundColor = channelColor
            channelViews.append(channelView)
            stackView.addArrangedSubview(channelView)
        }

        stackView.spacing = spacing
    }
    
    /**
     Apply the current db level and animate the view
     - parameter dbLevel: The db level in RMS
     */
    public func setDecibelLevel(_ dbLevel: Float) {
        var level = scaledPower(power: dbLevel)
        
        var channel = ((numberOfChannels / 2) + Int(ceil(Double(numberOfChannels % 2)))) - 1
        channel = Int.random(in: 0..<numberOfChannels)
        self.channelViews[channel].setLevel(level, animated: true)

        var offset = 1
        var stopDecrease = false
        var stopIncrease = false
        repeat {
            if channel - offset >= 0 {
                self.channelViews[channel-offset].setLevel(level, animated: true)
            } else {
                stopDecrease = true
            }
            
            if channel + offset < numberOfChannels {
                self.channelViews[channel+offset].setLevel(level, animated: true)
            } else {
                stopIncrease = true
            }
            level -= 0.2
            offset += 1
        } while !stopDecrease && !stopIncrease
    }

    /**
     Set the state as silent
     
     Every channel are set to 0
     - parameter animated: **true** for animation
     */
    public func setSilentAnimated(_ animated: Bool) {
        channelViews.forEach { $0.setLevel(0, animated: animated, duration: 2) }
    }
    /*
     Transforms the RMS into an input for displaying each channel
     */
    fileprivate func scaledPower(power: Float) -> CGFloat {
        guard power.isFinite else { return 0.0 }
        if power <= minumumDB {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        }
        return CGFloat((abs(minumumDB) - abs(power)) / abs(minumumDB))
    }

    /*
     IB stuffs
     */
    public override func prepareForInterfaceBuilder() {
        stackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        channelViews.forEach {
            $0.setLevel(CGFloat.random(in: 0..<0.4), animated: false)
            stackView.addArrangedSubview($0)
        }
    }
}
/**
 A class representing a level of a VolumeIndicator.
 
 
 */
internal final class ChannelView: UIView {
    
    /// The audio level of this channel. 0 to 1.0
    private(set) var level: CGFloat = 1 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    private var heightConstraint: NSLayoutConstraint!
    private var standtardHeight: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = frame.width / 2
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        standtardHeight = frame.height
        
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil, attribute: .height,
                                              multiplier: 1, constant: standtardHeight)
        self.addConstraints([heightConstraint])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: standtardHeight * level)
    }
    
    /**
     Sets the level.
    
     The value is between 0.0 and 1.0
     - parameter level: the audio level
     - parameter animated: true if the change should be animated
     - parameter duration: The duration of the animation. Default is 0.095
     */
    public func setLevel(_ level: CGFloat, animated: Bool, duration: TimeInterval = 0.095) {
        self.level = max(0, min(1, level))
        UIView.animate(withDuration: animated ? duration : 0, delay: 0.0, options: [.curveEaseOut], animations: {
            self.heightConstraint.constant = max(self.frame.width, self.standtardHeight * self.level)
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }
}
