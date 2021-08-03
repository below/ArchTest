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

typealias SVKProcessingError = Error

struct SVKProcessorData {
    var data: Any?
}

/**
 A protocol defining a SVKProcessor.

 A process have some Input data, process it and return an Output data
 */
protocol SVKProcessor {
    
    associatedtype Input = SVKProcessorData
    associatedtype Output = SVKProcessorData
    
    /// The input of the processor
    var input: Input { set get }

    /**
     Process its input and return the result
     - returns: Some Output data
     */
    func process() -> Output
}

/**
 A processor that can produce a composition
 */
protocol CompositeOutputProsessor: SVKProcessor {
    associatedtype CompositeOutput
    /**
     Process its input and return the result as a composition of Output
     - returns: An array of Output
     */
    func process() -> CompositeOutput
}

///**
// A processor manager.
// 
// The processor manager links processor by pluging them.
// The manager sends each processor's ouput to the next processor and garbage the final result
// */
//struct ProcessorManager {
//
//    /**  creates a singleton */
//    public static let shared = ProcessorManager()
//    private init() {}
//
//    /**
//     Process a collection of processors
//     */
//    func aggragate<T: SVKProcessor>(processors: [T]) -> Any? {
//    
//        return processors.reduce(nil) { (output, processor) -> Any? in
//            return processor.process(input: output)
//        }
//    }
//}
//
