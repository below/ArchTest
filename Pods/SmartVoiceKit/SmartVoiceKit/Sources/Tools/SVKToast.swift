//
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
import AudioToolbox

fileprivate extension CGFloat {
    static var oneLine: CGFloat = 46
    static var oneLineAction: CGFloat = 72
    static var twoLines: CGFloat = 64
    static var twoLinesAction: CGFloat = 90
}

fileprivate struct SVKToastConfig{
    static var widthCoef: CGFloat = 0.9
    static var imgSide: CGFloat = 30
    static var transitionTime: TimeInterval = 0.3
    static var cornerRadius: CGFloat = 4
    static var defaultWidth: CGFloat = 200
    static var defaultHeight: CGFloat = 100
    static var horizontalSpacing: CGFloat = 8
    static var elementsSpacing: CGFloat = 8
}
public class SVKToast: UIView {
    fileprivate var timer: Timer?
    var toastData: SVKToastData? = nil
    
    var completionHandler: (() -> Void)? = nil
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.timer?.invalidate()
        self.timer = nil
        if let action = self.toastData?.action{
            action.handler?(action)
        }
        remove()
    }
    
    func remove() {
        UIView.animate(withDuration: config.transitionTime, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            self.alpha = 0.0
        }) { _ in
            
            guard let wrapper = self.superview as? SVKSnackBar else{
                self.removeFromSuperview()
                return
            }
            self.removeFromSuperview()
            wrapper.removeFromSuperview()
        }
    }
    
}

class SVKSnackBar: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let myToast = self.subviews.compactMap({$0 as? SVKToast}).first else{
            return
        }
        let touch = touches.first
        guard let location = touch?.location(in: self) else { return }
        if !myToast.frame.contains(location) {
            myToast.timer?.invalidate()
            myToast.timer = nil
            myToast.remove()
            myToast.completionHandler?()
        }
        
    }
    
}
public extension UIView {
    fileprivate typealias config = SVKToastConfig
    
    func showToast(with data: SVKToastData, completionHandler: (() -> Void)? = nil) {
        // remove old toast if there is one
        removePresentedToastIfNeeded()
        
        if (data.type == .default) {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let toast = createToastView(for: data,completionHandler: completionHandler)
        
        // set center here
        let point = centerPoint(forToast: toast, inSuperview: self, offset: data.offset)
        toast.center = point
        
        toast.alpha = 0.0
        
        
        ///
        let snackbar = SVKSnackBar(frame: self.frame)
        self.addSubview(snackbar)
        snackbar.center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2 )
        
        snackbar.addSubview(toast)
        UIView.animate(withDuration: config.transitionTime, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            toast.alpha = 1.0
        }) { _ in
            let timer = Timer(timeInterval: data.duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
            timer.tolerance = 0.1
            RunLoop.main.add(timer, forMode: .common)
            toast.timer = timer
        }
    }

    func showNoInternetToast() {
        let toastData = SVKToastData(with: .networking, message: "SVK.toast.no.internet.error.message".localized)
        showToast(with: toastData)
    }

    @objc
    private func toastTimerDidFinish(_ timer: Timer) {
        guard let toast = timer.userInfo as? SVKToast else { return }
        toast.remove()
        toast.completionHandler?()
    }
    
