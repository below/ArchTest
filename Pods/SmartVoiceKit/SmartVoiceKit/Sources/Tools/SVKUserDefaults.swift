//
//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2021 Orange
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

class SVKUserDefaults {

    private static let uniqueIDKey = "unique-id"

    static func store(uniqueID: String) {
        UserDefaults.standard.setValue(uniqueID, forKey: uniqueIDKey)
        UserDefaults.standard.synchronize()
    }

   static func getUniqueID() -> String? {
        UserDefaults.standard.value(forKey: uniqueIDKey) as? String
    }
}
