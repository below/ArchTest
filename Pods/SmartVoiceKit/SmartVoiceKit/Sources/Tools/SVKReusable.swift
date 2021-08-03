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

//MARK: UITableview mixin
protocol SVKReusable: class {
    /// Returns the reuse identifier
    static var reuseIdentifier: String { get }
    /**
     Fill the reusable cell with some contents
     - parameter content: The content use to fill the reusable
     */
    func fill<T>(with content: T)
}

extension SVKReusable {
    static var reuseIdentifier: String {
        return String(reflecting: Self.self)
    }
}

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type = T.self, for indexPath: IndexPath) -> T where T: SVKReusable {
        return self.dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as! T
    }
}
