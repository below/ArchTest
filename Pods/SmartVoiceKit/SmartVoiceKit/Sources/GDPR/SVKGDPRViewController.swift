//
// Software Name: Smart Voice Kit - SVPocket
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
// Module description: A sample code to use the SDK in a test app
// named SVPocket.
//

import Foundation
import UIKit
import AudioToolbox

public enum SVKGDPRContentDisplayed {
    case all
    case agreements
    case deleteInteractions
}
public protocol SVKGDPRProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Load messages from the history
    func getUserAgreements( completionHandler: @escaping (SVKUserAgreements?) -> Void)
    
    func update(tncAgreement: SVKTNCAgreement, completionHandler: @escaping (Bool) -> Void)
}

public extension SVKGDPRProtocol {
    
    func getUserAgreements( completionHandler: @escaping (SVKUserAgreements?) -> Void) {
        getUserAgreementsInternal(retry: true, completionHandler: completionHandler)
    }
 
    private func getUserAgreementsInternal( retry:Bool, completionHandler: @escaping (SVKUserAgreements?) -> Void) {
        SVKAPIUserAgreementsRequest().perform { result in
            switch result {
            case .success(_, let agreements as SVKUserAgreements):
                completionHandler(agreements)
            case .success(let code, _):
                SVKLogger.debug("SVKAPIUserAgreementsRequest terminated with code: \(code)")
                if retry {
                    getUserAgreementsInternal(retry: false, completionHandler: completionHandler)
                }
            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            getUserAgreementsInternal(retry: false, completionHandler: completionHandler)
                        } else {
                            completionHandler(nil)
                        }
                    }
                }
                completionHandler(nil)
            }
        }
        
    }
    
    func update(tncAgreement: SVKTNCAgreement, completionHandler: @escaping (Bool) -> Void) {
        updateInternal(retry: true, tncAgreement: tncAgreement, completionHandler: completionHandler)
    }
    
    private func updateInternal(retry:Bool, tncAgreement: SVKTNCAgreement, completionHandler: @escaping (Bool) -> Void) {
        if SVKTNCId(rawValue: tncAgreement.tncId) == .listenVoice {
            SVKAnalytics.shared.log(event: tncAgreement.agreed ? "myactivity_agreement_LISTENVOICE_on" : "myactivity_agreement_LISTENVOICE_off")
        }
        SVKAPIUserAgreementsRequest(method: .post([tncAgreement])).perform { result in
            switch result {
            case .success(_, _):
                completionHandler(true)
                break
            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            updateInternal(retry: false, tncAgreement: tncAgreement, completionHandler: completionHandler)
                        } else {
                            completionHandler(false)
                        }
                    }
                }
                completionHandler(false)
            }
        }
    }
    
}

public class SVKGDPRViewController: UITableViewController  {
    
    var aggrementList: [SVKGDPRSwitchModel] = []
    
    var expandList: [String] = []
    
    var isShowOnlyDeviceHistory: Bool = false
    
    var conversationDelegate: SVKConversationProtocol?
    
    var userDelegate: SVKUserProtocol?
    
    var gdprDelegate: SVKGDPRProtocol?
    
    var dedicatedPreFixLocalisationKey: String = ""
    
    var useNavigation: Bool = true
    
