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

struct SVKSSMLDividerProcessor: SVKProcessor {
    
    typealias Input = String
    typealias Output = [SVKSSMLProcessor.Output]
    
    /// The input text thats contains the SSML
    var input: String = ""
    
    /// processor behaviour
    var behaviour: SVKSSMLProcessorBehaviour
    
    init(input: Input, behaviour: SVKSSMLProcessorBehaviour) {
        self.input = input
        self.behaviour = behaviour
    }
    
    /**
     Process the input and divide it according to a behaviour
     
     - returns: An array of strings
     */
    func process() -> Output {

        switch behaviour {
        case .splitContent(_, let removePattern):
            /*
             This behaviour use a regex pattern to split the input into several strings.
             The pattern is not inserted into the array if removePattern is true
             */
            var result: [String] = []
            var start = input.startIndex
            while let range = input.range(of: behaviour.regexPattern, options: .regularExpression, range: start..<input.endIndex) {
                let newStr = String(input[start..<range.lowerBound])
                result.append(newStr)
                start = range.lowerBound < range.upperBound ? range.upperBound : input.index(range.lowerBound, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
                if (!removePattern && range.lowerBound < range.upperBound) {
                    result.append(String(input[range.lowerBound..<range.upperBound]))
                }
            }
            let newStr = String(input[start..<input.endIndex])
            if (!newStr.isEmpty){
                result.append(newStr)
            }
            return result
            
        case .paragraphs:
            return input.components(matching: behaviour.regexPattern)
            
        case .sentence:
            return input.components(matching: behaviour.regexPattern).compactMap {
                    return SVKSSMLProcessor(input: $0, behaviour: .displayableContent).process()
                }
            
        default:
            return Output()
        }
    }
}
