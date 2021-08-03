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
import UIKit

public struct SVKTools {
    
    static var locale = Locale.current {
        didSet {
            iso8061DateFormatter.locale = locale
            assistantTimeFormatter.locale = locale
            assistantDayFormatter.locale = locale
            assistantDayCurrentYearFormatter.locale = locale
            assistantWeekFormatter.locale = locale
        }
    }
    
    /**
     Returns the Localize a string associated to key

     # Important
     The function first, looks in the main bundle. If none key or table is found it looks in the framework bundle.

     - parameter key: The key of the string in the table
     - parameter tableName: The name of the table in wich the function may lookup. Default is "Localizable.strings"
     - returns: The value of key

     */
    public static func localizedString(_ key: String, tableName: String = "Localizable", bundle: Bundle? = nil) -> String {
        let mainBundleLocalizedString = NSLocalizedString(key, tableName: tableName, comment: "")
        if let bundle = bundle, mainBundleLocalizedString == key {
            let frameworkLocalizedString = NSLocalizedString(key, tableName: tableName, bundle: bundle, value: "", comment: "")
            return frameworkLocalizedString
        }
        return mainBundleLocalizedString
    }
    /**
     Laods an image from 1st the mainBundle, 2nd SVKBundle
     */
    static func imageWithName(_ name: String) -> UIImage? {
        guard !name.isEmpty  else {
            return nil
        }
        if let image = UIImage(named: name) {
            return image
        }
        else if let image = UIImage(named: name, in: SVKBundle, compatibleWith: nil) {
            return image
        }
        return nil
    }

    static func image(with view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    /**
     Returns the path of a resource.
     
     First, looks in the main bundle the in th bundle passed in parameter.
     
     - parameter name: The name of the resource to look for
     - parameter type: The type of the resource
     - parameter bundle: The Bundle in which look for the resource if not found in the main bundle
     - returns: The path of the resource.
     */
    static func path(forResource name: String, ofType type:String? = nil, in bundle: Bundle? = nil) -> String? {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            return bundle?.path(forResource: name, ofType: type)
        }
        return path
    }
    
    public static var iso8061DateFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()

    public static var iso8061ShortDateFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()

    public static var iso8061GMTDateFormatter: Foundation.ISO8601DateFormatter = {
        let formatter = Foundation.ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    
    static var assistantDayFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "dd. MMM yyyy"
        return formatter
    }()

