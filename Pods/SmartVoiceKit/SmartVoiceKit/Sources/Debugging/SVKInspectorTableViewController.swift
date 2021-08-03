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

class SVKInspectorTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var titleHeader: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnCancel: UIButton!
    
    public var bubbleDescription: SVKAssistantBubbleDescription?
    public var bubblesView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Developer Mode"
        tableView.estimatedRowHeight = 62
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        setTitleHeader()
    }
    
    public func setTitleHeader() {
        if #available(iOS 11.0, *) {
            let topArea = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
            headerHeightConstraint.constant = SVKConstant.HeaderHeight.defaultHeight + topArea
        } else {
            headerHeightConstraint.constant = SVKConstant.HeaderHeight.heightWithSafeArea
        }
        titleHeader.backgroundColor = SVKConversationAppearance.shared.tintColor
        btnCancel.setTitle("navigationBar.menu.cancel".localized, for: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backCancelClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    // MARK: - Table view data source

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorMessageTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorMessageTableViewCell
            cell.stackView.addArrangedSubview(bubblesView)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorFieldTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorFieldTableViewCell
            cell.textLabel?.text = "Skill"
            if let skillId = bubbleDescription?.invokeResult?.skill?.id {
                cell.detailTextLabel?.text = skillId
            } else if let skillId = bubbleDescription?.historyEntry?.request?.skillId {
                cell.detailTextLabel?.text = skillId
            } else {
                cell.detailTextLabel?.text = "N/A"
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorFieldTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorFieldTableViewCell
            cell.textLabel?.text = "Intent"
            cell.detailTextLabel?.text = bubbleDescription?.invokeResult?.intent?.intent ?? "N/A"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorFieldTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorFieldTableViewCell
            cell.textLabel?.text = "Answer type"
            cell.detailTextLabel?.text = bubbleDescription?.invokeResult?.skill?.resultType.rawValue ?? "N/A"
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorJSONTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorJSONTableViewCell
            cell.titleLabel?.text = "Json code"
            cell.codeLabel.textColor = SVKConversationAppearance.shared.tintColor
            if let data = bubbleDescription?.invokeResult?.jsonData,
                let json = String(data: data, encoding: .utf8) {
                cell.codeLabel.text = json.prettyJSON
            } else if let data = bubbleDescription?.historyEntryJSONData,
                let json = String(data: data, encoding: .utf8) {
                cell.codeLabel.text = json.prettyJSON
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: SVKInspectorJSONTableViewCell.reuseIdentifier, for: indexPath) as! SVKInspectorJSONTableViewCell
            cell.titleLabel?.text = "Json card's code"
            if let data = bubbleDescription?.card?.jsonData,
                let json = String(data: data, encoding: .utf8) {
                cell.codeLabel.text = json.prettyJSON
            }
            return cell
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.row == 0 {
            return bubblesView.frame.height + 30
        } else if indexPath.row == 4 || indexPath.row == 5 {
            return UITableView.automaticDimension
        } else {
            return 62
        }
} }

class SVKInspectorMessageTableViewCell: UITableViewCell {
    @IBOutlet var stackView: UIStackView!
    static let reuseIdentifier = "MessageCell"
}

class SVKInspectorFieldTableViewCell: UITableViewCell {
    static let reuseIdentifier = "FieldCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        detailTextLabel?.textColor = SVKConversationAppearance.shared.tintColor
    }
}

class SVKInspectorJSONTableViewCell: UITableViewCell {
    static let reuseIdentifier = "JSONCell"
    @IBOutlet var codeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    
    @IBAction func copyJson(_: Any) {
        if let text = codeLabel.text {
            UIPasteboard.general.string = text
        }
    }
}

extension String {
    struct FormatState {
        var tab = 0
        var tabs: String {
            var s = ""
            for _ in 0 ..< tab {
                s.append("\t")
            }
            return s
        }
    }

    public var prettyJSON: String {
        var prettyJSON = ""
        var states = [FormatState()]
        var level = 0
        var previousCharacter = Character(" ")
        var isNewline = false

        for c in self {
            if "{[".contains(c) {
                if previousCharacter != ":" {
                    prettyJSON.append(states[level].tabs)
                }
                prettyJSON.append(c)
                prettyJSON.append("\n")
                previousCharacter = c
                isNewline = true
                level += 1
                states.append(FormatState(tab: level))
            } else if "}]".contains(c) {
                level = max(0, level - 1)
                prettyJSON.append("\n")
                prettyJSON.append(states[level].tabs)
                prettyJSON.append(c)
                previousCharacter = c
                isNewline = true
                states.removeLast()
            } else if c == "\n" {
                prettyJSON.append(c)
                previousCharacter = c
                isNewline = true
            } else if c == "," {
                prettyJSON.append(c)
                prettyJSON.append("\n")
                previousCharacter = c
                isNewline = true
            } else {

                if isNewline {
                    prettyJSON.append(states[level].tabs)
                    isNewline = false
                }

                prettyJSON.append(c)
                previousCharacter = c
                if c == ":" {
                    prettyJSON.append(" ")
                }
            }
        }
        return prettyJSON
    }
}

extension SVKAssistantBubbleDescription {
    var historyEntryJSONData: Data? {
        guard let entry = historyEntry else { return nil }
        do {
            return try JSONEncoder().encode(entry)
        } catch {
            
        }
        return nil
    }
}


