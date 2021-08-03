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

class SVKFeedbackOptInViewController: UIViewController {

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var headLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    
    @IBOutlet var refuseButton: SVKCustomButton!
    @IBOutlet var acceptButton: SVKCustomButton!
    @IBOutlet var badgeContainer: UIView!
    @IBOutlet var buttonsContainer: SVKStandardPageButtonView!
    
    /// The feedback protocol delegate
    public var delegate: SVKFeedbackViewControllerDelegate?
    
    /// The header text
    public var headerText = "feedback.optin.head".localized
    
    /// The subheader text
    public var feedbackOptinBodyKey = ".feedback.optin.body"
    public var prefixFeedbackOptinBodyKey = "djingo"
    
    public var trustBadgeDeeplink: String?
    public var shouldDisplayBadge: Bool = true
    public var shouldDropShadow: Bool = false
    public var fonts: (headFont: UIFont, bodyFont: UIFont) = (UIFont.systemFont(ofSize: 20, weight: .bold), UIFont.systemFont(ofSize: 16))
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = "feedback.optin.title".localized
    }
    
    public var bubbleDescription: SVKBubbleDescription!
    var isDefaultNavigationBarHidden = false

    override public func viewDidLoad() {
        super.viewDidLoad()
        iconImage.image = SVKAppearanceBox.Assets.consentScreen
        headLabel.text = headerText
        bodyLabel.text = (prefixFeedbackOptinBodyKey + feedbackOptinBodyKey).localized
        
        let setupLabels = {
            self.headLabel.textAlignment = SVKAppearanceBox.TextAlignement.feedbackPage
            self.bodyLabel.textAlignment = SVKAppearanceBox.TextAlignement.feedbackPage
            
            self.headLabel.font = self.fonts.headFont
            self.bodyLabel.font = self.fonts.bodyFont
        }
        setupLabels()
        
        acceptButton.setTitle("feedback.optin.accept".localized, for: .normal)
        acceptButton.fillColor = SVKConversationAppearance.shared.hightlightedBtnColor
        acceptButton.highlightedFillColor = SVKConversationAppearance.shared.hightlightedBtnColor
        acceptButton.shapeColor = SVKConversationAppearance.shared.hightlightedBtnColor
        refuseButton.setTitle("feedback.optin.refuse".localized, for: .normal)
        let decorateButtonsView = {
            if self.shouldDropShadow{
                self.dropShadow()
            }else{
                self.dropSeparatorLine()
            }
        }
        
        decorateButtonsView()
        view.backgroundColor = SVKAppearanceBox.shared.appearance.backgroundColor.color
        buttonsContainer.updateSeparatorLine()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bodyLabel.text = (prefixFeedbackOptinBodyKey + feedbackOptinBodyKey).localized
        SVKAnalytics.shared.startActivity(name: "myactivity_feedback_rights_acceptance", with: nil)
        if trustBadgeDeeplink == nil || !shouldDisplayBadge{
            badgeContainer.removeFromSuperview()
        }
        self.navigationItem.hidesBackButton = true
        isDefaultNavigationBarHidden = (self.navigationController?.navigationBar.isHidden == true)
        if isDefaultNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? SVKFeedbackViewController {
            viewController.delegate = delegate
            viewController.bubbleDescription = bubbleDescription
            viewController.navigationItem.hidesBackButton = true
        }
    }

    @IBAction func openTrustBadge(sender: Any?) {
        guard let urlString = trustBadgeDeeplink,
            let URL = URL(string: urlString),
            UIApplication.shared.canOpenURL(URL) else {
                return
        }
        UIApplication.shared.open(URL, options: [:]) { success in
            if success {
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func confirm(sender: Any?) {
        SVKAnalytics.shared.log(event: "myactivity_feedback_rights_acceptance_validate")
        delegate?.authorizeFeedback() { (success) in
            
            DispatchQueue.main.async {
                if !success {
                    SVKAnalytics.shared.log(event: "myactivity_feedback_rights_acceptance_confirmation_error")
                    DispatchQueue.main.safeAsync {
                        
                        let toastData = SVKToastData(with: .default, message: "SVK.toast.consent.error.message".localized)
                        
                        self.view.showToast(with: toastData)                        
                    }
                } else {
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackViewController") as? SVKFeedbackViewController {
                        viewController.delegate = self.delegate
                        viewController.bubbleDescription = self.bubbleDescription
                        viewController.modalPresentationStyle = .fullScreen
                        viewController.isDefaultNavigationBarHidden = self.isDefaultNavigationBarHidden
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func cancel(sender: Any?) {
        if isDefaultNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        SVKAnalytics.shared.log(event: "myactivity_feedback_rights_acceptance_cancel")
        self.navigationController?.popViewController(animated: true)
    }

}

extension SVKFeedbackOptInViewController{
    private func dropShadow() {
        let shadowHeight: CGFloat = 1
        let shadowOpacity: Float = 0.9
        let shadowWidth = self.view.frame.width//buttonsContainer.bounds.width
        let contactRect = CGRect(x: 0,
                                 y: shadowHeight * 2 ,
                                 width: shadowWidth,
                                 height: shadowHeight)
        
        buttonsContainer.layer.shadowPath = UIBezierPath(rect: contactRect).cgPath
//        buttonsContainer.layer.shadowRadius = 3
        buttonsContainer.layer.shadowOpacity = shadowOpacity
        buttonsContainer.layer.shadowColor = SVKAppearanceBox
            .shared
            .appearance
            .buttonStyle
            .highlightedState
            .fillColor
            .color
            .cgColor
    }
    
    private func dropSeparatorLine() {
        let width = self.view.frame.width//buttonsContainer.bounds.width
        let separatorRect = CGRect(x: 0, y: 0, width: width, height: 1)
        let shape: CAShapeLayer = CAShapeLayer()
        shape.path = UIBezierPath(rect: separatorRect).cgPath
        
        shape.strokeColor = UIColor.dividerColor.cgColor
        buttonsContainer.layer.addSublayer(shape)

    }
}
