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

public typealias SVKAnalyticsAttributes = [String: Any]

public protocol SVKAnalyticsDelegate {
    /**
     enable or disable analytics
     */
    var isAnalyticsEnabled: Bool { get set }
    /**
     events session logging
     */
    func log(session event: String, with attributes: SVKAnalyticsAttributes?)

    /**
     events logging
     */
    func log(event: String, with attributes: SVKAnalyticsAttributes?)

    /**
     activity logging
     */
    func startActivity(name: String, with attributes: SVKAnalyticsAttributes?)
    
    func stopCurrentActivity()

    /**
     send data
     */
    func sendData(_ data: SVKAnalyticsAttributes)
}

extension SVKAnalyticsDelegate {
    
    var isAnalyticsEnabled: Bool {
        get {
            return false;
        }
    }
    
    func log(session event: String, with attributes: SVKAnalyticsAttributes?) {}

    func log(event: String, with attributes: SVKAnalyticsAttributes?) {}

    func startActivity(name: String, with attributes: SVKAnalyticsAttributes?) {}
    
    func stopCurrentActivity() {}

    func sendData(_ data: SVKAnalyticsAttributes) {}
}

public class SVKAnalytics {

    // the delegate 
    private var delegate: SVKAnalyticsDelegate?

    public var isAnalyticsEnabled: Bool {
        get {
            guard  let delegate = delegate else {
                return false
            }
            return delegate.isAnalyticsEnabled
        }
        set(newValue) { delegate?.isAnalyticsEnabled = newValue }
    }

    // the singleton
    public static var shared: SVKAnalytics = {
        return SVKAnalytics()
    }()

    public static func configureWith(delegate: SVKAnalyticsDelegate) {
        let shared = SVKAnalytics.shared
        shared.delegate = delegate
    }

    private init() {
    }

    public func log(session event: String, with attributes: SVKAnalyticsAttributes? = nil) {
        delegate?.log(session: NSLocalizedString(event, comment: ""), with: attributes)
    }

    public func log(event: String, with attributes: SVKAnalyticsAttributes? = nil) {
        delegate?.log(event: NSLocalizedString(event, comment: ""), with: attributes)
    }

    public func startActivity(name: String, with attributes: SVKAnalyticsAttributes?) {
        delegate?.startActivity(name: NSLocalizedString(name, comment: ""), with: attributes)
    }

    public func stopCurrentActivity() {
        delegate?.stopCurrentActivity()
    }

    public func sendData(_ data: SVKAnalyticsAttributes) {
        delegate?.sendData(data)
    }
}
