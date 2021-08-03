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

struct SVKSSMLCompositeProcessor: SVKProcessor {
    
    typealias Input = String
    typealias Output = [String:SVKSSMLProcessor.Output]
    
    /// The input text thats contains the SSML
    var input: String = ""
    
    /// processor behaviour
    var behaviour: SVKSSMLProcessorBehaviour

    init(input: Input, behaviour: SVKSSMLProcessorBehaviour) {
        self.input = input
        self.behaviour = behaviour
    }

    /**
     Parse a text, and clear it from any speak tags
     - returns: the result of the process of the input text
     */
    func process() -> Output {
        
        switch behaviour {
        case .imageAttributesAndCaptions(let bindingKeys):
            return input.components(matching: behaviour.regexPattern, bindTo: bindingKeys)
        default:
            return Output()
        }
    }
}
