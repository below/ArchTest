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

/**
 A representation of feedback sent to the backend
 */
extension SVKFeedback {
    
    var localizationKey: String {
        return "feedback.\(rawValue)"
    }
}

protocol SVKFeedbackViewControllerDelegate {
    /**
     Informs the delegate that a feedback has been selected
     - parameter feedback: the feedback to send
     - parameter historyId: the id of the concerned entry
     - parameter completionHandle: A completionHandler called at the end of the feedback update request
     */
    func didSelect(_ feedback: SVKFeedback, for historyId: String,completionHandler: @escaping (_ success: Bool)->Void)
    
    /**
     Ask the delegate to authorize 
     - parameter completionHander: A completionHandler called at the end of
        the authorization resquest
     */
    func authorizeFeedback(completionHandler: @escaping (_ success: Bool)->Void)
}

class SVKFeedbackViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    static let showFeedbackViewSegueIdentifier = "showFeedbackView"

    @IBOutlet var subtitle: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var cancelButton: SVKCustomButton!
    @IBOutlet var validateButton: SVKCustomButton!
    @IBOutlet var thankyouView: UILabel!
    @IBOutlet var thankyouBottomConstraint: NSLayoutConstraint!
    @IBOutlet var titleView: UIView!
    @IBOutlet weak var buttonContainer: SVKStandardPageButtonView!
    
    private let data: [SVKFeedback] = [.speechUnderstoodWrongSkillInvoked, .speechMisunderstoodRightSkillInvoked,
                                      .speechMisunderstoofWrongSkillInvoked,.unintededActivation,.speechVocalisedWrongly]
    
    public var delegate: SVKFeedbackViewControllerDelegate?
    public var bubbleDescription: SVKBubbleDescription! {
            didSet {
                selectedRow = data.firstIndex(of: bubbleDescription.vote)
        }
    }
  
    private var selectedRow: Int? = nil
    var isDefaultNavigationBarHidden: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "feedback.title".localized
        subtitle.text = "feedback.subtitle".localized
        cancelButton.setTitle("feedback.cancel".localized, for: .normal)
        validateButton.setTitle("feedback.validate".localized, for: .normal)
        
        validateButton.fillColor = SVKConversationAppearance.shared.hightlightedBtnColor
        validateButton.highlightedFillColor = SVKConversationAppearance.shared.hightlightedBtnColor
        validateButton.shapeColor = SVKConversationAppearance.shared.hightlightedBtnColor
        
        tableView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        titleView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        
        tableView.tableFooterView = UIView()
        thankyouBottomConstraint.constant = -thankyouView.frame.height
        buttonContainer.updateSeparatorLine()
        if isDefaultNavigationBarHidden == nil {
            isDefaultNavigationBarHidden = (self.navigationController?.navigationBar.isHidden == true)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SVKAnalytics.shared.startActivity(name: "myactivity_feedback", with: nil)
        self.navigationItem.hidesBackButton = true
        if isDefaultNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if isDefaultNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    private func dismiss() {
        if #available(iOS 13.0, *){
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        SVKAnalytics.shared.log(event: "myactivity_item_feedback_cancel")
        self.dismiss()
    }
    
    @IBAction func validate(_ sender: Any) {
        var feedback = SVKFeedback.none
        
        if let selectedRow = selectedRow {
            feedback = data[selectedRow]
        }
        
        var event = "myactivity_item_feedback_none"
        
        switch feedback {
        case .speechUnderstoodWrongSkillInvoked:
            event = "myactivity_item_feedback_understood_wrong_response"
        case .speechMisunderstoodRightSkillInvoked:
            event = "myactivity_item_feedback_misunderstood_right_response"
        case .speechMisunderstoofWrongSkillInvoked:
            event = "myactivity_item_feedback_misunderstood_wrong_response"
        case .unintededActivation:
            event = "myactivity_item_feedback_unsolicited"
        case .speechVocalisedWrongly:
            event = "myactivity_item_feedback_wrong_vocalization"
        default:
            event = "myactivity_item_feedback_none"
        }
        SVKAnalytics.shared.log(event: event, with: nil)
        
        // send the feedback
        delegate?.didSelect(feedback, for: bubbleDescription.historyID!) { (success: Bool) in
            DispatchQueue.main.safeAsync {
                self.dismiss()
            }
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackCell", for: indexPath)
        let feedback = data[indexPath.row]
        cell.textLabel?.text = feedback.localizationKey.localized
        if let selectedRow = selectedRow, selectedRow == indexPath.row {
            
            cell.imageView?.image = SVKAppearanceBox.Assets.radioButtonOn
        } else {
            cell.imageView?.image = SVKAppearanceBox.Assets.radioButtonOff
        }
        cell.contentView.backgroundColor = SVKAppearanceBox
            .shared
            .appearance
            .tableStyle
            .cell
            .backgroundColor
            .color
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedRow = selectedRow, selectedRow == indexPath.row {
            self.selectedRow = nil
        } else {
            selectedRow = indexPath.row
        }
        tableView.reloadData()
    }
}