    var contentDisplayed: SVKGDPRContentDisplayed = .all
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = .none
        let nib = UINib(nibName: "SVKGDPRSectionHeader", bundle: SVKBundle)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "SVKGDPRSectionIdentifier")
        tableView.sectionFooterHeight = 0.0;
    }
    
    public func configureWith(gdprDelegate: SVKGDPRProtocol, conversationDelegate: SVKConversationProtocol?, userDelegate: SVKUserProtocol?, isShowOnlyDeviceHistory: Bool = false,dedicatedPreFixLocalisationKey: String, useNavigation: Bool = true, contentDisplayed: SVKGDPRContentDisplayed = .all) {
        self.gdprDelegate = gdprDelegate
        self.conversationDelegate = conversationDelegate
        self.userDelegate = userDelegate
        self.isShowOnlyDeviceHistory = isShowOnlyDeviceHistory
        self.dedicatedPreFixLocalisationKey = dedicatedPreFixLocalisationKey
        self.useNavigation = useNavigation
        if self.useNavigation {
            navigationItem.title = ("SVK." + dedicatedPreFixLocalisationKey + ".GDPR.title").localized
        }
        self.contentDisplayed = contentDisplayed
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.useNavigation {
            navigationItem.title = ("SVK." + dedicatedPreFixLocalisationKey + ".GDPR.title").localized
        }
        self.tableView.tableFooterView = UIView()
        if [SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.agreements].contains(self.contentDisplayed) {
            self.gdprDelegate?.getUserAgreements() { (userAgreements) in
                if let userAgreements = userAgreements {
                    DispatchQueue.main.async {
                        var localAggrementList: [SVKGDPRSwitchModel] = []
                        for agreement in userAgreements.elements.filter({ (agreement) -> Bool in
                            SVKContext.consentPageRaw.contains(agreement.tncId)
                        }){
                            let tncTexts = agreement.tncTexts
                            let tncText = tncTexts.first
                            if let tncText = tncText {
                                let dataSwitch = SVKGDPRSwitchModel(label: tncText.displayName, value: agreement.userAgreement ?? false, id: agreement.tncId, description: tncText.text, isCollapsed: !self.expandList.contains(agreement.tncId))
                                localAggrementList.append(dataSwitch)
                            }
                        }
                        if self.aggrementList.isEmpty {
                            self.aggrementList.append(contentsOf: localAggrementList)
                        } else {
                            localAggrementList.forEach { (localAgg) in
                                if let index = self.aggrementList.firstIndex(where: { (agg) -> Bool in
                                    agg.id == localAgg.id
                                }) {
                                    var agg = self.aggrementList[index]
                                    agg.value = localAgg.value
                                    self.aggrementList[index] = agg
                                }
                            }
                        }
                        self.tableView.reloadData()
                    }
                } else {
                    DispatchQueue.main.safeAsync {
                        let offset = Float(self.tabBarController == nil ? 0.0 : 48)
                        
                        let toastData = SVKToastData(with: .default, message: "SVK.toast.consent.error.message".localized, offset: offset)
                        
                        self.parent?.view.showToast(with: toastData)

                    }

                }
            }
        }
    }
    
    public override func numberOfSections(in _: UITableView) -> Int {
        return 2
    }
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return [SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.agreements].contains(self.contentDisplayed) ? aggrementList.count : 0
        case 1:
            return [SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.deleteInteractions].contains(self.contentDisplayed) ? 2 : 0
        default:
            return 0
        }
//        aggrementList.count + 2
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if let dataSwitch = self.tableView.dequeueReusableCell(withIdentifier: "SVKGDPRSwitchCell", for: indexPath) as? SVKGDPRSwitchCell {
                dataSwitch.data = aggrementList[indexPath.row]
                dataSwitch.delegate = self
                DispatchQueue.main.async {
                    dataSwitch.setNeedsLayout()
                }
                return dataSwitch
            }
        case 1:
            if indexPath.row == 0 {
                if let dataButton = self.tableView.dequeueReusableCell(withIdentifier: "SVKGDPRButtonCell", for: indexPath) as? SVKGDPRButtonCell {
                    dataButton.data = SVKGDPRButtonModel( button: "SVK.GDPR.deleteHistory.button".localized, id: "DeleteHistory")
                    dataButton.delegate = self
                    return dataButton
                }
            }
            if indexPath.row ==  1 {
                if let dataButton = self.tableView.dequeueReusableCell(withIdentifier: "SVKGDPRButtonCell", for: indexPath) as? SVKGDPRButtonCell {
                    dataButton.data = SVKGDPRButtonModel( button: "SVK.GDPR.deleteUser.button".localized, id: "DeleteUser")
                    dataButton.delegate = self
                    return dataButton
                }
            }
            
        default:
            return UITableViewCell()
        }
        return UITableViewCell()
    }

    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 0:
            if ![SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.agreements].contains(self.contentDisplayed) {
                return nil
            }
        default:
            if ![SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.deleteInteractions].contains(self.contentDisplayed) {
                return nil
            }
        }
        let header = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "SVKGDPRSectionIdentifier") as! SVKGDPRSectionHeader
        let title = section == 0 ? "SVK.GDPR.tncAgrements.title".localized :"SVK.GDPR.datas.title".localized
        header.fill(with: title)
        return header
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            if ![SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.agreements].contains(self.contentDisplayed) {
                return 0
            }
        default:
            if ![SVKGDPRContentDisplayed.all,SVKGDPRContentDisplayed.deleteInteractions].contains(self.contentDisplayed) {
                return 0
            }
        }
        return 50.0
    }
}

