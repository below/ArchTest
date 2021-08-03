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

public class SVKDeleteUserViewController: UIViewController {

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var headLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    
    @IBOutlet var cancelButton: SVKCustomButton!
    @IBOutlet var confirmButton: SVKCustomButton!
    @IBOutlet var buttonsContainer: SVKStandardPageButtonView!
    
    @IBOutlet var scrollViewTraling: NSLayoutConstraint!
    @IBOutlet var scrollViewLeading: NSLayoutConstraint!
    /// The history protocol delegate
    public var delegate: SVKUserProtocol?
    
    /// A completion handler called if the removal has successed
    public var successCompletionHandler: (() -> Void)? = nil

    /// A completion handler called if the has failed
    public var failCompletionHandler: (() -> Void)? = nil
    
    /// The header text
    public var headerText = "deleteUser.head".localized
    
    /// The subheader text
    public var subHeaderText:String {
        get {
            return (dedicatedPreFixLocalisationKey + ".deleteUser.body").localized
        }
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        buttonsContainer.updateSeparatorLine()
    }
    
    // skin dependent prefix for text resources (djingo or magenta)
    public var dedicatedPreFixLocalisationKey:String = "djingo"
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = "deleteUser.title".localized
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        SVKAnalytics.shared.startActivity(name: "myactivity_delete_user", with: nil)
        headLabel.text = headerText
        bodyLabel.text = subHeaderText
        
        confirmButton.setTitle("deleteUser.confirm".localized, for: .normal)
//        confirmButton.fillColor = SVKConversationAppearance.shared.hightlightedBtnColor
//        confirmButton.highlightedFillColor = SVKConversationAppearance.shared.hightlightedBtnColor
//        confirmButton.shapeColor = SVKConversationAppearance.shared.hightlightedBtnColor
        cancelButton.setTitle("deleteUser.cancel".localized, for: .normal)
       
        scrollViewLeading.constant = CGFloat( SVKAppearanceBox.shared.appearance.standardPageStyle.pageLeading)
        scrollViewTraling.constant = CGFloat( SVKAppearanceBox.shared.appearance.standardPageStyle.pageTrailing)
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true
        // TODO set the right icon
        iconImage.image = SVKAppearanceBox.shared.appearance.assets?.deleteAllPage
        buttonsContainer.updateSeparatorLine()
    }
    
    @IBAction func confirm(sender: Any?) {
        
        delegate?.delete { (success) in
            
            DispatchQueue.main.async {
                if !success {
                    SVKAnalytics.shared.log(event: "myactivity_delete_user_error")
                    DispatchQueue.main.safeAsync {
                        let toastData = SVKToastData(with: .default, message: "SVK.toast.deletion.error.message".localized)
                        
                        self.view.showToast(with: toastData)
                    }
                } else {
                    SVKAnalytics.shared.log(event: "myactivity_delete_user")
                    self.successCompletionHandler?()
                    
                    
                    if self.navigationController?.viewControllers.firstIndex(of: self) ?? 0 > 0 {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancel(sender: Any?) {
        if self.navigationController?.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}
