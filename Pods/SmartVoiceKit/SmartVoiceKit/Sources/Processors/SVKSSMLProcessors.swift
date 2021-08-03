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

internal extension String {
    /**
     The scalar representation of an unicode string (U+1F327)
     */
    var scalarFromUnicode: String {
        guard let value = components(separatedBy: "+").last,
            let int32 = UInt32(value, radix: 16),
            let unicodeScalar = Unicode.Scalar(int32) else {
                return self
        }
        return String(unicodeScalar)
    }

    /**
     Apply a regular expression to the String and returns the ranges of matching patterns
     - parameter pattern: The pattern to use as a regular expression.
     Returns an array of Range<String.Index>
     */
    func rangesOf(matching pattern: String) -> [Range<String.Index>] {
        
        var ranges = [Range<String.Index>]()
        let range = NSRange(location: 0, length: self.count)
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            regex.enumerateMatches(in: self, options: [], range: range) { (match, flags, stop) in
                if let match = match {
                    for n in 1..<match.numberOfRanges {
                        if  let range = Range(match.range(at: n), in: self) {
                            ranges.append(range)
                        }
                    }
                }
            }
        } catch _ {
            SVKLogger.error("NSRegularExpression failed with pattern \(pattern)")
        }
        
        return ranges
    }
    /**
     Returns true if the string contains a pattern
     - parameter pattern: The regular expression use to match the pattern
     - returns: true if is at least one match found, false otherwise
     */
    func contains(regex pattern: String) -> Bool {
        return rangesOf(matching: pattern ).count > 0
    }

    /**
     Apply a regular expression to the String and returns the very String matching the pattern
     - parameter pattern: The pattern to use as a regular expression.
     - returns: An array of Range<String.Index>
     */
    func components(matching pattern: String) -> [SVKSSMLProcessor.Output] {
        
        var components = [String]()
        let range = NSRange(location: 0, length: self.count)
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            regex.enumerateMatches(in: self, options: [], range: range) { (match, flags, stop) in
                if let match = match {
                    for n in 1..<match.numberOfRanges {
                        if  let range = Range(match.range(at: n), in: self) {
                            components.append(String(self[range]))
                        }
                    }
                }
            }
        } catch _ {
            SVKLogger.error("NSRegularExpression failed with pattern \(pattern)")
        }
        
        return components
    }
    
    /**
     Apply a regular expression to the String and the macthing components
     
     Each value matched is store in a dictionary using a key from the given list.
     The key used is picked at the match range's index in the provided list, keys. [keys[match.rangeIndex]: matches[match.rangeIndex]]
     - parameter pattern: The pattern to use as a regular expression.
     - parameter keys: A list of keys use sequentially to store the matching value in the dictionary
     - returns a dictionary of matching components
     */
    func components(matching pattern: String, bindTo keys: [String]) -> [String:SVKSSMLProcessor.Output] {
        
        var components = [String:SVKSSMLProcessor.Output]()
        let range = NSRange(location: 0, length: self.count)
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            regex.enumerateMatches(in: self, options: [], range: range) { (match, flags, stop) in
                if let match = match {
                    for n in 0..<keys.count {
                        if  let range = Range(match.range(at: n+1), in: self) {
                            components[keys[n]] = SVKSSMLProcessor.Output(self[range])
                        }
                    }
                }
            }
        } catch {
        }
        
        return components
    }
    
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
}

/**
 This enum defines the SVKSSMLProcessor behaviour
 */
enum SVKSSMLProcessorBehaviour {
    case undefined
    /**
     This pattern removes a tag. only long tag like <tag>value</tag>
     
     (String) represents the tag.
     */
    case removeTag(String)
    
    /**
     This pattern removes the Value of a tag with a specicif attribute value. only long tag like <tag attributeName="AttributeValue">value</tag>
     
     tag (String) represents the tag.
     attributeName represents the attribute name we look for
     attributeValue represents the attribute value we look for
     
     */
    case removeTagValue(tag:String,attributeName:String,attributeValue:String)
    
    /**
     This pattern removes all unknown tags.
     keepTags: [String] represent tags which should be kept
     */
    case removeUnknownTags(keepTags: [String])
    
    /**
     This pattern removes the tag and its content.
     
     (String?) represents the tag.
     */
    case removeTagAndContent(String?)
    