    static var assistantDayCurrentYearFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "dd. MMMM"
        return formatter
    }()

    static var assistantTimeFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static var assistantWeekFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static func formattedDateTime(from iso8061Date: String, ommitTodayTime: Bool = false) -> String {
        if let date = date(from: iso8061Date) {
            let time = assistantTimeFormatter.string(from: date)
            let day = getRelativeFormattedDate(from: date)
            return (date.isToday() && ommitTodayTime) ? day :"\(day) \(time)"
        }
        return ""
    }

    static func formattedDate(from iso8061Date: String) -> String {
        if let date = date(from: iso8061Date) {
            return getRelativeFormattedDate(from: date)
        }
        return ""
    }

    private static func getRelativeFormattedDate(from date: Date) -> String {
        if date.isToday() {
            return "Filters.enum.today".localized
        } else if date.isPreviousDay() {
            return "Filters.enum.yesterday".localized
        } else if date.isSameWeek() {
            return assistantWeekFormatter.string(from: date)
        } else if date.isCurrentYear() {
            return assistantDayCurrentYearFormatter.string(from: date)
        } else {
            return assistantDayFormatter.string(from: date)
        }
    }
    
    static func date(from iso8061Date: String) -> Date? {
        if let date = iso8061DateFormatter.date(from: iso8061Date, timezoneIdentifier: "UTC") {
            return date
        } else if let date = iso8061ShortDateFormatter.date(from: iso8061Date, timezoneIdentifier: "UTC") {
            return date
        } else if let date = iso8061GMTDateFormatter.date(from: iso8061Date) {
            return date
        }
        let pattern = "(\\.[0-9]+)"
        let ranges = iso8061Date.rangesOf(matching: pattern)
        if ranges.count == 1, let fractional = Double("0" + String(iso8061Date[ranges[0].lowerBound..<ranges[0].upperBound])) {
            var shortDate = iso8061Date
            shortDate.removeSubrange(ranges[0].lowerBound..<ranges[0].upperBound)
            if let date = iso8061GMTDateFormatter.date(from: shortDate) {
                let t = TimeInterval(fractional)
                let dateResponse = date.addingTimeInterval(t)
                return dateResponse
            }
        }
        return nil
    }

    /// Format a duration to 00:00:00
    static func timerString(from duration: Int?) -> String {
        guard let duration = duration else { return "00:00:00" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = ((duration % 3600) % 60) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /**
     Returns a cover for a given media
     - parameter url: the cover string url
     - returns: A Data object representing the cover of the media
     */
    static public func fetchMediaImage(at url: String?, completionHandler: @escaping (Data?) -> Void) {
        if let url = url, let URL = Foundation.URL(string: "\(url)?size=medium") {
            URLSession.shared.dataTask(with: URL) { data, _, _ in
                completionHandler(data)
                }.resume()
        }
    }
    
    /**
     Returns a url from <bimg *>, <img *> tag
     - parameter with: the string representing the tag
     - returns: the url of the ressource http
     */
    static public func url(with imgTag: String) -> String? {
        var startIndex = imgTag.range(of: "<bimg=\"", options: String.CompareOptions.caseInsensitive)?.upperBound
        if startIndex == nil {
            startIndex = imgTag.range(of: "<img=\"", options: String.CompareOptions.caseInsensitive)?.upperBound
        }
        if startIndex == nil {
            startIndex = imgTag.range(of: "<bimg src=\"", options: String.CompareOptions.caseInsensitive)?.upperBound
        }
        if startIndex == nil {
            startIndex = imgTag.range(of: "<img src=\"", options: String.CompareOptions.caseInsensitive)?.upperBound
        }
        if let startIndex = startIndex {
            let endIndex = imgTag.range(of: "\"", options: String.CompareOptions.caseInsensitive,range: startIndex..<imgTag.endIndex)?.lowerBound
            if let endIndex = endIndex {
                return String(imgTag[startIndex..<endIndex])
            }
        }
        return nil
    }
}

extension Date {
    func isToday() -> Bool {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return components == todayComponents
    }
    
    func inSameDayAs(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isCurrentYear() -> Bool {
        let todayComponents = Calendar.current.dateComponents([.year], from: Date())
        let components = Calendar.current.dateComponents([.year], from: self)
        return components == todayComponents
    }

    func isPreviousDay() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInYesterday(self)
    }

    func isSameWeek() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

extension DateFormatter {
    public func date(from string: String, timezoneIdentifier: String) -> Date? {
        self.timeZone = TimeZone(identifier: timezoneIdentifier)
        let date = self.date(from: string)
        self.timeZone = TimeZone.current
        return date
    }
}

public extension UIColor {
    static var dateGray: UIColor {
        return UIColor(red: 153 / 255, green: 153 / 255, blue: 153 / 255, alpha: 1)
    }

    static var tintColor: UIColor {
        return UIColor(red: 241 / 255, green: 110 / 255, blue: 0, alpha: 1)
    }

    static var green: UIColor {
        return UIColor(red: 78 / 255, green: 226 / 255, blue: 96 / 255, alpha: 1)
    }
    
    static var greyishBrown: UIColor {
        return UIColor(white: 85.0 / 255.0, alpha: 1.0)
    }
    
    static var whiteTwo: UIColor {
      return UIColor(white: 238.0 / 255.0, alpha: 1.0)
    }
    static var elegantGray: UIColor {
        return UIColor(white: 187.0 / 255.0, alpha: 1.0)
    }
    static var dividerColor: UIColor {
        return UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1)
    }
}

extension String {
    public var localized: String {
        if let path = SVKBundle.path(forResource: SVKContext.locale.languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path) {
            return NSLocalizedString(self, tableName: "SVKLocalizable", bundle: bundle, value: "", comment: "")
        }
        return self
    }
    
    public var localizedWithTenantLang: String {
        if let path = SVKBundle.path(forResource: SVKAPIClient.language, ofType: "lproj"),
            let bundle = Bundle(path: path) {
            return NSLocalizedString(self, tableName: "SVKLocalizable", bundle: bundle, value: "", comment: "")
        }
        return self
    }
    
    func localized(value:Int) -> String {
        var lastKey = "items"
        if value == 0 {
            lastKey = "zero"
        } else if value == 1 {
            lastKey = "item"
        }
        if let path = SVKBundle.path(forResource: SVKContext.locale.languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path) {
            let itemKey = NSLocalizedString(self + "." + lastKey, tableName: "DCLocalizable", bundle: bundle, value: "", comment: "")
            let format = NSLocalizedString(self + ".format", tableName: "DCLocalizable", bundle: bundle, value: "", comment: "")
            return String(format: format, value, itemKey.localized)
        }
        return self
    }
        
    func formatPTHMtoMinutes() -> String? {
        let initialDate  = self
        let pthmPattern = "PT(([0-9]+)H)?(([0-9]+)M)?"
        var totalMinutes: String?
        var totalMinutesInteger: Int = 0
        
        let regex = try? NSRegularExpression(
            pattern: pthmPattern,
            options: .caseInsensitive
        )
        
        if let match = regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: initialDate.utf16.count)) {
            if let hoursRange = Range(match.range(at: 2), in: initialDate) {
                let hours = initialDate[hoursRange]
                totalMinutesInteger = (Int(hours) ?? 0) * 60
            }
            if let minutesRange = Range(match.range(at: 4), in: initialDate) {
                let minutes = initialDate[minutesRange]
                totalMinutesInteger += (Int(minutes) ?? 0)
            }
            totalMinutes = String(totalMinutesInteger) + " min"
        }
        return totalMinutes
    }
    func sharedPrefix(with other: String) -> String {
        return (self.isEmpty || other.isEmpty || self.first! != other.first!) ? "" :
            "\(self.first!)" + String(Array(self.dropFirst())).sharedPrefix(with: String(Array(other.dropFirst())))
    }
}