    func createToastView(for message: SVKToastData,completionHandler: (() -> Void)? = nil) -> SVKToast {
        let toast = SVKToast()
        toast.backgroundColor = SVKAppearanceBox.Toast.backgroundColor//.white
        toast.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        toast.layer.cornerRadius = config.cornerRadius
        
        var wrapperWidth = config.defaultWidth
        
        if let _w = superview?.bounds.width{
            wrapperWidth = _w - 2 * config.horizontalSpacing
        } else {
            wrapperWidth = self.bounds.size.width - 2 * config.horizontalSpacing
        }
        
        var wrapperHeight: CGFloat = config.defaultHeight
        
        toast.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        let stackView = createStackView(for: message)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16).isActive = true
        stackView.topAnchor.constraint(equalTo: toast.topAnchor, constant: 8).isActive = true
        stackView.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16).isActive = true
        stackView.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -8).isActive = true
        toast.toastData = message
        toast.completionHandler = completionHandler
        toast.layoutIfNeeded()
        wrapperHeight = recalculateHight(ofToast: toast)
        toast.bounds.size.height = wrapperHeight
        
        return toast
    }
    
    @discardableResult
    private func removePresentedToastIfNeeded() -> Bool {
        let myToasts = self.subviews.compactMap{ $0 as? SVKToast }
        guard myToasts.count > 0 else {
            return false
        }
        myToasts.forEach {
            $0.remove()
        }
        return true
    }
    
    @discardableResult
    private func nbLinesForMsgLabel(in v: SVKToast) -> Int{
        guard let _vStack = v.subviews.compactMap({$0 as? UIStackView}).first,
              let _hStack = _vStack.arrangedSubviews.compactMap({$0 as? UIStackView}).first,
              let txtLbl = _hStack.arrangedSubviews.compactMap({$0 as? SVKMessageLabel}).first
        else{
            return 0
        }
        
        return txtLbl.maxNumberOfLines
    }
    
    fileprivate func createStackView(for message: SVKToastData) -> UIStackView {
        let vStack   = UIStackView()
        vStack.spacing = config.elementsSpacing
        vStack.axis = .vertical
        vStack.distribution = .fillProportionally
        vStack.alignment = .fill
        
        let hStack = UIStackView()
        hStack.spacing = config.elementsSpacing
        hStack.distribution  = .fill
        hStack.alignment = .center
        
        // add Image
        let logo = UIImageView(image: message.type.image)
        
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.widthAnchor.constraint(equalToConstant: config.imgSide).isActive = true
        logo.heightAnchor.constraint(equalToConstant: config.imgSide).isActive = true
        
        hStack.addArrangedSubview(logo)
        // add message
        let messageLabel = SVKMessageLabel()
        messageLabel.text  = message.message
        messageLabel.textAlignment = .left
        messageLabel.numberOfLines = 2
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.8
        /// fix for iOS 10
        messageLabel.textColor = SVKAppearanceBox
            .shared
            .appearance
            .toastStyle
            .textColor
            .color
        messageLabel.font = SVKAppearanceBox
            .shared
            .appearance
            .toastStyle
            .textFont
            .font
        
        hStack.addArrangedSubview(messageLabel)
        
        vStack.addArrangedSubview(hStack)
        
        // add action label
        guard let actionTxt = message.action?.title else {
            return vStack
        }
        
        let actionLabel = SVKActionLabel()
        actionLabel.text  = actionTxt
        actionLabel.textAlignment = .right
        
        /// fix for iOS 10
        actionLabel.textColor = SVKAppearanceBox
            .shared
            .appearance
            .toastStyle
            .actionTextColor
            .color
        actionLabel.font = SVKAppearanceBox
            .shared
            .appearance
            .toastStyle
            .actionTextFont
            .font
        
        vStack.addArrangedSubview(actionLabel)
        
        return vStack
    }
    
    fileprivate func centerPoint(forToast toast: UIView, inSuperview superview: UIView, offset: Float = 0.0) -> CGPoint {
        let bottomPadding: CGFloat = SVKAppearanceBox.Toast.verticalSpacing + superview.svkSafeAreaInsets.bottom
        return CGPoint(x: superview.bounds.size.width / 2.0, y: (superview.bounds.size.height - (toast.frame.size.height / 2.0)) - bottomPadding - CGFloat(offset))
    }
    
    private func recalculateHight(ofToast toast: SVKToast) -> CGFloat{
        var wrapperHeight: CGFloat = .twoLinesAction // 2 lines + action title => full armor toast
        let numberOfLines = nbLinesForMsgLabel(in: toast)//data.message.numberOfLines(for: viewWidth * 0.9, and: SVKBlocDescriptionLabel().font)
        let action: SVKAction? = toast.toastData?.action
        if numberOfLines > 1 {// two lines
            if action == nil {
                wrapperHeight = .twoLines // 2 lines without action title
            }
        }else{ // one line
            wrapperHeight = .oneLineAction // one line with action title
            if action == nil {
                wrapperHeight = .oneLine // 1 line without action title
            }
        }
        return wrapperHeight
    }
    
}
private extension UIView {
    
    var svkSafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
}
public typealias SVKActionHandler = (SVKAction) -> Void
public class SVKAction {
    /// Short display title.
    public var title: String
    /// an action to execute
    public var handler: SVKActionHandler?
    
    /// Creates a SVKAction with the given arguments.
    ///
    /// - Parameters:
    ///   - title: The action's title.
    ///   - handler: Handler block. Called when the user selects the action.
    public init(title: String, handler: SVKActionHandler? = nil){
        // no need to set it @escaping, it's optional so it's already @escaping
        self.title = title
        self.handler = handler
    }
}

public struct SVKToastData {
    public enum ToastType {
        case `default`, confirmation, networking
        var image: UIImage? {
            get {
                switch self {
                case .default:
                    return SVKAppearanceBox.Toast.iconDefault
                case .confirmation:
                    return SVKAppearanceBox.Toast.iconConfirmation
                case .networking:
                    return SVKAppearanceBox.Toast.iconNoWifi
                }
            }
        }
    }
    public var type: ToastType = .default
    
    /// Message you want to display to the user
    public var message: String
    
    /// Y offset to provide a custom marging for current Toast
    public var offset: Float
    
    /**
     The default duration. Used for the `showToast`.
     Default is 3.0.
     */
    public var duration: TimeInterval = 3.0
    /// Action message shown
    public var action: SVKAction? = nil
    public init(with type: ToastType = .default,
                message: String,
                duration: TimeInterval = 3.0,
                offset: Float = 0,
                action: SVKAction? = nil){
        self.type = type
        self.message = message
        self.action = action
        self.duration = duration
        self.offset = offset
    }
}
