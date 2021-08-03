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


class SVKLoadMoreControl: UIControl {
    
    /// the animation duration
    private let animationDuration: TimeInterval = 0.2
    
    /// The inset
    private let inset: CGFloat = 50
    private var transientInset: CGFloat = 0
    
    private let defaultHeight = 200
    
    let activityAnimationImages = UIImage.animationImages(named: "A-07-01-Lop24", bundle: SVKBundle, withExtension: "gif")
    
    let activityAnimationImageView = UIImageView()
    var indicator: SVKRotator = SVKRotator(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
    public enum UILoadMoreControlPosition: Int {
        case bottom
        case top
    }
    
    /// The control's position in the tableView
    private var position: UILoadMoreControlPosition = .bottom

    /// The label
    private var label: UILabel!

    /// the pull distance in pixels. Default is 60
    public var pullDistance: CGFloat = 60
    
    /// the activity indicator
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)

    private var panGestureState: UIGestureRecognizer.State = .possible
    private var lastUpdateDate: Date? = nil
    
    public var locale = Locale(identifier: "en_EN") {
        didSet {
            lastUpdateDate = nil
            label.text = lastUpdateText
        }
    }

    public var currentActivity: SVKActivityIndicatorProtocol {
        get {
            switch animationType{
            case .activityIndicator:
                return self.activityIndicator
            case .lop24:
                return self.activityAnimationImageView
            case .rotator:
                return self.indicator
            }
        }
        // due to build failed when using currentActivity.isHidden = true set must be present
        set(value) {
            
        }
    }
    
    /// true if loading is going on
    private(set) var isLoading: Bool = false
    
    /// Control text
    public var text: String = "" {
        didSet {
            label.text = text
        }
    }
    
