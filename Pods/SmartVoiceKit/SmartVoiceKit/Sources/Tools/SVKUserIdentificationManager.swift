//
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

public class SVKUserIdentificationManager {
    private init() {}
    
    public static let shared = SVKUserIdentificationManager()
    
    private var serialNumberInternal: String = "i-SVK-000000000000000"
    
    public var serialNumber: String{
        get {
            return serialNumberInternal
        }
    }
    
    /// Return the unique id which is used for tracking purpose
    public var uniqueID: String {
        get {
            getUniqueID()
        }
    }

    /// Stores unique id from host app
    private var _uniqueID: String?

    private(set) var deviceName : String? = nil
    
    public func configureWith(serialNumberPrefix: String? = nil,uniqueDeviceId: String? = nil,deviceName: String? = nil) {
        
        self.deviceName = deviceName
        var serialNumber = "i-SVK-"
        
        if let serialNumberPrefix = serialNumberPrefix, !serialNumberPrefix.isEmpty {
            serialNumber += serialNumberPrefix + "-"
        }
        
        if let uniqueDeviceId = uniqueDeviceId, !uniqueDeviceId.isEmpty {
            serialNumber += uniqueDeviceId
        } else if let uniqueDeviceId = UIDevice.current.identifierForVendor?.uuidString {
            serialNumber += uniqueDeviceId
        } else {
            SVKLogger.fatal("ConfigureWith uniqueDeviceId can't be set")
            serialNumber += "00000000-0000-0000-0000-000000000000"
        }

        serialNumberInternal = serialNumber
    }

    /// Generates unique id using the device uuidString
    /// - Returns: UUIDString
    private func generateUniqueID() -> String {
        if let uniqueDeviceId = UIDevice.current.identifierForVendor?.uuidString {
            SVKUserDefaults.store(uniqueID: uniqueDeviceId)
            return uniqueDeviceId
        } else {
            SVKLogger.fatal("ConfigureWith uniqueDeviceId can't be set")
            let defaultID = "i-SVK-000000000000000"
            SVKUserDefaults.store(uniqueID: defaultID)
            return defaultID
        }
    }

    /// Sets the unique id provided by host app
    /// - Parameter uniqueID: This should be unique between the sessions
    public func set(uniqueID: String) {
        _uniqueID = uniqueID
    }

    /// returns unique id provided by host app otherwise SVK generate new one and store it.
    ///  same unique id is used for all the session.
    /// - Returns: Unique id
    private func getUniqueID() -> String {
        if let id = _uniqueID {
            return id
        } else if let id = SVKUserDefaults.getUniqueID() {
            return id
        } else {
           return generateUniqueID()
        }
    }
}

