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

extension UITableView {
    
    /**
     
     # Usage
     ```
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     if things.count == 0 {
     self.tableView.showEmptyState(withImage: UIImage(named: "illus_empty"), title: "no data", text: "ohh no")
     } else {
     self.tableView.hideEmptyState()
     }
     
     return things.count
     }
     ```
     */
    
    func showEmptyState(withImage image: UIImage?, title: String, text: String, fonts: (titleFont: UIFont, textFont: UIFont)) {
        let emptyState = SVKEmptyTableViewState()
        emptyState.imageView.image = image
        
        emptyState.titleLbl.text = title
        emptyState.descriptionLbl.text = text

        emptyState.titleLbl.font = fonts.titleFont
        emptyState.descriptionLbl.font = fonts.textFont
        self.backgroundView = emptyState
    }
    
    func hideEmptyState(withSeparatorStyle separatorStyle: UITableViewCell.SeparatorStyle = .singleLine) {
        self.backgroundView = nil
//        self.separatorStyle = separatorStyle
    }
}
