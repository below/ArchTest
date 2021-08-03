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

public enum SVKLoggerLevel: String, CustomStringConvertible {
    case debug
    case info
    case warn
    case error
    case fatal

    public init?(string: String) {
        self.init(rawValue: string.lowercased())
    }

    public var description: String {
        return rawValue.uppercased()
    }

    public var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warn: return 2
        case .error: return 3
        case .fatal: return 4
        }
    }
}

public protocol SVKLoggerDelegate: class {
    func log(event: SVKLoggerEvent)
}

/**
 A PrettyLogger event
 */
public struct SVKLoggerEvent {

    ///The log level of the event
    public let level: SVKLoggerLevel

    /// The message to be logged
    public let message: String

    /// The name of the class being logged
    public let className: String

    /// The function from where the event comes from
    public let function: String

    /// The file name of the source code
    public let file: String

    /// The line where the event comes from in the source file
    public let line: Int

}

public class SVKLogger {

    /// The proxy logger delegate
    public static var delegate: SVKLoggerDelegate?

    /// The logger Level. Default is .info
    public static var level: SVKLoggerLevel = .info

    private init() {}
    
    /**
     Log a message
     
     - parameter level: The log level for the message
     - parameter message: The message to log
     - parameter function: The function to log
     - parameter file: The function's source file
     - parameter line: The line of the log in the source file
     */
    private static func log(_  level: SVKLoggerLevel = .error,message: String, function: String = #function,
                     file: String = #file, line: Int = #line) {

        guard SVKLogger.level.priority <= level.priority else {
            return
        }
        
        let logEvent = SVKLoggerEvent(level: level, message: message, className: file.lastWord, function: function, file: file, line: line)
        SVKLogger.delegate?.log(event: logEvent)
    }

    /**
     Log a debugging message
    
     The log level is .debug
     - parameter message: The message to log
     */
    public static func debug(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if DEBUG
        log(.debug, message: message, function: function, file: file, line: line)
        #endif
    }

    /**
     Log an information message
     
     The log level is .info
     - parameter message: The message to log
     */
    @objc
    public static func info(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        log(.info, message: message, function: function, file: file, line: line)
    }

    /**
     Log a warning message
     
     The log level is .warn
     - parameter message: The message to log
     */
    @objc
    public static func warn(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        log(.warn, message: message, function: function, file: file, line: line)
    }

    /**
     Log an error message
     
     The log level is .error
     - parameter message: The message to log
     */
    @objc
    public static func error(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        log(.error, message: message, function: function, file: file, line: line)
    }

    /**
     Log a fatal message
     
     The log level is .fatal
     - parameter message: The message to log
     */
    @objc
    public static func fatal(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        log(.fatal, message: message, function: function, file: file, line: line)
    }
}

//extension SVKLogger: SVKLoggerDelegate {
//
//    public func log(event: SVKPLoggerEvent) {
//        let source = event.level == .debug ? "\(event.className).\(event.function):\(event.line): " : ""
//        let formattedMessage = "[\(event.level)] \(source)\(event.message) "
//        NSLog(formattedMessage)
//    }
//}
public extension String{
    var lastWord: String {
        guard !self.isEmpty else {
            return ""
        }
        var constructedURL = URL(fileURLWithPath: self)
        constructedURL.deletePathExtension()
        return constructedURL.lastPathComponent
    }
}
