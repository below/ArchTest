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

class SVKAudioRecorderSegue: UIStoryboardSegue {
    
    static public let segueIdentifier = "SVKAudioRecorderSegue"
    
    override func perform() {
        guard let viewController = source as? SVKAudioRecorderViewController,
            let container = viewController.inputViewContainer,
            let inputView = self.destination.view,
            let inputController = self.destination as? SVKAudioInputViewController,
            let insets = (destination as? SVKInputViewProtocol)?.contentInsets else { return }
        
        inputController.isSoundEffectsEnabled = viewController.isSoundEffectsEnabled
        
        container.subviews.first?.removeFromSuperview()
        container.addSubview(inputView)
        viewController.addChild(self.destination)
        
        inputView.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leading)-[inputView]-(trailing)-|",
                                                                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                metrics: ["leading":insets.left, "trailing":insets.right],
                                                                views: ["inputView" : inputView]))
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[inputView]-(bottom)-|",
                                                                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                metrics: ["top":insets.top, "bottom":insets.bottom],
                                                                views: ["inputView" : inputView]))
    }
}
