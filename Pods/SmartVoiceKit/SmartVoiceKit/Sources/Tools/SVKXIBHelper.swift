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

import Foundation

public protocol XIBAble {
    associatedtype View where View: UIView
    static func load() -> View
}
public extension XIBAble {
    //static func load<T>(from type: T.Type, bundle: Bundle = Bundle.main) -> UIView where T: UIView {
    static func load() -> View {
        let name = String(describing: Self.self)
        let bundle = Bundle(for: Self.self as! AnyClass)
        return bundle.loadNibNamed(name, owner: nil, options: nil)?.first as! View
    }
}