    /**
     Splits the content. (tag: String, Bool) If bool is true the pattern is removed
     
     This pattern should split the following content in 14 lines (Here the tag is 'break'):
     "The \'multiplication\' table for number \'5\' is:<break time=\"0ms\"/>\'5*0=0<break time=\"0ms\"/>5*1=5<break time=\"0ms\"/>5*2=10<break time=\"0ms\"/>5*3=15<break time=\"0ms\"/>5*4=20<break time=\"0ms\"/>5*5=25<break time=\"0ms\"/>5*6=30<break time=\"0ms\"/>5*7=35<break time=\"0ms\"/>5*8=40<break time=\"0ms\"/>5*9=45<break time=\"0ms\"/>5*10=50<break time=\"0ms\"/>5*11=55<break time=\"0ms\"/>5*12=60\'"
     */
    case splitContent(String,Bool)
    
    /**
     Extract url, layout and caption from a 'p' tag.
     
     This pattern should be able to extract the image link and the caption if presents
     of the following text:
    <p img-src=\"https://media.giphy.com/media/nZGIDIHQtimBO/giphy.gif\">Caption</p>

     [String] contains the key used to store the extracted values in the returned dictionary.
     */
    case imageAttributesAndCaptions([String])
    
    /**
     This pattern should be able to split the following text in at least 14 lines (paragraphs).
     
     Each paragraphe begins by a p tag or its a literal string :
     
     Yoda serves <p img-src="http://URL-of-image.com/img_girl.jpg" img-layout="landscape"></p>
     <p>Pour cette information, je vous invite à vous rendre sur <s display="none" alt="boutique.orange.fr">boutique point orange point fr</s>, ou à cliquer sur le lien <s display="none" alt="disponible dans la carte suivante">qui vient d'être envoyé sur votre application Speaker Djingo</s> dans la rubrique mon activité.</p>
     <p display="none">How can I help you</p>
     <p>Vous pouvez aussi appeler le service client au 3900.</p>
     <p>Hi Damien</p>
     <p>Yoda was the Jedi Master for apprentices:</p> Count Dooku
     <p img-src="https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg/revision/latest/scale-to-width-down/500?cb=20180430181839" img-layout="portrait"></p>
     
     and Luke Skywalker <p img-src="https://preview.redd.it/2qmnb44sbt7z.jpg?width=960&crop=smart&auto=webp&s=35a83797e4282127f3cdd7e8a50baeba4422b0a7" img-layout="landscape"></p>
     <p>In less than 100 years, Yoda achieved the title and rank of Jedi Master. <s display=\"none\" alt=\"Yoda used a cane to help him walk in his later life, although he was capable of throwing it aside and moving quickly while using the Force.\">Yoda was a master of lightsaber combat, he was one of the greatest duelists of all time.</s></p> <p img-src=\"https://lph5i1b6c053kq7us26bdk75-wpengine.netdna-ssl.com/wp-content/uploads/2012/11/master-yoda-facts.jpg\" img-layout=\"horizontal\"></p>
     Yoda serves as the Grand Master of the Jedi Order. <p img-src=\"https://media.giphy.com/media/nZGIDIHQtimBO/giphy.gif\"></p> <p alt=\"He is a high-ranking general of Clone Troopers in the Clone Wars.\"></p>
     */
    case paragraphs
    
    
    /**
     This pattern allow to matches a 's' tag with its attributes and contents.
     
     Match a sentence (<s> tag).
     Example of sentences that could be matched:
     <s alt="boutique.orange.fr">boutique point orange point fr</s>
     <s display="none" alt="disponible dans la carte suivante">qui vient d'être envoyé sur votre application Speaker Djingo</s>
     */
    case sentence
    
    /**
     This pattern determines which part of a tag'scontent is 'displayable'.
     
     Parse the sentence attributes to get it's displayable content.
     Example: <p display="none">How can I help you</p>
     */
    case displayableContent


    /// Match a unicode character and replace it by a Unicode.Scalar
    case replaceUnicode
    
    case splitContentForParner(String)
    
    /// Escape any strings between \\ and \\
    case escape
    
