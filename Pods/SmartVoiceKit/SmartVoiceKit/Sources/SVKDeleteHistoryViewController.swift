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

public class SVKDeleteHistoryViewController: UIViewController {

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var headLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    
    @IBOutlet var cancelButton: SVKCustomButton!
    @IBOutlet var confirmButton: SVKCustomButton!
    @IBOutlet var buttonsContainer: SVKStandardPageButtonView!
    @IBOutlet weak var titleHeader: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackTopConstraint: NSLayoutConstraint!
    
    /// The history protocol delegate
    public var delegate: SVKDeleteHistoryProtocol?
    
    /// A completion handler called if the removal has successed
    public var successCompletionHandler: (() -> Void)? = nil

    /// A completion handler called if the has failed
    public var failCompletionHandler: (() -> Void)? = nil
    
    /// The header text
    public var headerText = "deleteHistory.head".localized
    
    /// The subheader text
    public var subHeaderText = "deleteHistory.body".localized
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = "deleteHistory.title".localized
    }

    public var showOnlyDeviceHistory: Bool = false
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        buttonsContainer.updateSeparatorLine()
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        headLabel.text = headerText
        bodyLabel.text = subHeaderText
        
        confirmButton.setTitle("deleteHistory.confirm".localized, for: .normal)
        cancelButton.setTitle("deleteHistory.cancel".localized, for: .normal)
        setTitleHeader()
    }
    
    public func setTitleHeader() {
        if navigationController == nil {
            if #available(iOS 11.0, *) {
                let topArea = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
                headerHeightConstraint.constant = SVKConstant.HeaderHeight.defaultHeight + topArea
            } else {
                headerHeightConstraint.constant = SVKConstant.HeaderHeight.heightWithSafeArea
            }
            titleLabel.text = "deleteHistory.title".localized
            titleHeader.backgroundColor = SVKConversationAppearance.shared.tintColor
        } else {
            title = "deleteHistory.title".localized
            headerHeightConstraint.constant = 0
            titleLabel.text = ""
            stackTopConstraint.constant = stackTopConstraint.constant + SVKConstant.HeaderHeight.heightWithSafeArea
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true
        iconImage.image = SVKAppearanceBox.shared.appearance.assets?.deleteAllPage
        buttonsContainer.updateSeparatorLine()
    }
        
    @IBAction func confirm(sender: Any?) {
        
        SVKAnalytics.shared.startActivity(name: "myactivity_delete_all", with: nil)
        let serialNumber = self.showOnlyDeviceHistory ? SVKUserIdentificationManager.shared.serialNumber : nil
        delegate?.deleteAllHistoryEntries(serialNumber: serialNumber) { (success) in
            
            DispatchQueue.main.async {
                if !success {
                    SVKAnalytics.shared.log(event: "myactivity_delete_all_error")
                    
                    DispatchQueue.main.safeAsync {
                        let toastData = SVKToastData(with: .default, message: "SVK.toast.deletion.error.message".localized)
                        
                        self.view.showToast(with: toastData)
                    }
                } else {
                    SVKAnalytics.shared.log(event: "myactivity_delete_all")
                    self.successCompletionHandler?()
                    
                    if self.navigationController?.viewControllers.firstIndex(of: self) ?? 0 > 0 {
                        self.navigationController?.popViewController(animated: true)
                    } else if self.navigationController != nil {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancel(sender: Any?) {
        if self.navigationController?.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            self.navigationController?.popViewController(animated: true)
        } else if self.navigationController != nil {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