extension UIRefreshControl {
    func trigger() {
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: false)
        }
        beginRefreshing()
        sendActions(for: .valueChanged)
    }
    
    var title: String? {
        set {
            if let value = newValue {
                let attributedString = NSMutableAttributedString(string: value, attributes: nil)
                attributedString.addAttributes([NSAttributedString.Key.foregroundColor:UIColor.dateGray,
                                                NSAttributedString.Key.font:UIFont.loader], range: NSMakeRange(0, attributedString.length))
                self.attributedTitle = attributedString
            } else {
                self.attributedTitle = nil
            }
        }
        get {
            return self.attributedTitle?.string
        }
    }
}

public extension UIFont {
    static var loader: UIFont {
        return UIFont.systemFont(ofSize: 11, weight: .regular)
    }
}

extension UILabel {
    func setTextWhileKeepingAttributes(string: String) {
        if let newAttributedText = self.attributedText {
            let mutableAttributedText = newAttributedText.mutableCopy()
            
            (mutableAttributedText as AnyObject).mutableString.setString(string)
            
            self.attributedText = mutableAttributedText as? NSAttributedString
        }
    }
    
    var maxNumberOfLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font ?? UIFont()], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
    
    func isTruncated() -> Bool {
        guard let text = text,
              let font = font else {
            return false
        }

        let textSize = (text as NSString).boundingRect(with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [.font: font], context: nil).size
        
        
        
        return textSize.height > bounds.size.height
    }
}

extension String {
    func numberOfLines(for width: CGFloat, and font: UIFont) -> Int {
        let maxSize = CGSize(width: width, height: CGFloat(MAXFLOAT))
        let text = self as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}
extension UIViewController {    
    var topParent: UIViewController? {
        var viewController: UIViewController? = parent
        repeat {
            if let _ = viewController?.parent {
                viewController = viewController?.parent
            } else {
                break
            }
        } while true
        return viewController
    }
}

extension Data {
    
    func wrapIntoWAVContainer() -> Data {
        
        let sampleRate: Int32 = 16000
        let chunkSize: Int32 = Int32(self.count) - 8
        let subChunkSize: Int32 = 16
        let format: Int16 = 1
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate: Int32 = sampleRate * Int32(channels * bitsPerSample / 8)
        let blockAlign: Int16 = channels * 2
        let dataSize: Int32 = Int32(self.count)
        
        var container = Data()
        
        container.append([UInt8]("RIFF".utf8), count: 4)
        container.append(intToByteArray(chunkSize), count: 4)
        container.append([UInt8]("WAVE".utf8), count: 4)
        container.append([UInt8]("fmt ".utf8), count: 4)
        container.append(intToByteArray(subChunkSize), count: 4)
        container.append(shortToByteArray(format), count: 2)
        container.append(shortToByteArray(channels), count: 2)
        container.append(intToByteArray(sampleRate), count: 4)
        container.append(intToByteArray(byteRate), count: 4)
        container.append(shortToByteArray(blockAlign), count: 2)
        container.append(shortToByteArray(bitsPerSample), count: 2)
        
        container.append([UInt8]("data".utf8), count: 4)
        container.append(intToByteArray(dataSize), count: 4)
        container.append(self)
        return container
        
    }
    
    func intToByteArray(_ i: Int32) -> [UInt8] {
        return [
            //little endian
            UInt8((i      ) & 0xff),
            UInt8((i >>  8) & 0xff),
            UInt8((i >> 16) & 0xff),
            UInt8((i >> 24) & 0xff)
        ]
    }
    
    func shortToByteArray(_ i: Int16) -> [UInt8] {
        return [
            //little endian
            UInt8((i      ) & 0xff),
            UInt8((i >>  8) & 0xff)
        ]
    }
}

public extension DispatchQueue {
    func safeAsync(execute: @escaping ()->Void) {
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.async(execute: execute)
        }
    }

    func safeSync(execute: @escaping ()->Void) {
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.sync(execute: execute)
        }
    }
}


extension UITextView {
    var isTextTruncated: Bool {
      var isTruncating = false

      // The `truncatedGlyphRange(...) method will tell us if text has been truncated
      // based on the line break mode of the text container
      layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: Int.max)) { _, _, _, glyphRange, stop in
        let truncatedRange = self.layoutManager.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphRange.lowerBound)
        if truncatedRange.location != NSNotFound {
          isTruncating = true
          stop.pointee = true
        }
      }

      // It's possible that the text is truncated not because of the line break mode,
      // but because the text is outside the drawable bounds
      if isTruncating == false {
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        isTruncating = characterRange.upperBound < text.utf16.count
      }

      return isTruncating
   }
}