    public var animationType: SVKLoadMoreControlAnimationType = SVKLoadMoreControlAnimationType.activityIndicator
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func layoutIndicator(_ position: SVKLoadMoreControl.UILoadMoreControlPosition) {
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isHidden = true
        self.addSubview(indicator)
        if position == .bottom {
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                indicator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
                indicator.widthAnchor.constraint(equalToConstant: 35),
                indicator.heightAnchor.constraint(equalToConstant: 35)
            ])
        } else {
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                indicator.bottomAnchor.constraint(equalTo: label.topAnchor, constant: 0),
                indicator.widthAnchor.constraint(equalToConstant: 35),
                indicator.heightAnchor.constraint(equalToConstant: 35)
            ])
        }
        indicator.rotationSpeed = .high
        indicator.indicatorWidth = 3
        indicator.indicatorColor = UIColor(hex: "#B2B2B2").cgColor
    }
    
    /**
     Initializes and returns a newly allocated SVKLoadMoreControl object for a specific position.
     - parameter position: The position **UILoadMoreControlPosition** of the control in the tableView
     - returns: An initialized SVKLoadMoreControl object.
     */
    init(position: UILoadMoreControlPosition, animationType:SVKLoadMoreControlAnimationType) {
        super.init(frame: .zero)
        
        self.position = position
    
        label = UILabel(frame: frame)
        label.text = lastUpdateText
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.dateGray
        label.font = UIFont.loader
        label.numberOfLines = 2
        label.textAlignment = .center
        self.addSubview(label)
        
        if position == .bottom {
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                label.topAnchor.constraint(equalTo: self.topAnchor, constant: 8.0)
                ])
        } else {
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8.0)
                ])
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = false
        activityIndicator.isHidden = true
        
        self.addSubview(activityIndicator)
        
        if position == .bottom {
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                activityIndicator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5)
                ])
        } else {
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                activityIndicator.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -5)
                ])
        }
        
        activityAnimationImageView.translatesAutoresizingMaskIntoConstraints = false
        activityAnimationImageView.isHidden = true
        self.addSubview(activityAnimationImageView)
        if let images = activityAnimationImages {
            activityAnimationImageView.animationImages = images
            activityAnimationImageView.animationDuration = 0
            activityAnimationImageView.animationRepeatCount = 0
            activityAnimationImageView.image = images.first
            if position == .bottom {
                NSLayoutConstraint.activate([
                    activityAnimationImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    activityAnimationImageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
                    activityAnimationImageView.widthAnchor.constraint(equalToConstant: 35),
                    activityAnimationImageView.heightAnchor.constraint(equalToConstant: 35)
                    ])
            } else {
                NSLayoutConstraint.activate([
                    activityAnimationImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    activityAnimationImageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -5),
                    activityAnimationImageView.widthAnchor.constraint(equalToConstant: 35),
                    activityAnimationImageView.heightAnchor.constraint(equalToConstant: 35)
                    ])
            }
        }
        activityAnimationImageView.contentMode = .scaleAspectFit
        
        layoutIndicator(position)
        self.frame = CGRect(x: 0, y: 0, width: 0, height: defaultHeight)
        self.animationType = animationType
        self.backgroundColor = UIColor.clear
    }

    /**
     begin loading
     */
    public func beginLoading() {
        guard !isLoading else { return }
        isLoading = true
    }

    /**
     end loading
     */
    public func endLoading(animated: Bool = true, completionHandler: (()->Void)? = nil) {
        guard isLoading, let scrollView = superview as? UIScrollView else {
            return }
        isLoading = false
        lastUpdateDate = Date()
        
        var contentInset = scrollView.contentInset
        if position == .bottom {
            contentInset.bottom = transientInset
        } else {
            contentInset.top = transientInset
        }

        // synchronously stop the animation
        stopAnimating(animated: animated) {
            self.label.text = self.lastUpdateText
            DispatchQueue.main.async {
                completionHandler?()
                if animated
                || self.position == .bottom {
                    scrollView.contentInset = contentInset
                }
                if self.position == .top {
                    scrollView.contentInset = contentInset
                }
            }
        }
    }
    
    /**
     Start the activityIndicator animation
     */
    public func startAnimating(_ completionHandler: @escaping (()->Void)) {
        currentActivity.isHidden = false
        currentActivity.startAnimating()
        self.setNeedsLayout()
        self.setNeedsDisplay()
        if let scrollView = self.superview as? UIScrollView {
            var contentInset = scrollView.contentInset
            if position == .bottom {
                contentInset.bottom += max(0, scrollView.frame.height - scrollView.contentSize.height) + self.inset
                transientInset = scrollView.contentInset.bottom
                
                UIView.animate(withDuration: animationDuration, animations: {
                    scrollView.contentInset = contentInset
                    var y = scrollView.contentSize.height - scrollView.frame.height + self.inset
                    if contentInset.bottom > self.inset {
                        y = self.inset
                    }
                    scrollView.contentOffset = CGPoint(x: 0, y: y)
                }) { (finished) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: completionHandler)
                }
            } else {
                contentInset.top +=  self.inset
                transientInset = scrollView.contentInset.top
                UIView.animate(withDuration: animationDuration, animations: {
                    scrollView.contentInset = contentInset
                    scrollView.contentOffset = CGPoint(x: 0, y: -self.inset)
                }) { (finished) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: completionHandler)
                }
            }
        }
    }

    /**
     Stop the activityIndicator animation
     */
    public func stopAnimating(animated: Bool = true, completionHandler: @escaping (()->Void)) {
        currentActivity.stopAnimating()
        currentActivity.isHidden = true
  
        guard let scrollView = self.superview as? UIScrollView else {
            completionHandler()
            return
        }
        
        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                let y = self.position == .bottom ?  max(0, scrollView.contentSize.height - scrollView.frame.height) : 0
                scrollView.contentOffset = CGPoint(x: 0, y: y)
            }) { (finished) in
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }

    var lastUpdateText: String {
        guard let date = lastUpdateDate else {
            return "Pull to refresh".localized
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        let day = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "HH:mm"
        return "Pull to refresh".localized + "\n" + "Last update".localized + " \(day) \(dateFormatter.string(from: Date()))"
    }

    func evaluateValueChanged(for scrollView: UIScrollView, headerOffset: CGFloat) {
        // if the control is visible
        guard let _ = self.superview else { return }
        
        if  !self.isEnabled { return }
        
        switch scrollView.panGestureRecognizer.state {
        case .possible where panGestureState == .changed,
             .ended where panGestureState == .changed:
            panGestureState = .possible
            if !activityIndicator.isAnimating {
                label.text = "Updating".localized
                startAnimating() {
                    self.sendActions(for: .valueChanged)
                }
            }
        case .changed where panGestureState == .possible:
            if isVisible(in: scrollView,headerOffset: headerOffset) {
                panGestureState = .changed
                label.text = "Release to update".localized
                UISelectionFeedbackGenerator().selectionChanged()
                
                currentActivity.isHidden = false
                
            }
        case .changed where panGestureState == .changed:
            if !isVisible(in: scrollView,headerOffset: headerOffset) {
                panGestureState = .failed
                label.text = lastUpdateText
                currentActivity.isHidden = true
            }
            
        case .possible where panGestureState == .failed:
            panGestureState = .possible
            currentActivity.isHidden = true
        case .failed :
            panGestureState = .possible
             currentActivity.isHidden = true
        case .cancelled, .ended:
            panGestureState = .possible
            currentActivity.isHidden = !self.currentActivity.isAnimating
        default:
            break
        }
    }
    
    /**
     Return true if the control is entirely visible in it's superview
    */
    fileprivate func isVisible(in view: UIScrollView, headerOffset: CGFloat) -> Bool {
        guard let superview = view.superview else { return false }
        
        var extendedFrame = frame
        if position == .bottom {
            extendedFrame.size.height = pullDistance - headerOffset
        } else {
            extendedFrame.size.height = pullDistance - headerOffset
            extendedFrame.origin.y = -pullDistance
        }
        
        var visibleFrame = superview.frame
        if position == .top,
            let tableView = view as? UITableView,
            let y = tableView.tableHeaderView?.frame.height {
            visibleFrame.origin.y = y
        }
        visibleFrame.size.height = view.frame.height
        visibleFrame.origin.y = 0
        let controlFrame = superview.convert(extendedFrame, from: self.superview)
        let response = visibleFrame.contains(controlFrame)
        return response
    }

    //MARK: layout
    override func layoutSubviews() {
        if let scrollView = superview as? UIScrollView {
            var frame = scrollView.frame
            frame.origin.y = position == .top ? -frame.size.height : max(scrollView.contentSize.height, scrollView.frame.height)
            self.frame = frame
        }
        super.layoutSubviews()
    }

}