    /// The regex pattern associated to the behaviour
    var regexPattern: String {
        
        switch self {
        case .removeTag(let tag):
            return "(<((\(tag))(\\s*([^>]*)))>)((.|\n)*?)<\\/(\\3)>"
        case .removeTagValue(let tag, let attributeName , let attributeValue):
            return "<((\(tag))((\\s*(\(attributeName)=\"\(attributeValue)\")([^>]*?)))>)((.|\n)*?)<\\/\(tag)>"
        case .removeTagAndContent(let tag):
            if let tag = tag {
                return "(<((\(tag))(\\s*([^>]*)))>)((.|\n)*?)<\\/(\\3)>"
            } else {
                return "<[^>].+>"
            }
            
        case .splitContent(let tag, _):
          return "\\s?(<\(tag))([^\\/>]+)\\/>\\s?|\\s?(<\(tag))(.*)\\/\(tag)>\\s?"
                
        case .imageAttributesAndCaptions:
            return "(?:img-src=\"([^\"]*)\")(?:\\s+)?(?:img-layout=\"([^\"]*)\")?(?:\\s+)?>([^<>]*)<\\/p>"
            
        case .paragraphs:
               return "<p>([^<>]*)?(<s [^<]*<\\/s>)<\\/p>|([^<>]*)?(<p [^<]*<\\/p>)|(<p>[^<]*<\\/p>)?([^<>]*)?(<p [^<]*<\\/p>)?([^<>]*)|([^<>]*)?(<s [^<]*<\\/s>)"
            
        case .sentence:
            return "(.*?)(<s .*?<\\/s>)|(.+)"
        
        case .displayableContent:
            return "(display\\s?=\\s?\"none\")"
        
        case .replaceUnicode:
            return "(U\\+[A-F0-9]+)"
        
        case .splitContentForParner(let tag):
            return "\\s?(\(tag)(.*)(\\\\\(tag)))\\s?"
        case .undefined,.removeUnknownTags(_):
            return ""
        case .escape:
            return "(\\\\(.*?)\\\\)"
        }
    }
    
    /// The SSML tag
    var tag: String {        
        switch self {
        case .removeTag(let tag):
            return tag //?? ""
        case .removeTagAndContent(let tag):
            return tag ?? ""
        case .splitContent(let tag, _):
            return tag
        case .splitContentForParner(let tag):
            return tag
        case .removeTagValue(let tag, _,  _):
            return tag
        case .imageAttributesAndCaptions, .paragraphs,
             .sentence, .displayableContent, .replaceUnicode,
             .undefined,.removeUnknownTags, .escape:
            return ""
        }
    }
}


/**
 A text processor wich delete any SSML tag and its content from a text
 */
struct SVKSSMLProcessor: SVKProcessor {
    
    typealias Input = String
    typealias Output = String
    
    /// The input text thats contains the SSML
    var input: String = ""
    
    /// processor behaviour
    var behaviour: SVKSSMLProcessorBehaviour
    
    /**
     Parse a text, and clear it from any SVKSSMLProcessorBehaviour.tag
     - returns: the result of the process of the input text
     */
    func process() -> Output {
        switch behaviour {
        case .displayableContent:
            if input.contains(regex: behaviour.regexPattern) {
                return input.components(matching: "alt=\"(.+)\"" ).first ?? ""
            }
            
            guard let output = input.components(matching: ">\\s?(.+)\\s?<").first else {
                return input.components(matching: "alt=\"(.+)\"" ).first ?? input
            }
            return output
        
        case .replaceUnicode:
            return input.rangesOf(matching: behaviour.regexPattern)
                .reduce(input, { (result, range) -> String in
                    let value = String(input[range])
                    return result.replacingOccurrences(of: value,
                                                       with: value.scalarFromUnicode,
                                                       options: String.CompareOptions(rawValue: 0),
                                                       range: result.startIndex..<result.endIndex)

            })
        case .removeUnknownTags(let keepTags):
            var result = removeShortUnknownTags(input: input, knownTags: keepTags)
            result = removeLongUnknownTags(input: result, knownTags: keepTags)
            return result

        case .removeTag(let tag):
            var result = removeLongTagsKeepValue(input: input, regexPattern: behaviour.regexPattern)
            result = removed(tag, from: result)
            return result

        case .removeTagValue(let tag,_,_):
            var result = removeTagValueWithSpecificAttribute(input: input, regexPattern: behaviour.regexPattern)
            result = removed(tag, from: result)
            return result

        case .escape:
            return input.rangesOf(matching: behaviour.regexPattern)
                .reduce(input, { (result, range) -> String in
                    let value = String(input[range])
                    return result.replacingOccurrences(of: value,
                                                       with: "",
                                                       options: String.CompareOptions(rawValue: 0),
                                                       range: result.startIndex..<result.endIndex) })
                .trimmingCharacters(in: .whitespaces)
        
        default:
            return input.replacingOccurrences(of: behaviour.regexPattern, with: "", options: .regularExpression, range: nil)
                .replacingOccurrences(of: "<\(behaviour.tag)>", with: "")
                .replacingOccurrences(of: "</\(behaviour.tag)>", with: "")
        }
    }
    
