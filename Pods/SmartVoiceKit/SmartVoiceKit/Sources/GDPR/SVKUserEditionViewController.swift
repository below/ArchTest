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

import UIKit

class SVKUserEditionViewController: UITableViewController {

    var transientUser: SVKUserInfo?
    var editTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Account"

        self.tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Account informations"
    }

    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0 ... 6: return 76
        default: return 44
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.row > 1 {
            // TODO add logout delegate inside api user
//            AppDelegate.logout()
            self.dismiss(animated: true, completion: nil)
            return
        }
    }

    func editionCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserCell
        cell.textField.delegate = self
        cell.textField.tag = indexPath.row

        switch indexPath.row {
        case 0:
            cell.label.text = "User ID"
            cell.textField.text = transientUser?.id
            cell.textField.placeholder = "User ID"
        case 1:
            cell.label.text = "Language"
            cell.textField.text = transientUser?.locale
            cell.textField.placeholder = ""
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0...1:
            return editionCell(at: indexPath)
        default:
            return tableView.dequeueReusableCell(withIdentifier: "LogoutCell", for: indexPath)
        }
    }

    @IBAction func cancel(_: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

// MARK: UITextFieldDelegate

extension SVKUserEditionViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard textField.tag != 1 else { return false }
        editTextField = textField
        return true
    }

}

class UserCell: UITableViewCell {
    @IBOutlet var textField: UITextField!
    @IBOutlet var label: UILabel!
}