extension SVKGDPRViewController: SVKGDPRSwitchModelDelegate {
    public func switchAction(_ for: SVKGDPRSwitchModel) {
        
        let tncAgreement = SVKTNCAgreement(agreed: `for`.value, tncId: `for`.id)
        self.gdprDelegate?.update(tncAgreement: tncAgreement) { (success) in
            if !success {
                DispatchQueue.main.async {
                    let offset = Float(self.tabBarController == nil ? 0.0 : 48)
                    let toastData = SVKToastData(with: .default, message: "SVK.toast.consent.error.message".localized, offset: offset)
                    self.parent?.view.showToast(with: toastData)
                }
            }
        }
     }
    
    public func switchCollapseExpand(_ for: SVKGDPRSwitchModel?) {
        if let switchModel = `for`, let index = aggrementList.firstIndex(where: { (model) -> Bool in
            model.id == switchModel.id
        }) {
            var model = aggrementList[index]
            model.isCollapsed = !model.isCollapsed
            if model.isCollapsed {
                if let indexExpand = expandList.firstIndex(where: { (key) -> Bool in
                    key == switchModel.id
                }) {
                    expandList.remove(at: indexExpand)
                }
            } else {
                expandList.append(switchModel.id)
            }
            aggrementList[index] = model
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .none, animated: true)
        }
    }
}

extension SVKGDPRViewController: SVKGDPRButtonModelDelegate {
  
    public func tapAction(_ for: SVKGDPRButtonModel) {
        if `for`.id == "DeleteHistory" {
            let storyboard = UIStoryboard(name: "SVKConversationStoryboard", bundle: SVKBundle)
            if let confirmViewController = storyboard.instantiateViewController(withIdentifier: "SVKDeleteHistoryViewController") as? SVKDeleteHistoryViewController {
                confirmViewController.showOnlyDeviceHistory = self.isShowOnlyDeviceHistory
                confirmViewController.delegate = self.conversationDelegate
                confirmViewController.successCompletionHandler = {
                    var notification = Notification(name: SVKKitNotificationConfigurationChanged)
                    notification.userInfo = ["deleteHistoryAll": true]
                    // DispatchQueue is used because of simultanemous access crash
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(notification)
                        self.tabBarController?.selectedIndex = 0
                    }
                }
                confirmViewController.failCompletionHandler = {  }

                confirmViewController.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(confirmViewController, animated: true)
            }
        }
        if `for`.id == "DeleteUser" {
            let storyboard = UIStoryboard(name: "SVKConversationStoryboard", bundle: SVKBundle)
            if let confirmViewController = storyboard.instantiateViewController(withIdentifier: "SVKDeleteUserViewController") as? SVKDeleteUserViewController {
                confirmViewController.dedicatedPreFixLocalisationKey = dedicatedPreFixLocalisationKey
                confirmViewController.delegate = self.userDelegate
                confirmViewController.successCompletionHandler = {
                    var notification = Notification(name: SVKKitNotificationConfigurationChanged)
                    notification.userInfo = ["deleteUser": true]
                    // DispatchQueue is used because of simultanemous access crash
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(notification)
                        if self.navigationController?.viewControllers.firstIndex(of: self) ?? 0 > 0 {
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        }
                        let mainStoryboard = UIStoryboard(name: "Settings", bundle: nil)
                        
                        if let userViewController = mainStoryboard.instantiateViewController(withIdentifier: "UserEditionViewController") as? SVKUserEditionViewController {
                            userViewController.modalPresentationStyle = .fullScreen
                            let parent = self.navigationController?.parent
                            parent?.present(UINavigationController(rootViewController: userViewController),
                                        animated: true, completion: {
                                            // TODO validate the deleted code
//                                            userViewController.edit("")
                                }
                             )
                        }
                        
                    }
                }
                confirmViewController.failCompletionHandler = {  }

                confirmViewController.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(confirmViewController, animated: true)
            }
        }
    }
    
}