extension SVKLoadMoreControl {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *){
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection){
                activityIndicator.style = traitCollection.userInterfaceStyle == .dark ? .white : .gray
            }
        }
    }
}


extension SVKLoadMoreControl {
    func trigger() {
        guard !isLoading else { return }
        if let scrollView = superview as? UIScrollView {
            let y = position == . bottom ? scrollView.contentOffset.y - frame.height : -self.inset
            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
        }
        
        label.text = "Updating".localized
        self.sendActions(for: .valueChanged)
            
        startAnimating {
        }
    }
}

extension UIActivityIndicatorView: SVKActivityIndicatorProtocol {}
extension UIImageView: SVKActivityIndicatorProtocol {}
extension SVKRotator: SVKActivityIndicatorProtocol{
    var isAnimating: Bool {
        animating
    }
    
    func startAnimating() {
        start()
    }
    
    func stopAnimating() {
        stop(animation: .none)
    }
    override var isHidden: Bool{
        didSet{
            lurkSpinner(isHidden)
        }
    }
}

/**
 The public protocol of a activity
 */
public protocol SVKActivityIndicatorProtocol {
    
    var isHidden:Bool {get set}
    
    var isAnimating:Bool {get}
    
    func startAnimating()
    
    func stopAnimating()
}

public enum SVKLoadMoreControlAnimationType {
    case activityIndicator, lop24, rotator
}
