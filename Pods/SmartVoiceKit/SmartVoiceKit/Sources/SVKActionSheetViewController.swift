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

/**
 An enum identifying each button contains in the actionsheet's toolbar
 */
public enum SVKActionSheetButtonIdentity: Int {
    case resend = 1
    case enunciate
    case comment
    case copy
    case share
    case delete
    case code
}

/**
 A protocol to implement when the SVKActionSeelController is used
 */
protocol SVKActionSheetViewControllerDelegate {
    /// Provide a feedback on a bubbles
    func provideFeedbackOnBubble(at: IndexPath)
    
    /// copy the content of a bubble at indexPath
    func copyBubble(at: IndexPath)
    
    /// delete a bubble at indexPath
    func deleteBubble(at: IndexPath)
    
    /// enunciated a bubble at indexPath
    func enunciateBubble(at: IndexPath)
    
    /// resend a bubble at indexPath
    func resendBubble(at: IndexPath)
    
    /// display view for debugging
    func displayBubbleJSON(at: IndexPath)
    
    /// share the bubble's content at indexPath
    func shareBubble(at: IndexPath)
}

/**
 The horizontal alignment of a view
 */
public enum SVKHorizontalAlignement {
    case left(CGFloat)
    case right(CGFloat)
}

class SVKActionSheetViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var toolBar: UIStackView!
    @IBOutlet var toolbarLeading: NSLayoutConstraint!
    @IBOutlet var toolbarBottom: NSLayoutConstraint!
    @IBOutlet var toolbarTrailing: NSLayoutConstraint!
    
    
    @IBOutlet weak var resendBtn: UIButton!
    @IBOutlet weak var enunciateBtn: UIButton!
    @IBOutlet weak var feedbackBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var codeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    
    /// the indexpPath to interact with
    public var actionIndexPath: IndexPath!
    
    /// the action shees delegate
    public var delegate: SVKActionSheetViewControllerDelegate?
    
    /// the completion handler called on dismiss
    public var completionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureButtons()
    }
    
    @IBAction func dismiss(_: UIGestureRecognizer?) {
        completionHandler?()
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    /**
     Sets the toolBar position from a relative position and aligns it
     - parameter relativePosition: The position from where the toolBar should be display
     - parameter alignment: The horizontal alignement
     */
    public func setToolBarPosition(relativePosition: CGPoint, alignment: SVKHorizontalAlignement) {
        toolbarBottom.constant = abs(view.bounds.height - relativePosition.y)
        switch alignment {
        case .left(let margin):
            toolbarLeading.constant = margin - 4
        case .right(let margin):
            toolbarTrailing.constant = margin - 10
            scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
            toolBar.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
        }
    }
    
    // MARK: actions
    
    /**
     Provide feedback / comment a buuble
     */
    @IBAction func provideFeedback(_ sender: Any) {
        delegate?.provideFeedbackOnBubble(at: actionIndexPath)
        dismiss(nil)
    }
    
    /**
     Resend a bubble
     */
    @IBAction func resendBubble(_ sender: Any) {
        delegate?.resendBubble(at: actionIndexPath)
        dismiss(nil)
    }
    
    /**
     Enunciate (vocalize) a bubble
     */
    @IBAction func enunciateBubble(_ sender: Any) {
        delegate?.enunciateBubble(at: actionIndexPath)
        dismiss(nil)
    }
    
    /**
     Delete a message
     */
    @IBAction func deleteBubble(_: Any) {
        delegate?.deleteBubble(at: actionIndexPath)
        dismiss(nil)
    }
    
    /**
     Display the code of a bubble
     Developper stuff
     */
    @IBAction func displayCode(_: Any) {
        delegate?.displayBubbleJSON(at: actionIndexPath)
        dismiss(nil)
    }
    
    @IBAction func copyBubble(_ sender: Any) {
        delegate?.copyBubble(at: actionIndexPath)
        dismiss(nil)
    }
    @IBAction func shareBubble(_ sender: UIButton) {
        delegate?.shareBubble(at: actionIndexPath)
        dismiss(nil)
    }
    
    /**
     Removes an action button from its tag
     */
    public func removeButton(identifiedBy tag: SVKActionSheetButtonIdentity) {
        toolBar.arrangedSubviews.first { $0.tag == tag.rawValue }?.removeFromSuperview()
    }
}


final class FeedbackButtonLabel: UILabel {
    override func awakeFromNib() {
        self.text = self.text?.localized
    }
}

extension SVKActionSheetViewController{
    fileprivate func configureButtons(){
        // set right images configured either in json or in-code
        enunciateBtn.setImage(SVKAppearanceBox.Assets.longPressPlay, for: .normal)
        feedbackBtn.setImage(SVKAppearanceBox.Assets.longPressMisunderstood, for: .normal)
        deleteBtn.setImage(SVKAppearanceBox.Assets.longPressDelete, for: .normal)
        shareBtn.setImage(SVKAppearanceBox.Assets.longPressShare, for: .normal)
        resendBtn.setImage(SVKAppearanceBox.Assets.longPressResend, for: .normal)
        
        // scale image inside the button to deal with all asset's sizes
        [enunciateBtn, feedbackBtn, deleteBtn, shareBtn, resendBtn]
            .forEach {$0?.imageView?.contentMode = .scaleAspectFill }
    }
}
