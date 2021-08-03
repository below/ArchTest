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

typealias DictionaryArray = SVKSSMLCompositeProcessor.Output
typealias StringArray = [SVKSSMLProcessor.Output]
typealias StringStatusArray = [(SVKSSMLProcessor.Output,Bool)]

extension String {
    /**
     Returns the String modified by a processor
     
     The string property is processed by an SVKSSMLProcessor and return to the caller.
     - parameter behaviour: The behaviour applied to the SVKSSMLProcessor
     - returns: The processed string or the original string if the processing has failed
    */
    func process(with behaviour: SVKSSMLProcessorBehaviour) -> SVKSSMLProcessor.Output {
        return SVKSSMLProcessor(input: self, behaviour: behaviour).process()
    }

    /**
     Splits the String using a SVKProcessor
     
     The string property is processed by an SVKSSMLProcessor
     - parameter behaviour: The behaviour applied to the SVKSSMLProcessor
     - returns: The processed text as an **SVKSSMLCompositeProcessor.Output**
     */
    func process(with behaviour: SVKSSMLProcessorBehaviour) -> SVKSSMLCompositeProcessor.Output  {
        return SVKSSMLCompositeProcessor(input: self, behaviour: behaviour).process()
    }

    func process(with behaviour: SVKSSMLProcessorBehaviour) -> SVKSSMLDividerAndGetTypeProcessor.Output  {
        return SVKSSMLDividerAndGetTypeProcessor(input: self, behaviour: behaviour).process()
    }
    /**
     Splits the String using a SVKProcessor
     
     The string property is processed by an SVKSSMLProcessor
     - parameter behaviour: The behaviour applied to the SVKSSMLProcessor
     - returns: The processed text as an **SVKSSMLCompositeProcessor.Output**
     */
    func process(with behaviour: SVKSSMLProcessorBehaviour) -> StringArray {
        return SVKSSMLDividerProcessor(input: self, behaviour: behaviour).process()
    }

}