    /**
     remove short unknownTags like <tag attribute /> from input and knowntags
     */

    func removeShortUnknownTags(input:String,knownTags: [String]) -> String {
        var result = ""
        var start = input.startIndex
        let regexPattern = "(<([^<\\/\\s]*)(\\s*([^<\\/]*)))\\/>"
        let regex = try? NSRegularExpression(
            pattern: regexPattern,
            options: .caseInsensitive
        )
        while let range = input.range(of: regexPattern, options: .regularExpression, range: start..<input.endIndex) {
            let newStr = String(input[start..<range.lowerBound])
            if (!newStr.isEmpty){
                result.append(newStr)
            }
            start = range.lowerBound < range.upperBound ? range.upperBound : input.index(range.lowerBound, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
            if (range.lowerBound < range.upperBound) {
                let resp = String(input[range.lowerBound..<range.upperBound])
                if let match = regex?.firstMatch(in: resp, options: [], range: NSRange(location: 0, length: resp.utf16.count)) {
                    let tagName = String(resp[Range(match.range(at: 2), in: resp)!])
                    if knownTags.contains(tagName) {
                        result.append(resp)
                    }
                }
            }
        }
        let newStr = String(input[start..<input.endIndex])
        if (!newStr.isEmpty){
            result.append(newStr)
        }
        return result
    }

    // anyTagWithdrawer
    private func removed(_ tag:String, from input:String) -> String {
        func withdraw(statement: String, from phrase: inout String){
            phrase = phrase.replacingOccurrences(of: statement, with: "")
        }
        //                   (          full match                           )
        //                   ( 2nd group   )                   (another 2nd  )
        //                                  (   )  third group
        //                                       (           ) 4th group
        let regEx: String = "(<\(tag)[^>]*>)(.*?)(<\\/\(tag)>)|(<\(tag)[^>]*>)"
        
        //: The expression manages two types of tags =>
        //: 1.`<tag...>...</tag>`
        //: 2. `<tag .../>`
        //: that's why it contains Logical OR symbol => `|` to separate groups.
        //: There are four possible matching groups in this expression:
        
        //: - The **first** one : so-called "full match", it's the entire expression between "(...)"
        //: will capture the expression between the tags and include tags themselves `<tag ...>...</tag>`
        
        //: - The **second** group is : either the opening tag `<tag ...>` or the "full match"
        //: the same as the **first** group for **self-closing** tags i.e. `<tag .../>`
        
        //: - The **third** OPTIONAL group is the content between tags: `<tag...> CONTENT </tag>`
        //: - The **fourth** OPTIONAL group is the closing tag `</tag>`
        
        let result = input.matchingStrings(regex: regEx)
    
        var parsed = input
        result.forEach { capturingGroups in
            let filtered = capturingGroups.filter {!$0.isEmpty}
            switch filtered.count {
            case 2:
                // self-closing tag i.e. <tag .../>
                let _tag = filtered[1]
                withdraw(statement: _tag, from: &parsed)
            case 4:
                // <tag ...>...</tag>
                let openingTag = filtered[1]
                let closingTag = filtered[3]
                withdraw(statement: openingTag, from: &parsed)
                withdraw(statement: closingTag, from: &parsed)
            default:
                break
            }
        }
        return parsed
    }
    
    /**
     remove long unknownTags like <tag>value</tag> from input and knowntags
     */

    func removeLongUnknownTags(input:String,knownTags: [String]) -> String {
        var result = ""
        var start = input.startIndex
        let regexPattern = "(<(([^>]*)(\\s*([^>]*)))>)((.|\\n)*?)<\\/(\\3)>"
        let regex = try? NSRegularExpression(
            pattern: regexPattern,
            options: .caseInsensitive
        )
        while let range = input.range(of: regexPattern, options: .regularExpression, range: start..<input.endIndex) {
            let newStr = String(input[start..<range.lowerBound])
            if (!newStr.isEmpty){
                result.append(newStr)
            }
            start = range.lowerBound < range.upperBound ? range.upperBound : input.index(range.lowerBound, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
            if (range.lowerBound < range.upperBound) {
                let resp = String(input[range.lowerBound..<range.upperBound])
                if let match = regex?.firstMatch(in: resp, options: [], range: NSRange(location: 0, length: resp.utf16.count)) {
                    let tagName = String(resp[Range(match.range(at: 3), in: resp)!])
                    if knownTags.contains(tagName) {
                        let tagName = String(resp[Range(match.range(at: 3), in: resp)!])
                        let tagHeader = String(resp[Range(match.range(at: 1), in: resp)!])
                        let value = String(resp[Range(match.range(at: 6), in: resp)!])
                        let tagEnd = "</\(tagName)>"
                        result.append(tagHeader)
                        let eval = removeLongUnknownTags(input: value, knownTags: knownTags)
                        if !eval.isEmpty {
                            result.append(eval)
                        }
                        result.append(tagEnd)
                    }
                }
            }
        }
        let newStr = String(input[start..<input.endIndex])
        if (!newStr.isEmpty){
            result.append(newStr)
        }
        return result
    }
    
    /**
     remove long unknownTags like <tag>value</tag> from input and knowntags but keep the value
     */

    func removeLongTagsKeepValue(input:String,regexPattern: String) -> String {
        var result = ""
        var start = input.startIndex
//        let regexPattern = "(<((\(tag))(\\s*([^>]*)))>)((.|\n)*?)<\\/(\\3)>"
        let regex = try? NSRegularExpression(
            pattern: regexPattern,
            options: .caseInsensitive
        )
        while let range = input.range(of: regexPattern, options: .regularExpression, range: start..<input.endIndex) {
            let newStr = String(input[start..<range.lowerBound])
            if (!newStr.isEmpty){
                result.append(newStr)
            }
            start = range.lowerBound < range.upperBound ? range.upperBound : input.index(range.lowerBound, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
            if (range.lowerBound < range.upperBound) {
                let resp = String(input[range.lowerBound..<range.upperBound])
                if let match = regex?.firstMatch(in: resp, options: [], range: NSRange(location: 0, length: resp.utf16.count)) {
                    let value = String(resp[Range(match.range(at: 6), in: resp)!])
                    if !value.isEmpty {
                        result.append(value)
                    }
                   
                }
            }
        }
        let newStr = String(input[start..<input.endIndex])
        if (!newStr.isEmpty){
            result.append(newStr)
        }
        return result
    }
    
    /**
     remove value for long Tag with a specific attribute like <tag attibuteName="AttributeValue">value</tag> from input keep only the tag part.
     */
    
    func removeTagValueWithSpecificAttribute(input:String,regexPattern: String) -> String {
        var result = ""
        var start = input.startIndex
        //        let regexPattern = "(<((\(tag))(\\s*([^>]*)))>)((.|\n)*?)<\\/(\\3)>"
        let regex = try? NSRegularExpression(
            pattern: regexPattern,
            options: .caseInsensitive
        )
        while let range = input.range(of: regexPattern, options: .regularExpression, range: start..<input.endIndex) {
            let newStr = String(input[start..<range.lowerBound])
            if (!newStr.isEmpty){
                result.append(newStr)
            }
            start = range.lowerBound < range.upperBound ? range.upperBound : input.index(range.lowerBound, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
            if (range.lowerBound < range.upperBound) {
                let resp = String(input[range.lowerBound..<range.upperBound])
                if let match = regex?.firstMatch(in: resp, options: [], range: NSRange(location: 0, length: resp.utf16.count)) {
                    let tag = String(resp[Range(match.range(at: 2), in: resp)!])
                    let value = String(resp[Range(match.range(at: 1), in: resp)!])
                    let displayable = SVKSSMLProcessor(input: value, behaviour: .displayableContent).process()
                    if !value.isEmpty ,!tag.isEmpty,!displayable.isEmpty {
                        result.append("<")
                        result.append(value)
                        result.append("</")
                        result.append(tag)
                        result.append(">")
                    }
                    
                }
            }
        }
        let newStr = String(input[start..<input.endIndex])
        if (!newStr.isEmpty){
            result.append(newStr)
        }
        return result
    }
}

