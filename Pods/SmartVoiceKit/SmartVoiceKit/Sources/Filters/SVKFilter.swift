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

public enum SVKFilterRange: Int, CaseIterable {
    case all
    case today
    case yesterday
    case last7days
    case thisMonth
    case lastMonth
}

public struct SVKFilter {
    public let range: SVKFilterRange
    public let device: SVKFilterDevice?
    
    public init(range: SVKFilterRange, device: SVKFilterDevice?) {
        self.range = range
        self.device = device
    }
}

public struct SVKFilterDevice {
    let name: String
    let serialNumber: String
}

public protocol SVKFilterDelegate {
    var filterValue:SVKFilter { get }
    
    func updateFilterValue(_ filterValue:SVKFilter)
    
    func getDeviceList(completionHandler: (([SVKFilterDevice]) -> Void)?)
    
    var isDevicesFeatureAvailable: Bool { get }

    func updateRangeFilter(value: SVKFilterRange)
    func updatePeriodFilter(value: SVKFilterDevice?)
}

public class SVKFilterHeaderView: UIView {
    
}

public class SVKFilterFullButton: SVKCustomButton {
    
}
