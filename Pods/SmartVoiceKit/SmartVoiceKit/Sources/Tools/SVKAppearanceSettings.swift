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

fileprivate extension String{
    func contains(_ other: SVKFont.FontLexis) -> Bool{
        return self.contains(other.rawValue)
    }
    var svkFontName:String{
        var str = SVKFont.FontLexis.system.rawValue
        let fontName = self.lowercased()
        if fontName.contains(SVKFont.FontLexis.bold){
            str.append(SVKFont.FontLexis.bold.rawValue)
        }
        if fontName.contains(SVKFont.FontLexis.italic) {
            str.append(SVKFont.FontLexis.italic.rawValue)
        }
        return str
    }
}
fileprivate extension UIImage{
    static func drawPDFfromURL(url: URL?) -> UIImage? {
        guard let url = url,
            let document = CGPDFDocument(url as CFURL),
            let page = document.page(at: 1) else { return nil }
        
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.clear.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }
 
    static func renderPdf(named pdf: String?, orUsePNG defaultImg: String) ->  UIImage?{
        guard let imgName = pdf else {
            return defaultImg.isEmpty ? nil : SVKTools.imageWithName(defaultImg)
        }
        var url = Bundle.main.url(forResource: imgName, withExtension: "pdf")
        if url == nil {
            url = SVKBundle.url(forResource: imgName, withExtension: "pdf")
        }
        return UIImage.drawPDFfromURL(url: url)
    }
    static func dynamicImage(from imageDescription: SVKImageDescription?,
                      usingDefault: String) ->  UIImage?{
        guard let dayImg = UIImage.renderPdf(named: imageDescription?.main, orUsePNG: usingDefault) else { return SVKTools.imageWithName(usingDefault) }
        // don't use defaultImg: if there isn't nightImg we should use dayImg instead
        guard let nightImg = UIImage.renderPdf(named: imageDescription?.dark, orUsePNG: "")  else {
            return dayImg
        }
        if #available(iOS 13.0, *) {
            let scaleTrait = UITraitCollection(displayScale: UIScreen.main.scale)
            let styleTrait = UITraitCollection(userInterfaceStyle: .dark)
            let traits = UITraitCollection(traitsFrom: [styleTrait, scaleTrait])
             dayImg.imageAsset?.register(nightImg, with: traits)
        }
        return dayImg
    }
}
protocol SVKAuditable {
    associatedtype SVKParams
    func checkConfiguration(_ params: SVKParams?) throws
    
}
public enum SVKFlavorError: Error{
    case missingDarkColor
    case missingConfigurationFile
}
public enum SVKInterfaceStyle : String {
    case main
    case dark
}
extension SVKInterfaceStyle : Decodable{}
public struct SVKFont: Decodable{
    var name: String
    var size: CGFloat
    public init(with font: UIFont) {
        self.size = font.pointSize
        self.name = font.familyName
        if font.familyName.lowercased().contains("apple")
            && font.familyName.lowercased().contains(.system){ // ".AppleSystemUIFont"
            self.name = font.fontName.svkFontName
        }
    }
    public init(name: String, size: CGFloat) {
        self.name = name
        self.size = size
    }
}
extension SVKFont{
    public var font: UIFont{
        var _font: UIFont = UIFont.boldSystemFont(ofSize: 15)
        if isSystemFont {
            _font = systemFont
        }else{
            _font = UIFont(name: name, size: size) ?? _font
        }
        
        return _font
    }
    fileprivate enum FontLexis: String{
        case system, bold, italic, monospace
    }
    private var isSystemFont: Bool{
        name.lowercased().contains(FontLexis.system)
    }
    private var systemFont: UIFont{
        let fontName = name.lowercased()
        if fontName.contains(FontLexis.bold){
            return UIFont.boldSystemFont(ofSize: size)
        }
        if fontName.contains(FontLexis.italic) {
            return UIFont.italicSystemFont(ofSize: size)
        }
        if fontName.contains(FontLexis.monospace){
            return UIFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
        }
        return UIFont.systemFont(ofSize: size)
    }
}

public enum SVKTextAlignment: String, Decodable{
    case left, right, center, justified, natural
    public var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left:
            return NSTextAlignment.left
        case .right:
            return NSTextAlignment.right
        case .center:
            return NSTextAlignment.center
        case .justified:
            return NSTextAlignment.justified
        case .natural:
            return NSTextAlignment.natural
        }
    }
}
public struct SVKImageDescription: Codable{
    public var main: String
    public var dark: String? // the dark image is not mandatory for the image description
    
    public init(main: String, dark: String? = nil) {
        self.main = main
        self.dark = dark
    }
}
/**
 Provides suitable images for the SVK needs.
 Search an PDF asset for given name.
 */
public struct SVKImageProvider{
    /// Radio buttons
    public var radioButtonActiveImageName: SVKImageDescription?
    public var radioButtonInactiveImageName: SVKImageDescription?
    /// Check box buttons
    public var checkBoxActiveImageName: SVKImageDescription?
    public var checkBoxInactiveImageName: SVKImageDescription?
    /// Audio Rec component images & Conversation Mic images
    public var audioRecordingActiveImageName: SVKImageDescription?
    public var audioRecordingInactiveImageName: SVKImageDescription?
    public var audioRecordingImageSideSize: CGFloat?
    public var audioRecordingHighlightedImageName: SVKImageDescription?
    /// Swipe over bubble images
    public var swipeCopyImageName: SVKImageDescription?
    public var swipeShareImageName: SVKImageDescription?
    public var swipePlayImageName: SVKImageDescription?
    public var swipeDeleteImageName: SVKImageDescription?
    public var swipeMisunderstoodImageName: SVKImageDescription?
    public var swipeResendImageName: SVKImageDescription?
    
    /// Long press on bubble images
    public var lpCopyImageName: SVKImageDescription?
    public var lpShareImageName: SVKImageDescription?
    public var lpPlayImageName: SVKImageDescription?
    public var lpDeleteImageName: SVKImageDescription?
    public var lpMisunderstoodImageName: SVKImageDescription?
    public var lpResendImageName: SVKImageDescription?
    
    /// flag
    public var flagImageName: SVKImageDescription?
    
    /// mic animation images
    
    public var speakingAnimation: [SVKImageDescription]?
    
    /// empty screen icon, will be shown in the middle of the screen
    public var emptyScreenImageName: SVKImageDescription?
    
    /// empty screen icon, will be shown in the middle of the screen
    public var networkErrorImageName: SVKImageDescription?
    
    // deleteAll page screen icon, will be shown in the middle of the screen
    public var deleteAllPageImageName: SVKImageDescription?
    
    public var tableCellActionIconName: SVKImageDescription?
    /// feedback consent screen icon, will be shown in the middle of the screen
    public var consentScreenImageName: SVKImageDescription?

    /// Filter screen icons
    public var filterDropDownImageName: SVKImageDescription?
    public var filterCloseImageName: SVKImageDescription?

    public init(){}
}
extension SVKImageProvider{
    /// all getters are summed here
    /// Calculated Properties zone
    public var radioButtonOff: UIImage? {
        UIImage.dynamicImage(from: radioButtonInactiveImageName, usingDefault: "radioOff")
    }
    public var radioButtonOn: UIImage? {
        UIImage.dynamicImage(from: radioButtonActiveImageName, usingDefault: "radioOn")
    }
    
    public var checkBoxOn: UIImage? {
        UIImage.dynamicImage(from: checkBoxActiveImageName, usingDefault: "checkOn")
    }
    public var checkBoxOff: UIImage? {
        UIImage.dynamicImage(from: checkBoxInactiveImageName, usingDefault: "checkOff")
    }
    
    public var longPressPlay: UIImage?{
        UIImage.dynamicImage(from: lpPlayImageName, usingDefault: "play-action-button")
    }
    public var longPressShare: UIImage?{
        UIImage.dynamicImage(from: lpShareImageName, usingDefault: "share-button")
    }
    public var longPressCopy: UIImage?{
        UIImage.dynamicImage(from: lpCopyImageName, usingDefault: "copy-button")
    }
    public var longPressDelete: UIImage?{
        UIImage.dynamicImage(from: lpDeleteImageName, usingDefault: "delete-button")
    }
    public var longPressMisunderstood: UIImage?{
        UIImage.dynamicImage(from: lpMisunderstoodImageName, usingDefault: "comment-button")
    }
    public var longPressResend: UIImage?{
        UIImage.dynamicImage(from: lpResendImageName, usingDefault: "resend-button")
    }
    
    public var swipeShare: UIImage?{
        UIImage.dynamicImage(from: swipeShareImageName, usingDefault: "share-button")
    }
    public var swipeCopy: UIImage?{
        UIImage.dynamicImage(from: swipeCopyImageName, usingDefault: "copy-button")
    }
    public var swipePlay: UIImage?{
        UIImage.dynamicImage(from: swipePlayImageName, usingDefault: "play-action-button")
    }
    public var swipeDelete: UIImage?{
        UIImage.dynamicImage(from: swipeDeleteImageName, usingDefault: "delete-button")
    }
    public var swipeMisunderstood: UIImage?{
        UIImage.dynamicImage(from: swipeMisunderstoodImageName, usingDefault: "comment-button")
    }
    public var swipeResend: UIImage?{
        UIImage.dynamicImage(from: swipeResendImageName, usingDefault: "resend-button")
    }
    
    public var flag: UIImage?{
        UIImage.dynamicImage(from: flagImageName, usingDefault: "signal-flag")
    }
    
    public var audioRecOn: UIImage?{
        UIImage.dynamicImage(from: audioRecordingActiveImageName, usingDefault: "Djingo-Mic-dynamic")
    }
    public var audioRecOff: UIImage?{
        UIImage.dynamicImage(from: audioRecordingInactiveImageName, usingDefault: "Djingo-Mic-Mute-dynamic")
    }

    public var animatedImages: [UIImage]? {
        
        func defaultImgs()->[UIImage]{
            return  (0...3)
                .map {"Djingo-Speaker" + String($0)}
                .compactMap {SVKTools.imageWithName($0)}
        }
        
        guard let imgDescriptions = speakingAnimation else{
            return defaultImgs()
        }
        
        let imgs = imgDescriptions.compactMap{UIImage.dynamicImage(from: $0, usingDefault: "")}
        return imgs.count > 0 ? imgs : defaultImgs()
    }
    
    public var audioRecHighlighted: UIImage?{
        var dayImg = SVKTools.imageWithName("Djingo-Mic-dynamic")?.withColor(UIColor(hex: "#666666")).withRenderingMode(.alwaysOriginal)
        var nightImg = dayImg
        
        if let dayImgName = audioRecordingHighlightedImageName?.main{
            var url = Bundle.main.url(forResource: dayImgName, withExtension: "pdf")
            if url == nil {
                url = SVKBundle.url(forResource: dayImgName, withExtension: "pdf")
            }
            dayImg = UIImage.drawPDFfromURL(url: url)
        }
        
        if let nightImgName = audioRecordingHighlightedImageName?.dark{
            var url = Bundle.main.url(forResource: nightImgName, withExtension: "pdf")
            if url == nil{
                url = SVKBundle.url(forResource: nightImgName, withExtension: "pdf")
            }
            nightImg = UIImage.drawPDFfromURL(url: url)
        }
        
        if #available(iOS 13.0, *),
            let nightImg = nightImg{
            let scaleTrait = UITraitCollection(displayScale: UIScreen.main.scale)
            let styleTrait = UITraitCollection(userInterfaceStyle: .dark)
            let traits = UITraitCollection(traitsFrom: [styleTrait, scaleTrait])
            dayImg?.imageAsset?.register(nightImg, with: traits)
        }
        return dayImg
        
    }
    
    public var emptyScreen: UIImage?{
        UIImage.dynamicImage(from: emptyScreenImageName, usingDefault: "empty-screen")
    }
    public var networkErrorScreen: UIImage?{
        UIImage.dynamicImage(from: networkErrorImageName, usingDefault: "empty-network-screen")
    }
    public var deleteAllPage: UIImage?{
        UIImage.dynamicImage(from: deleteAllPageImageName, usingDefault: "iconDelete")
    }
    public var tableCellActionIcon: UIImage?{
        UIImage.dynamicImage(from: tableCellActionIconName, usingDefault: "chevron_down")
    }
    public var consentScreen: UIImage?{
        UIImage.dynamicImage(from: consentScreenImageName, usingDefault: "consent-page")
    }

    public var filterDropDown: UIImage? {
        UIImage.dynamicImage(from: filterDropDownImageName, usingDefault: "dropDownArrow")
    }

    public var filterClose: UIImage? {
        UIImage.dynamicImage(from: filterCloseImageName, usingDefault: "filterClose")
    }
}

extension SVKImageProvider: Decodable {
    private enum CodingKeys: String, CodingKey {
        case radioButtonActiveImageName = "radioButtonActive"
        case radioButtonInactiveImageName = "radioButtonInactive"
        case checkBoxActiveImageName = "checkBoxActive"
        case checkBoxInactiveImageName = "checkBoxInactive"
        
        case lpCopyImageName = "longPressCopy"
        case lpShareImageName = "longPressShare"
        case lpPlayImageName = "longPressPlay"
        case lpDeleteImageName = "longPressDelete"
        case lpMisunderstoodImageName = "longPressMisunderstood"
        case lpResendImageName = "longPressResend"
        
        case swipeCopyImageName          = "swipeCopy"
        case swipeShareImageName         = "swipeShare"
        case swipePlayImageName          = "swipePlay"
        case swipeDeleteImageName        = "swipeDelete"
        case swipeMisunderstoodImageName = "swipeMisunderstood"
        case swipeResendImageName = "swipeResend"
        
        case flagImageName = "flag"
        
        case audioRecordingActiveImageName = "audioRecActive"
        case audioRecordingInactiveImageName = "audioRecInactive"
        case audioRecordingImageSideSize = "audioRecSideSize"
        case speakingAnimation = "speakingAnimation"
        case audioRecordingHighlightedImageName = "audioRecHighlighted"
        
        case emptyScreenImageName = "emptyPage"
        case networkErrorImageName = "networkError"
        case deleteAllPageImageName = "deleteAllPage"
        case tableCellActionIconName = "tableCellActionIcon"
        case consentScreenImageName = "feedbackPage"
        case filterCloseImageName = "filterClose"
        case filterDropDownImageName = "filterDropDown"
    }
}

public struct SVKColor {
    var main: UIColor
    var dark: UIColor?
    
    public init(main: UIColor, dark: UIColor? = nil) {
        self.main = main
        self.dark = dark
    }
    
}
extension SVKColor{
    public var color: UIColor{
        get{
            var dynamicColor = self.main
            if #available(iOS 13.0, *),
                SVKAppearanceBox.shared.appearance.userInterfaceStyle.contains(.dark){
                dynamicColor = UIColor { traitCollection -> UIColor in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return self.dark ?? self.main
                    case .light, .unspecified:
                        return self.main
                    @unknown default:
                        return self.main
                    }
                }
            }
            return dynamicColor
        }
    }
    public func getColor(_ withInterfaceStyle: Set<SVKInterfaceStyle>) -> UIColor
    {
        var dynamicColor = self.main
        if #available(iOS 13.0, *),
           withInterfaceStyle.contains(.dark){
            dynamicColor = UIColor { traitCollection -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return self.dark ?? self.main
                case .light, .unspecified:
                    return self.main
                @unknown default:
                    return self.main
                }
            }
        }
        return dynamicColor
    }
}
extension SVKColor: Decodable{
    private enum CodingKeys: String, CodingKey {
        case main
        case dark
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hexMain = try container.decode(String.self, forKey: .main)
        self.main = UIColor(hex: hexMain)
        if let hexDark = try? container.decode(String.self, forKey: .dark){
            self.dark = UIColor(hex: hexDark)
        }
    }
}
extension SVKColor: SVKAuditable{
    func checkConfiguration(_ params: Set<SVKInterfaceStyle>? = nil) throws{
        guard let params = params,
            !params.isEmpty else {
                return
        }
        
        // verify if there is any color for .dark mode
        if params.contains(.dark),
            self.dark == nil{
            throw SVKFlavorError.missingDarkColor
        }
    }
}

public struct SVKTableAppearance {
    public var section: SVKTableSectionAppearance
    public var cell: SVKTableCellAppearance
    
    public init(section: SVKTableSectionAppearance, cell: SVKTableCellAppearance
    ) {
        self.section = section
        self.cell = cell
    }
}

extension SVKTableAppearance: Decodable{
//    private enum CodingKeys: String, CodingKey {
//        case section
//        case cell
//    }
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let cell = try container.decode(SVKTableCellAppearance.self, forKey: .cell)
//        self.cell = cell
//        if let hexDark = try? container.decode(String.self, forKey: .dark){
//            self.dark = UIColor(hex: hexDark)
//        }
//    }
}

public struct SVKTableSectionAppearance {
    public var backgroundColor: SVKColor
    public var foregroundColor: SVKColor
    public var separatorColor: SVKColor
}
extension SVKTableSectionAppearance: Decodable{
}
public struct SVKTableCellAppearance {
    public var backgroundColor: SVKColor
    public var foregroundMainColor: SVKColor
    public var foregroundSecondColor: SVKColor
    public var foregroundButtonColor: SVKColor
    public var separatorColor: SVKColor
    public var actionForegroundColor: SVKColor
    public var footerSeparatorColor: SVKColor
}
extension SVKTableCellAppearance: Decodable{
}


public struct SVKStandardPageAppearance {
    private(set) var backgroundColor: SVKColor
    private(set) var messageTitleFont: SVKFont
    private(set) var messageTitleColor: SVKColor
    private(set) var messageDescriptionFont: SVKFont
    private(set) var messageDescriptionColor: SVKColor
    private(set) var textAlignment: SVKTextAlignment
    private(set) var bulletTextAlignment: SVKTextAlignment
    private(set) var pageLeading: Int
    private(set) var pageTrailing: Int
    private(set) var useShadow: Bool
    private(set) var buttonZoneBackgroundColor: SVKColor
    
    public init( backgroundColor: SVKColor, messageTitleFont: SVKFont, messageTitleColor: SVKColor, messageDescriptionFont: SVKFont, messageDescriptionColor: SVKColor, textAlignment: SVKTextAlignment, bulletTextAlignment: SVKTextAlignment,
                 useShadow: Bool, pageLeading: Int, pageTrailing: Int, buttonZoneBackgroundColor: SVKColor) {
        self.backgroundColor = backgroundColor
        self.messageTitleFont = messageTitleFont
        self.messageTitleColor = messageTitleColor
        self.messageDescriptionFont = messageDescriptionFont
        self.messageDescriptionColor = messageDescriptionColor
        self.textAlignment = textAlignment
        self.bulletTextAlignment = textAlignment
        self.pageLeading = pageLeading
        self.pageTrailing = pageTrailing
        self.useShadow = useShadow
        self.buttonZoneBackgroundColor = buttonZoneBackgroundColor
    }
}
extension SVKStandardPageAppearance: Decodable{
}

public struct SVKButtonStyleDescription{
    public var fillColor: SVKColor
    public var shapeColor: SVKColor
    public var lineWidth: CGFloat
    
    public init(fillColor: SVKColor, shapeColor: SVKColor, lineWidth: CGFloat){
        self.fillColor = fillColor
        self.shapeColor = shapeColor
        self.lineWidth = lineWidth
    }
}
extension SVKButtonStyleDescription: Decodable{}

public struct SVKToastAppearance: Decodable{
    public var backgroundColor: SVKColor
    public var textColor: SVKColor
    public var actionTextColor: SVKColor
    public var textFont: SVKFont
    public var actionTextFont: SVKFont
    public var iconDefault: SVKImageDescription
    public var iconConfirmation: SVKImageDescription
    public var iconNoWifi: SVKImageDescription
    public var verticalPadding: CGFloat
    
}
public struct SVKHorizontalAppearance: Decodable {
    public var left: CGFloat
    public var right: CGFloat
    public var avatar: CGFloat
    
    public init(left: CGFloat = 52.0,
                right: CGFloat = 31.0,
                avatar: CGFloat = 8.0) {
        self.left = left
        self.right = right
        self.avatar = avatar
    }
}
extension SVKToastAppearance{
    
    public init(with backgroundColor: SVKColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(white: 1.0, alpha: 1.0)),
                textColor: SVKColor = SVKColor(main: UIColor(hex: "#ffffff"), dark: UIColor(hex: "#262626")),
                actionTextColor: SVKColor = SVKColor(main: UIColor(hex: "#ff7900"), dark: UIColor(hex: "#ff7900")),
                textFont: SVKFont = SVKFont(with: .systemFont(ofSize: 15)),
                actionTextFont: SVKFont = SVKFont(with: .systemFont(ofSize: 15, weight: .medium)),
                iconDefault: SVKImageDescription = SVKImageDescription(main: "", dark: ""),
                iconConfirmation: SVKImageDescription = SVKImageDescription(main: "", dark: ""),
                iconNoWifi: SVKImageDescription = SVKImageDescription(main: "", dark: ""),
                verticalPadding: CGFloat) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.actionTextColor = actionTextColor
        self.textFont = textFont
        self.actionTextFont = actionTextFont
        self.iconDefault = iconDefault
        self.iconConfirmation = iconConfirmation
        self.iconNoWifi = iconNoWifi
        self.verticalPadding = verticalPadding
    }
    public var defaultLogo: UIImage? {
        UIImage.dynamicImage(from: iconDefault.main.isEmpty ? nil : iconDefault, usingDefault: "toastDefault")
    }
    public var confirmationLogo: UIImage? {
        UIImage.dynamicImage(from: iconConfirmation.main.isEmpty ? nil : iconConfirmation, usingDefault: "toastConfirm")
    }
    public var networkingLogo: UIImage? {
        UIImage.dynamicImage(from: iconNoWifi.main.isEmpty ? nil : iconNoWifi, usingDefault: "toastNoWifi")
    }
    fileprivate static var defaultToast: Self{
        SVKToastAppearance(backgroundColor: SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(white: 1.0, alpha: 1.0)),
                           textColor: SVKColor(main: UIColor(hex: "#ffffff"), dark: UIColor(hex: "#262626")),
                           actionTextColor: SVKColor(main: UIColor(hex: "#ff7900"), dark: UIColor(hex: "#ff7900")),
                           textFont: SVKFont(with: .systemFont(ofSize: 15)),
                           actionTextFont: SVKFont(with: .systemFont(ofSize: 15, weight: .medium)),
                           iconDefault: SVKImageDescription(main: ""),
                           iconConfirmation: SVKImageDescription(main: ""),
                           iconNoWifi: SVKImageDescription(main: ""),
                           verticalPadding: 8)
    }
}
public struct SVKButtonAppearance {
    public var cornerRadius: CGFloat
    public var defaultState: SVKButtonStyleDescription
    public var highlightedState: SVKButtonStyleDescription
    public var disruptiveState: SVKButtonStyleDescription
    
    public init(`default`: SVKButtonStyleDescription,
                highlighted: SVKButtonStyleDescription,
                disruptive: SVKButtonStyleDescription,
                cornerRadius: CGFloat){
        self.defaultState = `default`
        self.highlightedState = highlighted
        self.disruptiveState = disruptive
        self.cornerRadius = cornerRadius
    }
}
extension SVKButtonAppearance: Decodable{}

public struct SVKBubbleAppearanceSettings: Decodable {
    public enum PinStyle: String, Decodable {
        case magenta, djingo
    }
    public var flagColor: SVKColor
    public var backgroundColor: SVKColor
    public var textColor: SVKColor
    public var cornerRadius: CGFloat
    public var contentInset: UIEdgeInsets
    public var category: PinStyle
    public var borderColor: SVKColor
    public var borderWidth: CGFloat
    public var typingTextColor: SVKColor
    
    public init(backgroundColor: SVKColor = SVKColor(main: .defaultAssistantColor, dark: UIColor(hex: "#F16E00")),
                textColor: SVKColor = SVKColor(main: .defaultAssistantText, dark: UIColor(hex: "#FFFFFF")),
                flagColor: SVKColor = SVKColor(main: .defaultAssistantColor, dark: UIColor(hex: "#F16E00")),
                cornerRadius: CGFloat = CGFloat(18),
                typingTextColor: SVKColor = SVKColor(main: UIColor(hex: "#8F8F8F"), dark: UIColor(hex: "#bbbbbbff")),
                borderColor: SVKColor = SVKColor(main: .defaultAssistantColor, dark: UIColor(hex: "#F16E00")),
                borderWidth: CGFloat = SVKBubble.defaultborderWidth,
                contentInset: UIEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12),
                category: PinStyle = .djingo) {
        self.flagColor = flagColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.category = category
        self.contentInset = contentInset
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.typingTextColor = typingTextColor
    }
}
extension SVKBubbleAppearanceSettings{
    fileprivate static var _color:SVKColor{
        SVKColor(main: .defaultAssistantColor, dark: UIColor(hex: "#F16E00"))
    }
    fileprivate static var _txtColor:SVKColor{
        SVKColor(main: .defaultAssistantText, dark: UIColor(hex: "#FFFFFF"))
    }
    fileprivate static var defaultUserBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .defaultUserColor,
                                                      dark: UIColor(hex: "#272727")),
                            textColor: SVKColor(main: .black,
                                                dark: UIColor(hex: "#EEEEEE")),
                            flagColor: SVKColor(main: .defaultUserColor,
                                                dark: UIColor(hex: "#272727")),
                            borderColor: SVKColor(main: .defaultUserColor,
                                                  dark: UIColor(hex: "#272727"))
        )
    }
    fileprivate static var defaultHeaderCollapsedErrorBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white,
                                                      dark: .black),
                            textColor: SVKColor(main: UIColor(hex: "#DDDDDD"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            borderColor: SVKColor(main: .white,
                                                  dark: .black),
                            borderWidth: CGFloat(0.0))
    }
    fileprivate static var defaultHeaderExpandedErrorBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white,
                                                      dark: .black),
                            textColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#9B9B9B")),
                            borderColor: SVKColor(main: .white,
                                                  dark: .black),
                            borderWidth: CGFloat(0.0))
    }
    fileprivate static var defaultUserErrorBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white,
                                                      dark: .black),
                            textColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            flagColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                  dark: UIColor(hex: "#DDDDDD")),
                            borderWidth: CGFloat(2.5))
    }
    fileprivate static var defaultAssistantErrorBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                      dark: UIColor(hex: "#9B9B9B")),
                            textColor: SVKColor(main: .white,
                                                dark: UIColor(white: 1, alpha: 1)),
                            flagColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                  dark: UIColor(hex: "#DDDDDD")),
                            borderWidth: CGFloat(0.0))
    }
    fileprivate static var defaultRecoBubble: Self{
        SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white,
                                                      dark: .black),
                            textColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            flagColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                dark: UIColor(hex: "#DDDDDD")),
                            borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"),
                                                  dark: UIColor(hex: "#DDDDDD")),
                            borderWidth: CGFloat(2.5))
    }
}

public struct SVKCardAppearance: Decodable{
    public var backgroundColor: SVKColor
    public var textColor: SVKColor
    public var supplementaryTextColor: SVKColor
    public var cornerRadius: CGFloat
    public var borderColor: SVKColor
    
    public init(backgroundColor: SVKColor = SVKColor(main: UIColor(white: 1, alpha: 1), dark: .black),
                textColor: SVKColor = SVKColor(main: .black, dark: .whiteTwo),
                supplementaryTextColor: SVKColor = SVKColor(main: .greyishBrown, dark: .elegantGray),
                cornerRadius: CGFloat = 18,
                borderColor: SVKColor = SVKColor(main: .greyishBrown, dark: .whiteTwo)
                ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.supplementaryTextColor = supplementaryTextColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
    }
}

public struct SVKCardV3Appearance: Decodable {
    public var backgroundColor: SVKColor
    public var textColor: SVKColor
    public var supplementaryTextColor: SVKColor
    public var cornerRadius: CGFloat
    public var borderColor: SVKColor
    public var layout: SVKCardV3LayoutApperance
    public var isFullSizeCard: Bool
    public init(backgroundColor: SVKColor = SVKColor(main: UIColor(white: 1, alpha: 1), dark: .black),
                textColor: SVKColor = SVKColor(main: .black, dark: .whiteTwo),
                supplementaryTextColor: SVKColor = SVKColor(main: .greyishBrown, dark: .elegantGray),
                cornerRadius: CGFloat = 18,
                borderColor: SVKColor = SVKColor(main: .greyishBrown, dark: .whiteTwo),
                layout: SVKCardV3LayoutApperance = SVKCardV3LayoutApperance(spacing: SVKCardLayoutSpacing(horizontal: 16,
                                                                                                          vertical: 16),
                                                                            header: SVKCardLayoutHeaderApperance(text: SVKCardLayoutHeaderTextApperance(color: SVKColor(main: UIColor(hex: "#000000ff"),
                                                                                                                                                                        dark: UIColor(white: 1, alpha: 1)),
                                                                                                                                                        font: SVKFont(name: "HelveticaNeue-Bold",
                                                                                                                                                                      size: 16)),
                                                                                                                 subText: SVKCardLayoutHeaderSubTextApperance(color: SVKColor(main: UIColor(hex: "#f16e00ff"),
                                                                                                                                                                              dark: UIColor(hex: "#f16e00ff")),
                                                                                                                                                              font: SVKFont(name: "HelveticaNeue",
                                                                                                                                                                            size: 12)),
                                                                                                                 image: SVKCardLayoutHeaderImageApperance(size: SVKSize(width: 36, height: 36),
                                                                                                                                                          tintColor: SVKColor(main: UIColor(hex: "#000000"),
                                                                                                                                                                              dark: UIColor(hex: "#EEEEEE")))),
                                                                            cardImage: SVKCardImageLayoutApperance(height: 140),
                                                                            text: SVKCardLayoutTextApperance(color: SVKColor(main: UIColor(hex: "#000000ff"),
                                                                                                                                  dark: UIColor(white: 1, alpha: 1)),
                                                                                                                  font: SVKFont(name: "HelveticaNeue-Bold",
                                                                                                                                size: 14)),
                                                                            subText: SVKCardLayoutSubTextAppearance(color: SVKColor(main: UIColor(hex: "#9e9e9e"),
                                                                                                                                    dark: UIColor(hex: "#cfcfcf")),
                                                                                                                    font: SVKFont(name: "HelveticaNeue",
                                                                                                                                  size: 14)),
                                                                            prominentText: SVKCardLayoutProminentTextApperance(color: SVKColor(main: UIColor(hex: "#FF7900"),
                                                                                                                                               dark: UIColor(hex: "#F16E00")),
                                                                                                                               font: SVKFont(name: "HelveticaNeue-Bold",
                                                                                                                                             size: 26),
                                                                                                                               actionForegroundColor: SVKColor(main: UIColor(hex: "#00739f"),
                                                                                                                                                               dark: UIColor(hex: "#31c2f7"))),
                                                                            itemList: SVKCardLayoutItemListAppearance()),
                isFullSizeCard:Bool = false) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.supplementaryTextColor = supplementaryTextColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.layout = layout
        self.isFullSizeCard = isFullSizeCard
    }
}

public struct SVKCardV3LayoutApperance: Decodable {

    public var spacing: SVKCardLayoutSpacing
    public var header: SVKCardLayoutHeaderApperance
    public var cardImage: SVKCardImageLayoutApperance
    public var text: SVKCardLayoutTextApperance
    public var subText: SVKCardLayoutSubTextAppearance
    public var prominentText: SVKCardLayoutProminentTextApperance
    public var itemList: SVKCardLayoutItemListAppearance

    public init(spacing: SVKCardLayoutSpacing,
                header: SVKCardLayoutHeaderApperance,
                cardImage: SVKCardImageLayoutApperance,
                text: SVKCardLayoutTextApperance,
                subText: SVKCardLayoutSubTextAppearance,
                prominentText: SVKCardLayoutProminentTextApperance,
                itemList: SVKCardLayoutItemListAppearance) {
        self.spacing = spacing
        self.header = header
        self.cardImage = cardImage
        self.text = text
        self.subText = subText
        self.prominentText = prominentText
        self.itemList = itemList
    }
}

public struct SVKCardLayoutSpacing: Decodable {

    public var horizontal: CGFloat
    public var vertical: CGFloat

    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

}

public struct SVKCardLayoutHeaderApperance: Decodable {

    public var text: SVKCardLayoutHeaderTextApperance
    public var subText: SVKCardLayoutHeaderSubTextApperance
    public var image: SVKCardLayoutHeaderImageApperance

    public init(text: SVKCardLayoutHeaderTextApperance, subText: SVKCardLayoutHeaderSubTextApperance, image: SVKCardLayoutHeaderImageApperance) {
        self.text = text
        self.subText = subText
        self.image = image
    }
}

public struct SVKCardLayoutHeaderTextApperance: Decodable {

    public var color: SVKColor
    public var font: SVKFont

    public init(color: SVKColor, font: SVKFont) {
        self.color = color
        self.font = font
    }
    
}

public struct SVKCardLayoutHeaderSubTextApperance: Decodable {
    
    public var color: SVKColor
    public var font: SVKFont

    public init(color: SVKColor, font: SVKFont) {
        self.color = color
        self.font = font
    }
}

public struct SVKCardLayoutHeaderImageApperance: Decodable {

    public var size: SVKSize
    public var tintColor: SVKColor

    public init(size: SVKSize, tintColor: SVKColor) {
        self.size = size
        self.tintColor = tintColor
    }
}

public struct SVKSize: Decodable {
    
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

public struct SVKCardImageLayoutApperance: Decodable {
    public var height: CGFloat

    public init(height: CGFloat) {
        self.height = height
    }
}

public struct SVKCardLayoutTextApperance: Decodable {

    public var color: SVKColor
    public var font: SVKFont

    public init(color: SVKColor, font: SVKFont) {
        self.color = color
        self.font = font
    }
}

public struct SVKCardLayoutSubTextAppearance: Decodable {

    public var color: SVKColor
    public var font: SVKFont

    public init(color: SVKColor, font: SVKFont) {
        self.color = color
        self.font = font
    }
}

public struct SVKCardLayoutProminentTextApperance: Decodable {

    public var color: SVKColor
    public var font: SVKFont
    public var actionForegroundColor: SVKColor


    public init(color: SVKColor,
                font: SVKFont,
                actionForegroundColor: SVKColor) {
        self.color = color
        self.font = font
        self.actionForegroundColor = actionForegroundColor
    }
}


public struct SVKAudioProgressViewApperance: Decodable {

    public var thumbImage: SVKImageDescription
    public var minimumTrackTintColor: SVKColor
    public var maximumTrackTintColor: SVKColor
    public var elapsedTimeColor: SVKColor
    public var durationTimeColor: SVKColor

    public init(thumbImage: SVKImageDescription = SVKImageDescription(main: "knob"),
                minimumTrackTintColor: SVKColor = SVKColor(main: UIColor(hex: "#f16e00")),
                maximumTrackTintColor: SVKColor = SVKColor(main: UIColor(hex: "#e4e4e6")),
                elapsedTimeColor: SVKColor = SVKColor(main: UIColor(hex: "#f16e00")),
                durationTimeColor: SVKColor = SVKColor(main: UIColor(hex: "#9e9e9e"))) {
        self.thumbImage = thumbImage
        self.minimumTrackTintColor = minimumTrackTintColor
        self.maximumTrackTintColor = maximumTrackTintColor
        self.elapsedTimeColor = elapsedTimeColor
        self.durationTimeColor = durationTimeColor
    }
}

public struct SVKCardLayoutItemListAppearance: Decodable {
    public var title: SVKCardItemListTitleAppearance
    public var itemText: SVKCardItemListItemAppearance
    public var image: SVKCardItemListImageApperance
    public var spacing: SVKCardItemListSpacingAppearance

    public init(title: SVKCardItemListTitleAppearance = SVKCardItemListTitleAppearance(),
                itemText: SVKCardItemListItemAppearance = SVKCardItemListItemAppearance(),
                image: SVKCardItemListImageApperance = SVKCardItemListImageApperance(),
                spacing: SVKCardItemListSpacingAppearance = SVKCardItemListSpacingAppearance()) {
        self.title = title
        self.itemText = itemText
        self.image = image
        self.spacing = spacing
    }
}

public struct SVKCardItemListSpacingAppearance: Decodable {

    /// Space between 2 list secions
    public var section: CGFloat
    
    /// Space between title and item in section
    public var title: CGFloat
    
    /// Space between 2 items in section
    public var item: CGFloat

    public init(section: CGFloat = 22, title: CGFloat = 18, item: CGFloat = 18) {
        self.section = section
        self.title = title
        self.item = item
    }
}

public struct SVKCardItemListImageApperance: Decodable {

    public var size: SVKSize

    public init(size: SVKSize = SVKSize(width: 24, height: 20)) {
        self.size = size
    }
}

public struct SVKCardItemListTitleAppearance: Decodable {
    public var color: SVKColor
    public var font: SVKFont

    public init(color: SVKColor = SVKColor(main: UIColor(hex: "#000000"),
                                           dark: UIColor(hex: "#ffffff")),
                font: SVKFont = SVKFont(name: "HelveticaNeue-Bold",
                                        size: 18)) {
        self.color = color
        self.font = font
    }
}

public struct SVKCardItemListItemAppearance: Decodable {

    public var color: SVKColor
    public var font: SVKFont
    public var actionForegroundColor: SVKColor

    public init(color: SVKColor = SVKColor(main: UIColor(hex: "#595959"),
                                           dark: UIColor(hex: "#ffffff")),
                font: SVKFont = SVKFont(name: "HelveticaNeue",
                                        size: 14),
                actionForegroundColor: SVKColor = SVKColor(main: UIColor(hex: "#ff7900"),
                                                           dark: UIColor(hex: "#f16e00"))) {
        self.color = color
        self.font = font
        self.actionForegroundColor = actionForegroundColor
    }
}

public struct SVKFeatures: Decodable {
    public var actions: SVKFeaturesActions
    
    public init(actions: SVKFeaturesActions = SVKFeaturesActions()) {
        self.actions = actions
    }
}

public struct SVKFilterViewStyle: Decodable {

    public var cornerRadius: CGFloat
    public var borderWidth: CGFloat
    public var borderColor: SVKColor
    public var font: SVKFont
    public var backgroundColor: SVKColor

    public init(cornerRadius: CGFloat = 5.0,
                borderWidth: CGFloat = 1.0,
                borderColor: SVKColor = SVKColor(main: UIColor(hex: "#6b6b6b"), dark:  UIColor(hex: "#b2b2b2")),
                font: SVKFont = SVKFont(name: "HelveticaNeue", size: 15),
                backgroundColor: SVKColor = SVKColor(main: UIColor(white: 1, alpha: 1), dark: .black)) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.font = font
        self.backgroundColor = backgroundColor
    }
}

public struct SVKToolBarStyle: Decodable {

    public var tintColor: SVKColor
    public var font: SVKFont
    public var backgroundColor: SVKColor

    public init(tintColor: SVKColor = SVKColor(main: UIColor(hex: "#007bff"), dark: UIColor(hex: "#007bff")),
                font: SVKFont = SVKFont(name: "HelveticaNeue-Medium", size: 14),
                backgroundColor: SVKColor = SVKColor(main: UIColor(hex: "#d0d0d0B3"), dark: UIColor(hex: "#000000B3"))) {
        self.tintColor = tintColor
        self.font = font
        self.backgroundColor = backgroundColor
    }
}


public struct SVKFeaturesActions: Decodable {
    public var useShare: Bool
    public var usePlay: Bool
    public var useDelete: Bool
    public var useMisunderstood: Bool
    public var useResend: Bool
    
    public init(useShare: Bool = true, usePlay: Bool = true, useDelete: Bool = true, useMisunderstood: Bool = true, useResend: Bool = true) {
        self.useShare = useShare
        self.usePlay = usePlay
        self.useDelete = useDelete
        self.useMisunderstood = useMisunderstood
        self.useResend = useResend
    }
}

public struct SVKAppearance {
    public var userInterfaceStyle: Set<SVKInterfaceStyle>
    public var backgroundColor: SVKColor
    public var audioInputColor: SVKColor
    public var audioInputAnimationTorusColor: SVKColor
    public var audioInputAnimationBackgroundColor: SVKColor
    public var tintColor: SVKColor
    public var showTrustBadge: Bool = true
    public var feedbackPageTextAlignment: SVKTextAlignment? = .left
    public var features: SVKFeatures = SVKFeatures()
    public var buttonStyle: SVKButtonAppearance{
        didSet{
            SVKAppearance.updateCustomButtonAppearance(style: buttonStyle)
        }
    }
    public var filterButtonStyle: SVKButtonAppearance{
        didSet{
            SVKAppearance.updateFilterButtonAppearance(style: filterButtonStyle)
        }
    }
    
    public var filterViewStyle: SVKFilterViewStyle
    public var toolBarStyle: SVKToolBarStyle

    public var font: SVKFont?{
        didSet{
            guard let svkFont = font else { return }
            SVKAppearance.updateButtonsFont(svkFont: svkFont)
        }
    }
    public var fontHeaderTitle: SVKFont?{
        didSet{
            updateFonts()
        }
    }
    
    public var fontBlocTitle: SVKFont?{
        didSet{
            updateFonts()
        }
    }
    public var fontBlocDescription: SVKFont?{
        didSet{
            updateFonts()
        }
    }
    public var fontBlocActionTitle: SVKFont?{
        didSet{
            updateFonts()
        }
    }
    public var fontBlocButton: SVKFont?{
        didSet{
            updateFonts()
        }
    }
    private func updateFonts() {
        if let svkFont = fontHeaderTitle {
            SVKHeaderTitleLabel.appearance().font = svkFont.font
        }
        if let svkFont = fontBlocTitle {
            SVKBlocTitleLabel.appearance().font = svkFont.font
        }
        if let svkFont = fontBlocDescription {
            SVKBlocDescriptionLabel.appearance().font = svkFont.font
        }
        if let svkFont = fontBlocActionTitle {
            SVKBlocDescriptionLabel.appearance().font = svkFont.font
        }
        if let svkFont = fontBlocButton {
            SVKBlocButton.appearance().titleLabel?.font = svkFont.font
        }
        
    }
    
    private func updateStandardPageStyle() {
        SVKStandardPageMessageTitle.appearance().font = self.standardPageStyle.messageTitleFont.font
        SVKStandardPageMessageTitle.appearance().textColor = self.standardPageStyle.messageTitleColor.getColor(userInterfaceStyle)
        SVKStandardPageMessageTitle.appearance().textAlignment = self.standardPageStyle.textAlignment.nsTextAlignment
        
        SVKStandardPageMessageDescription.appearance().font = self.standardPageStyle.messageDescriptionFont.font
        SVKStandardPageMessageDescription.appearance().textColor = self.standardPageStyle.messageDescriptionColor.getColor(userInterfaceStyle)
        SVKStandardPageMessageDescription.appearance().textAlignment = self.standardPageStyle.textAlignment.nsTextAlignment
        
        SVKStandardPageBulletMessageDescription.appearance().font = self.standardPageStyle.messageDescriptionFont.font
        SVKStandardPageBulletMessageDescription.appearance().textColor = self.standardPageStyle.messageDescriptionColor.getColor(userInterfaceStyle)
        SVKStandardPageBulletMessageDescription.appearance().textAlignment = self.standardPageStyle.bulletTextAlignment.nsTextAlignment
        
        SVKStandardPageMainView.appearance().backgroundColor = self.standardPageStyle.backgroundColor.getColor(userInterfaceStyle)
        SVKStandardPageButtonView.appearance().backgroundColor = self.standardPageStyle.buttonZoneBackgroundColor.getColor(userInterfaceStyle)
    }
    
    public var assistantBubbleStyle: SVKBubbleAppearanceSettings
    public var userBubbleStyle: SVKBubbleAppearanceSettings
    public var headerExpandedErrorBubbleStyle: SVKBubbleAppearanceSettings
    public var headerCollapsedErrorBubbleStyle: SVKBubbleAppearanceSettings
    public var userErrorBubbleStyle: SVKBubbleAppearanceSettings
    public var assistantErrorBubbleStyle: SVKBubbleAppearanceSettings
    public var recoBubbleStyle: SVKBubbleAppearanceSettings
    public var cardStyle: SVKCardAppearance
    public var cardV3Style: SVKCardV3Appearance
    public var assets: SVKImageProvider?
    public var tableStyle: SVKTableAppearance
    public var audioProgressView: SVKAudioProgressViewApperance
    public var standardPageStyle: SVKStandardPageAppearance {
        didSet {
            // Set the appearance
            updateStandardPageStyle()
        }
    }
    
    public var toastStyle: SVKToastAppearance {
        didSet{
            Self.updateToast(style: toastStyle)
        }
    }
    
    public var horizontalAlignment: SVKHorizontalAppearance
    
    public init(){
        self.userInterfaceStyle = [.main,.dark]
        self.backgroundColor = SVKColor(main: .white, dark: .black)
        self.audioInputColor = SVKColor(main: .orange, dark: .white)
        audioInputAnimationTorusColor = SVKColor(main: .white, dark: .black)
        audioInputAnimationBackgroundColor = SVKColor(main: .white, dark: .black)
        self.tintColor = SVKColor(main: .black, dark: .white)
        self.buttonStyle = SVKAppearance.defaultButtonStyle
        self.filterButtonStyle = SVKAppearance.defaultButtonStyle
        self.font = SVKFont(name: "systembold", size: 15)
        self.fontHeaderTitle = SVKFont(name: "Helvetica Neue", size: 18)
        self.fontBlocTitle = SVKFont(name: "Helvetica Neue Bold", size: 16)
        self.fontBlocDescription = SVKFont(name: "Helvetica Neue", size: 14)
        self.fontBlocActionTitle = SVKFont(name: "Helvetica Neue", size: 16)
        self.fontBlocButton = SVKFont(name: "Helvetica Neue", size: 16)
        self.assistantBubbleStyle = SVKBubbleAppearanceSettings()
        self.userBubbleStyle = SVKBubbleAppearanceSettings.defaultUserBubble
        self.headerExpandedErrorBubbleStyle = SVKBubbleAppearanceSettings.defaultHeaderExpandedErrorBubble
        self.headerCollapsedErrorBubbleStyle = SVKBubbleAppearanceSettings.defaultHeaderCollapsedErrorBubble
        self.userErrorBubbleStyle = SVKBubbleAppearanceSettings.defaultUserErrorBubble
        self.assistantErrorBubbleStyle = SVKBubbleAppearanceSettings.defaultAssistantErrorBubble
        self.recoBubbleStyle = SVKBubbleAppearanceSettings.defaultRecoBubble
        self.cardStyle = SVKCardAppearance()
        self.cardV3Style = SVKCardV3Appearance()
        self.assets = SVKImageProvider()
        self.tableStyle = SVKAppearance.defaultTableStyle
        self.standardPageStyle = SVKAppearance.defaultstandardPageStyle
        self.toastStyle = SVKToastAppearance.defaultToast
        self.audioProgressView = SVKAudioProgressViewApperance()
        self.horizontalAlignment = SVKHorizontalAppearance()
        self.filterViewStyle = SVKFilterViewStyle()
        self.toolBarStyle = SVKToolBarStyle()
        updateFonts()
        updateStandardPageStyle()
    }
    
    public init(with fileName: String) {
        self.init()
        do {
            let json = try load(jsonFile: fileName)
            
            let decoder = JSONDecoder()
            let appearance = try decoder.decode(SVKAppearance.self, from: json)
            
            self.userInterfaceStyle = appearance.userInterfaceStyle
            self.backgroundColor = appearance.backgroundColor
            self.audioInputColor = appearance.audioInputColor
            self.audioInputAnimationBackgroundColor = appearance.audioInputAnimationBackgroundColor
            self.audioInputAnimationTorusColor = appearance.audioInputAnimationTorusColor
            self.tintColor = appearance.tintColor
            self.buttonStyle = appearance.buttonStyle
            self.filterButtonStyle = appearance.filterButtonStyle
            Self.updateCustomButtonAppearance(style: buttonStyle)
            Self.updateFilterButtonAppearance(style: filterButtonStyle)
            self.showTrustBadge = appearance.showTrustBadge
            if let feedbckPageTextAlignement = appearance.feedbackPageTextAlignment{
                self.feedbackPageTextAlignment = feedbckPageTextAlignement
            }
            let _font: SVKFont = appearance.font ?? SVKFont(name: "systembold", size: 15)
            self.font = _font
            let _fontHeaderTitle: SVKFont? = appearance.fontHeaderTitle ?? self.fontHeaderTitle
            self.fontHeaderTitle = _fontHeaderTitle
            let _fontBlocTitle: SVKFont? = appearance.fontBlocTitle ?? self.fontBlocTitle
            self.fontBlocTitle = _fontBlocTitle
            let _fontBlocDescription: SVKFont? = appearance.fontBlocDescription ?? self.fontBlocDescription
            self.fontBlocDescription = _fontBlocDescription
            let _fontBlocActionTitle: SVKFont? = appearance.fontBlocActionTitle ?? self.fontBlocActionTitle
            self.fontBlocActionTitle = _fontBlocActionTitle
            let _fontBlocButton: SVKFont? = appearance.fontBlocButton ?? self.fontBlocButton
            self.fontBlocButton = _fontBlocButton
            Self.updateButtonsFont(svkFont: _font)
            self.assistantBubbleStyle = appearance.assistantBubbleStyle
            self.userBubbleStyle = appearance.userBubbleStyle
            self.headerCollapsedErrorBubbleStyle = appearance.headerCollapsedErrorBubbleStyle
            self.headerExpandedErrorBubbleStyle = appearance.headerExpandedErrorBubbleStyle
            self.userErrorBubbleStyle = appearance.userErrorBubbleStyle
            self.assistantErrorBubbleStyle = appearance.assistantErrorBubbleStyle
            self.recoBubbleStyle = appearance.recoBubbleStyle
            self.cardStyle = appearance.cardStyle
            self.cardV3Style = appearance.cardV3Style
            self.audioProgressView = appearance.audioProgressView
            self.assets = appearance.assets
            self.tableStyle = appearance.tableStyle
            self.standardPageStyle = appearance.standardPageStyle
            self.features = appearance.features
            self.toastStyle = appearance.toastStyle
            self.horizontalAlignment = appearance.horizontalAlignment
            self.filterViewStyle = appearance.filterViewStyle
            self.toolBarStyle = appearance.toolBarStyle
            Self.updateToast(style: toastStyle)
            updateFonts()
            updateStandardPageStyle()
            //            appearance.checkConfiguration()
        } catch SVKFlavorError.missingConfigurationFile {
            fatalError("[🔥] Please, verify your appearance configuration file path")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("[🔥] dataCorrupted error: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("[🔥] \(key.stringValue) was not found, \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            fatalError("[🔥] \(type) was expected, \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("[🔥] no value was found for \(type), \(context.debugDescription)")
        }catch let unknownError{
            fatalError("[🔥] Unknown error: \(unknownError.localizedDescription)")
        }
    }
    
    /// Verification of right SVKAppearance configuration
    public func checkConfiguration(){
        
        // 1. verify that userInterfaceStyle is not empty
        assert(!userInterfaceStyle.isEmpty, "[🔥] userInterfaceStyle should not be empty. Possible values are .main, .dark. Please, set it with at least one value, i.e. [.main]")
        
        // 2. verify background color settings for dark mode
        checkDarkColorConfiguration(backgroundColor,
                                    errorMessage: generateMessage(for: "backgroundColor"))
        
        // 3. verify audio input color settings for dark mode
        checkDarkColorConfiguration(audioInputColor,
                                    errorMessage: generateMessage(for: "audioInputColor"))
        
        // 3a. verify audio input's animation torus color settings for dark mode
        checkDarkColorConfiguration(audioInputAnimationTorusColor,
                                    errorMessage: generateMessage(for: "audioInputAnimationTorusColor"))
        
        // 3b. verify audio input's animation background color settings for dark mode
        checkDarkColorConfiguration(audioInputAnimationBackgroundColor,
                                    errorMessage: generateMessage(for: "audioInputAnimationBackgroundColor"))
        // 4. verify fill color settings for dark mode in default state
        checkDarkColorConfiguration(buttonStyle.defaultState.fillColor,
                                    errorMessage: generateMessage(for: "button default state's fillColor"))
        
        // 5. verify fill color settings for dark mode in highlighted state
        checkDarkColorConfiguration(buttonStyle.highlightedState.fillColor,
                                    errorMessage: generateMessage(for: "button highlighted state's fillColor"))
        
        // 6. verify shape color settings for dark mode in default state
        checkDarkColorConfiguration(buttonStyle.defaultState.shapeColor,
                                    errorMessage: generateMessage(for: "button defaultState state's shapeColor"))
        
        // 7. verify shape color settings for dark mode in highlighted state
        checkDarkColorConfiguration(buttonStyle.highlightedState.shapeColor,
                                    errorMessage: generateMessage(for: "button highlighted state's shapeColor"))
        
        // 8. verify fill color settings for dark mode in default state
        checkDarkColorConfiguration(filterButtonStyle.defaultState.fillColor,
                                    errorMessage: generateMessage(for: "filter button default state's fillColor"))
        
        // 9. verify fill color settings for dark mode in highlighted state
        checkDarkColorConfiguration(filterButtonStyle.highlightedState.fillColor,
                                    errorMessage: generateMessage(for: "filter button highlighted state's fillColor"))
        
        // 10. verify shape color settings for dark mode in default state
        checkDarkColorConfiguration(filterButtonStyle.defaultState.shapeColor,
                                    errorMessage: generateMessage(for: "filter button defaultState state's shapeColor"))
        
        // 11. verify shape color settings for dark mode in highlighted state
        checkDarkColorConfiguration(filterButtonStyle.highlightedState.shapeColor,
                                    errorMessage: generateMessage(for: "filter button highlighted state's shapeColor"))
        // 12. verify tint color settings for dark mode
        checkDarkColorConfiguration(tintColor,
                                    errorMessage: generateMessage(for: "tintColor"))
        
    }
    

}

extension SVKAppearance{
    
    /// Verification of given color
    func checkDarkColorConfiguration(_ color:SVKColor, errorMessage: String){
        do {
            try color.checkConfiguration(userInterfaceStyle)
        } catch SVKFlavorError.missingDarkColor {
            fatalError(errorMessage)
        } catch {
            fatalError("the configuration is uncomplete")
        }
    }
    /// Helper method: create error message for given String in parameter
    func generateMessage(for missingDarkColor: String) -> String{
        let message =
        """
        [🔥] ->
        the \(missingDarkColor) is not configured for darkMode.
        
        Please, add this color to "SVKAppearance" or remove darkMode from
        "userInterfaceStyle" : [.main, .dark]
        \n
        """
        return message
    }
    /// defaut button's style used for empty initialization
    private static var defaultButtonStyle: SVKButtonAppearance{
        get{
            let bsdDefault = SVKButtonStyleDescription(fillColor: SVKColor(main: .white),
                                                       shapeColor: SVKColor(main: .white),
                                                       lineWidth: 0)
            
            let bsdHighlighted = SVKButtonStyleDescription(fillColor: SVKColor(main: .orange),
                                                           shapeColor: SVKColor(main: .orange),
                                                           lineWidth: 1)
            
            let bsdDisruptive = SVKButtonStyleDescription(fillColor: SVKColor(main: .orange),
                                                           shapeColor: SVKColor(main: .orange),
                                                           lineWidth: 1)
            
            let ba = SVKButtonAppearance(default: bsdDefault,
                                         highlighted: bsdHighlighted,
                                         disruptive: bsdDisruptive,
                                         cornerRadius: 16)
            
            
            return ba
        }
    }
    
    /// defaut button's style used for empty initialization
    private static var defaultTableStyle: SVKTableAppearance{
        get{
            let sectionBackgroundColor = SVKColor(main: UIColor(hex: "#F1F2F6"), dark: UIColor(hex: "#161616"))
            let sectionForegroundColor = SVKColor(main: UIColor(hex: "#6F7A73"), dark: UIColor(hex: "#6F7073"))
            let sectionSeparatorColor = SVKColor(main: UIColor(hex: "#F1F2F6"), dark: UIColor(hex: "#FFFFFF"))
            let sectionAppearance = SVKTableSectionAppearance(backgroundColor: sectionBackgroundColor, foregroundColor: sectionForegroundColor, separatorColor: sectionSeparatorColor)
            
            let cellBackgroundColor = SVKColor(main: UIColor(hex: "#FFFFFF"), dark: UIColor(hex: "#161616"))
            let cellForegroundMainColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(hex: "#FFFFFF"))
            let cellForegroundSecondColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(hex: "#FFFFFF"))
            let cellForegroundButtonColor = SVKColor(main: UIColor(hex: "#FF3B30"), dark: UIColor(hex: "#FF453A"))
            let cellSeparatorColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(hex: "#FFFFFF"))
            let cellActionForegroundColor = SVKColor(main: UIColor(hex: "#F16E00"), dark: UIColor(hex: "#F16E00"))
            let cellFooterSeparatorColor = SVKColor(main: UIColor(hex: "#F1F2F6"), dark: UIColor(hex: "#000000"))
            
            
            let cellAppearance = SVKTableCellAppearance(backgroundColor: cellBackgroundColor, foregroundMainColor: cellForegroundMainColor, foregroundSecondColor: cellForegroundSecondColor, foregroundButtonColor: cellForegroundButtonColor, separatorColor: cellSeparatorColor, actionForegroundColor: cellActionForegroundColor, footerSeparatorColor: cellFooterSeparatorColor)
            let tableAppearance = SVKTableAppearance(section: sectionAppearance, cell: cellAppearance)
            
            return tableAppearance
        }
    }
    
    private static var defaultstandardPageStyle: SVKStandardPageAppearance {
        get{
            let backgroundColor = SVKColor(main: UIColor(hex: "#FFFFFF"), dark: UIColor(hex: "#161616"))
            let messageTitleFont = SVKFont(name: "HelveticaNeue-Bold", size: 18)
            let messageTitleColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(hex: "#FFFFFF"))
            let messageDescriptionFont = SVKFont(name: "HelveticaNeue", size: 14)
            let messageDescriptionColor = SVKColor(main: UIColor(hex: "#000000"), dark: UIColor(hex: "#FFFFFF"))
            let buttonZoneBackgroundColor = SVKColor(main: UIColor(hex: "#FFFFFF"), dark: UIColor(hex: "#161616"))
            
            let standardPageAppearance = SVKStandardPageAppearance( backgroundColor :backgroundColor, messageTitleFont: messageTitleFont, messageTitleColor: messageTitleColor, messageDescriptionFont: messageDescriptionFont, messageDescriptionColor: messageDescriptionColor, textAlignment: .left,
                bulletTextAlignment: .left, useShadow: false, pageLeading: 16, pageTrailing: 16,
                buttonZoneBackgroundColor: buttonZoneBackgroundColor)
            
            return standardPageAppearance
        }
    }
    private static func updateToast(style: SVKToastAppearance){
        SVKActionLabel.appearance().font = style.actionTextFont.font
        SVKActionLabel.appearance().textColor = style.actionTextColor.color
        
        SVKMessageLabel.appearance().font = style.textFont.font
        SVKMessageLabel.appearance().textColor = style.textColor.color
    }
    
    /**
     Method to update **Custom button** with given `SVKButtonAppearance`.
     ~~~
     */
    private static func updateCustomButtonAppearance(style: SVKButtonAppearance){
        //configure custom state
        SVKCustomButton.appearance().layerBorderWidth = style.defaultState.lineWidth
        SVKCustomButton.appearance().layerCornerRadius = style.cornerRadius
        SVKCustomButton.appearance().shapeColor = style.defaultState.shapeColor.color
        SVKCustomButton.appearance().fillColor = style.defaultState.fillColor.color
        SVKCustomButton.appearance().highlightedFillColor = style.highlightedState.fillColor.color
        
        SVKCustomButtonHighlighted.appearance().layerBorderWidth = style.defaultState.lineWidth
        SVKCustomButtonHighlighted.appearance().layerCornerRadius = style.cornerRadius
        SVKCustomButtonHighlighted.appearance().shapeColor = style.disruptiveState.shapeColor.color
        SVKCustomButtonHighlighted.appearance().fillColor = style.disruptiveState.shapeColor.color
        SVKCustomButtonHighlighted.appearance().highlightedFillColor = style.disruptiveState.shapeColor.color
    
    }
    
    private static func updateFilterButtonAppearance(style: SVKButtonAppearance){
        //configure filter button in HistoryView
        // configure highlight state : for djingo it's full orange with white text | or full magenta color dt
        // so it reversed
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).layerBorderWidth = style.highlightedState.lineWidth
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).layerCornerRadius = style.cornerRadius
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).fillColor = style.highlightedState.fillColor.color
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).shapeColor = style.highlightedState.shapeColor.color
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).highlightedFillColor = style.highlightedState.fillColor.color
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).setTitleColor(style.defaultState.shapeColor.color,for: .highlighted)// highlighted color for filter full colored button
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).setTitleColor(style.defaultState.fillColor.color,for: .normal)
        
        // configure normal state
        
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).layerCornerRadius = style.cornerRadius
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).layerBorderWidth = style.defaultState.lineWidth
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).shapeColor = style.defaultState.shapeColor.color
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).highlightedFillColor = style.defaultState.shapeColor.color
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).setTitleColor(style.defaultState.shapeColor.color,for: .normal)
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).setTitleColor(style.defaultState.fillColor.color,for: .highlighted)
    }
    private static func updateButtonsFont(svkFont: SVKFont){
        SVKFilterFullButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).titleLabelFont = svkFont.font
        SVKCustomButton.appearance().titleLabelFont = svkFont.font
        SVKCustomButton.appearance(whenContainedInInstancesOf: [ SVKFilterHeaderView.self]).titleLabelFont = svkFont.font
    }
    
    private static func createSVKSkillAppearance(userBubblestyle: SVKBubbleAppearanceSettings,
                                                assistantBubblestyle: SVKBubbleAppearanceSettings,
                                                headerCollapsedErrorBubbleStyle: SVKBubbleAppearanceSettings,
                                                headerExpandedErrorBubbleStyle: SVKBubbleAppearanceSettings,
                                                userErrorBubbleStyle: SVKBubbleAppearanceSettings,
                                                assistantErrorBubbleStyle: SVKBubbleAppearanceSettings,
                                                recoBubbleStyle: SVKBubbleAppearanceSettings,
                                                font: SVKFont) -> SDKSkillAppearance{
        let assistantBubbleColors = SVKBubbleAppearance(foregroundColor: assistantBubblestyle.backgroundColor.color,
                                                 flagColor: assistantBubblestyle.flagColor.color,
                                                 textColor: assistantBubblestyle.textColor.color,
                                                 cornerRadius: assistantBubblestyle.cornerRadius,
                                                 font: font.font,
                                                 pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.left) : .default,
                                                 contentInset: assistantBubblestyle.contentInset)
        
        var userBubbleColors = SVKBubbleAppearance(foregroundColor: userBubblestyle.backgroundColor.color,
                                                  flagColor: userBubblestyle.flagColor.color,
                                                  textColor: userBubblestyle.textColor.color,
                                                  cornerRadius: userBubblestyle.cornerRadius,
                                                  borderWidth:  userBubblestyle.borderWidth,
                                                  borderColor: userBubblestyle.borderColor.color,
                                                  font: font.font,
                                                  pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                  contentInset: userBubblestyle.contentInset)
        var userErrorBubbleColors = SVKBubbleAppearance(foregroundColor: userErrorBubbleStyle.backgroundColor.color,
                                                       flagColor: userErrorBubbleStyle.flagColor.color,
                                                       textColor: userErrorBubbleStyle.textColor.color,
                                                       cornerRadius: userErrorBubbleStyle.cornerRadius,
                                                       borderWidth:  userErrorBubbleStyle.borderWidth,
                                                       borderColor: userErrorBubbleStyle.borderColor.color,
                                                       font: font.font,
                                                       pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                       contentInset: userErrorBubbleStyle.contentInset)
        let headerExpandedErrorBubbleColors = SVKBubbleAppearance(foregroundColor: headerExpandedErrorBubbleStyle.backgroundColor.color,
                                                                 flagColor: headerExpandedErrorBubbleStyle.flagColor.color,
                                                                 textColor: headerExpandedErrorBubbleStyle.textColor.color,
                                                                 cornerRadius: headerExpandedErrorBubbleStyle.cornerRadius,
                                                                 borderWidth:  headerExpandedErrorBubbleStyle.borderWidth,
                                                                 borderColor: headerExpandedErrorBubbleStyle.borderColor.color,
                                                                 font: font.font,
                                                                 pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                                 contentInset: headerExpandedErrorBubbleStyle.contentInset)
        
        let headerCollapedErrorBubbleColors = SVKBubbleAppearance(foregroundColor: headerCollapsedErrorBubbleStyle.backgroundColor.color,
                                                                 flagColor: headerCollapsedErrorBubbleStyle.flagColor.color,
                                                                 textColor: headerCollapsedErrorBubbleStyle.textColor.color,
                                                                 cornerRadius: headerCollapsedErrorBubbleStyle.cornerRadius,
                                                                 borderWidth:  headerCollapsedErrorBubbleStyle.borderWidth,
                                                                 borderColor: headerCollapsedErrorBubbleStyle.borderColor.color,
                                                                 font: font.font,
                                                                 pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                                 contentInset: headerCollapsedErrorBubbleStyle.contentInset)
        
        var assistantErrorBubbleColors = SVKBubbleAppearance(foregroundColor: assistantErrorBubbleStyle.backgroundColor.color,
                                                      flagColor: assistantErrorBubbleStyle.flagColor.color,
                                                      textColor: assistantErrorBubbleStyle.textColor.color,
                                                      cornerRadius: assistantErrorBubbleStyle.cornerRadius,
                                                      borderWidth:  assistantErrorBubbleStyle.borderWidth,
                                                      borderColor: assistantErrorBubbleStyle.borderColor.color,
                                                      font: font.font,
                                                      pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                      contentInset: assistantErrorBubbleStyle.contentInset)
        var recoBubbleColors = SVKBubbleAppearance(foregroundColor: recoBubbleStyle.backgroundColor.color,
                                                    flagColor: recoBubbleStyle.flagColor.color,
                                                    textColor: recoBubbleStyle.textColor.color,
                                                    cornerRadius: recoBubbleStyle.cornerRadius,
                                                    borderWidth:  recoBubbleStyle.borderWidth,
                                                    borderColor: recoBubbleStyle.borderColor.color,
                                                    font: font.font,
                                                    pinStyle: assistantBubblestyle.category == .magenta ? .pinStyle1(.right) : .default,
                                                    contentInset: recoBubbleStyle.contentInset)
        userBubbleColors.isCheckmarkEnabled = userBubblestyle.category == .djingo ? true : false
        userErrorBubbleColors.isCheckmarkEnabled = false
        assistantErrorBubbleColors.isCheckmarkEnabled = false
        recoBubbleColors.isCheckmarkEnabled = false
        
        var skillAppearance = SDKSkillAppearance(assistantBubbleAppearance: assistantBubbleColors, userBubbleAppearance: userBubbleColors,headerErrorCollapsedBubbleAppearance: headerCollapedErrorBubbleColors, headerErrorExpandedBubbleAppearance: headerExpandedErrorBubbleColors, userErrorBubbleAppearance: userErrorBubbleColors, assistantErrorBubbleAppearance: assistantErrorBubbleColors, recoBubbleAppearance: recoBubbleColors, avatarURL: nil)
        skillAppearance.avatarImage = userBubblestyle.category == .djingo ? SVKTools.imageWithName("djingo-avatar") : nil
        
        return skillAppearance
    }
    
    func load(jsonFile: String) throws -> Data{
        let bundle: Bundle = .main
        guard let url = bundle.url(forResource: jsonFile,
                                   withExtension: "json") else {
                                    throw SVKFlavorError.missingConfigurationFile
        }
        
        let data = try Data(contentsOf: url)
        
        return data
    }
}
extension SVKAppearance{
    /// calculated properties
    var SVKSkillAppearanceWrapper: SDKSkillAppearance{
        return Self.createSVKSkillAppearance(userBubblestyle: userBubbleStyle,
                                            assistantBubblestyle: assistantBubbleStyle,
                                            headerCollapsedErrorBubbleStyle: headerCollapsedErrorBubbleStyle,
                                            headerExpandedErrorBubbleStyle: headerExpandedErrorBubbleStyle,
                                            userErrorBubbleStyle: userErrorBubbleStyle,
                                            assistantErrorBubbleStyle: assistantErrorBubbleStyle,
                                            recoBubbleStyle: recoBubbleStyle,
                                            font: font ?? SVKFont(name: "systembold", size: 15))
        
    }
}
extension SVKAppearance: Decodable{}
/**
 A class singleton holding the instance of the appearance of the whole
 `SVK` module
 
 - Usage:
 ~~~
 // to read:
 let backgroundColor: UIColor = SVKAppearanceBox
 .shared
 .appearance
 .backgroundColor
 .color
 
 // to write:
 SVKAppearanceBox.shared.appearance = myImpOfSVKAppearance
 ~~~
 */
public class SVKAppearanceBox {
    
    /// The shared singleton object.
    public static let shared = SVKAppearanceBox()
    
    private init() {}
    /// The default svk appearance settings implementaion
    public var appearance: SVKAppearance = SVKAppearance()
    
}

/// Quick access variables
extension SVKAppearanceBox{
    // getter
    public static var cardTextColor: UIColor {
        SVKAppearanceBox.shared.appearance.cardStyle.textColor.color
    }
    
    public static var cardSupplementaryTextColor: UIColor {
        SVKAppearanceBox.shared.appearance.cardStyle.supplementaryTextColor.color
    }
    
    public static var cardCornerRadius: CGFloat {
        SVKAppearanceBox.shared.appearance.cardStyle.cornerRadius
    }
    
    public static var cardBorderColor: UIColor {
        SVKAppearanceBox.shared.appearance.cardStyle.borderColor.color
    }
    
    public static var cardBackgroundColor: UIColor {
        SVKAppearanceBox.shared.appearance.cardStyle.backgroundColor.color
    }
    
    public static var typingTextColor: UIColor {
        SVKAppearanceBox.shared.appearance.userBubbleStyle.typingTextColor.color
    }

    public static var progressViewThumbImage: UIImage? {
        UIImage.dynamicImage(from: SVKAppearanceBox.shared.appearance.audioProgressView.thumbImage,
                             usingDefault: "oval")
    }

    public struct Assets {
        public static var radioButtonOn: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.radioButtonOn
        }
        
        public static var radioButtonOff: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.radioButtonOff
        }
        public static var checkBoxOff: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.checkBoxOff
        }
        public static var checkboxOn: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.checkBoxOn
        }
        
        // long press
        public static var longPressCopy: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressCopy
        }
        public static var longPressShare: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressShare
        }
        public static var longPressPlay: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressPlay
        }
        public static var longPressDelete: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressDelete
        }
        public static var longPressMisunderstood: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressMisunderstood
        }
        public static var longPressResend: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.longPressResend
        }
        
        //swipe
        public static var swipeShare: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipeShare
        }
        public static var swipeCopy: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipeCopy
        }
        public static var swipePlay: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipePlay
        }
        public static var swipeDelete: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipeDelete
        }
        public static var swipeMisunderstood: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipeMisunderstood
        }
        public static var swipeResend: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.swipeResend
        }
        
        // flag
        public static var flag: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.flag
        }
        
        public static var audioRecOn: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.audioRecOn
        }
        
        public static var audioRecordingImageSize: CGFloat? {
            if let size = SVKAppearanceBox.shared.appearance.assets?.audioRecordingImageSideSize {
                return CGFloat(size)
            } else {
                return nil
            }
        }
        public static var audioRecOff: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.audioRecOff
        }
        
        public static var animatedImages : [UIImage]? {
            /// there is bug with traitCollection when pass images in an array, so my fix is here
            return SVKAppearanceBox.shared.appearance.assets?.animatedImages?.compactMap { img -> UIImage? in
                return img.dynamicAsset
            }
        }
        
        public static var audioRecHighlighted: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.audioRecHighlighted
        }
        public static var recSide: CGFloat? {
            SVKAppearanceBox.shared.appearance.assets?.audioRecordingImageSideSize
        }
        
        public static var emptyScreen: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.emptyScreen
        }
        
        public static var networkErrorScreen: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.networkErrorScreen
        }
        
        public static var tableCellActionIcon: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.tableCellActionIcon
        }
        
        public static var consentScreen: UIImage? {
            SVKAppearanceBox.shared.appearance.assets?.consentScreen
        }
    }
    
    public struct TextAlignement {
        public static var feedbackPage: NSTextAlignment {
            guard let alignement = SVKAppearanceBox.shared.appearance.feedbackPageTextAlignment else {
                return .left
            }
            return alignement.nsTextAlignment
        }
    }
    public struct Toast {
        public static var backgroundColor: UIColor {
            SVKAppearanceBox.shared.appearance.toastStyle.backgroundColor.color
        }
        public static var textColor: UIColor {
            SVKAppearanceBox.shared.appearance.toastStyle.textColor.color
        }
        public static var actionColor: UIColor {
            SVKAppearanceBox.shared.appearance.toastStyle.actionTextColor.color
        }
        public static var iconDefault: UIImage? {
            SVKAppearanceBox.shared.appearance.toastStyle.defaultLogo
        }
        public static var iconNoWifi: UIImage? {
            SVKAppearanceBox.shared.appearance.toastStyle.networkingLogo
        }
        public static var iconConfirmation: UIImage? {
            SVKAppearanceBox.shared.appearance.toastStyle.confirmationLogo
        }
        public static var verticalSpacing: CGFloat {
            SVKAppearanceBox.shared.appearance.toastStyle.verticalPadding
        }
    }
    
    public struct HorizontalAlignment {
        public static var left: CGFloat {
            SVKAppearanceBox.shared.appearance.horizontalAlignment.left
        }
        public static var right: CGFloat {
            SVKAppearanceBox.shared.appearance.horizontalAlignment.right
        }
        public static var avatar: CGFloat {
            SVKAppearanceBox.shared.appearance.horizontalAlignment.avatar
        }
    }
    
    public struct FilterStyle {
        public static var borderColor: UIColor {
            SVKAppearanceBox.shared.appearance.filterViewStyle.borderColor.color
        }
        
        public static var borderWidth: CGFloat {
            SVKAppearanceBox.shared.appearance.filterViewStyle.borderWidth
        }
        
        public static var cornerRadius: CGFloat {
            SVKAppearanceBox.shared.appearance.filterViewStyle.cornerRadius
        }
        
        public static var backgroundColor: UIColor {
            SVKAppearanceBox.shared.appearance.filterViewStyle.backgroundColor.color
        }
    }
    
    public struct ToolBarStyle {
        public static var tintColor: UIColor {
            SVKAppearanceBox.shared.appearance.toolBarStyle.tintColor.color
        }

        public static var backgroundColor: UIColor {
            SVKAppearanceBox.shared.appearance.toolBarStyle.backgroundColor.color
        }
    }
}
fileprivate extension UIColor{
    /**
     Private overriding of the white color to support .systemBackground color
     - Returns: systemBackground if on iOS13, or white if not
     */
    class var white: UIColor {
        if #available(iOS 13, *){
            return .systemBackground
        }
        return UIColor(white: 1, alpha: 1)
    } // 1.0 white
    
    static func grayScale(_ white: CGFloat,
                          alpha: CGFloat = 1) -> UIColor {
        UIColor(white: white, alpha: alpha)
    }
}

public class SVKHeaderTitleLabel: UILabel {
    
}

public class SVKBlocTitleLabel: UILabel {
    
}

public class SVKBlocDescriptionLabel: UILabel {
    
}

public class SVKBlocActionTitleLabel: UILabel {
    
}

public class SVKBlocButton: UIButton {
    
}
public class SVKActionLabel: UILabel {
    
}

public class SVKMessageLabel: UILabel {
    
}

public class SVKStandardPageMainView: UIView {
    
}

public class SVKStandardPageMessageTitle: UILabel {
    
}

public class SVKStandardPageMessageDescription: UILabel {
    
}

public class SVKStandardPageBulletMessageDescription: UILabel {
    
}

public class SVKStandardPageButtonView: UIView {
    
    private var shadowShape: CAShapeLayer?
    
    public func updateSeparatorLine() {
          if SVKAppearanceBox.shared.appearance.standardPageStyle.useShadow {
            self.setShadow()
        } else {
            self.setSeparatorLine()
        }
    }
    
    private func setShadow() {
        let shadowHeight: CGFloat = 1
        let shadowOpacity: Float = 0.9
        let shadowWidth = self.frame.width//buttonsContainer.bounds.width
        let contactRect = CGRect(x: 0,
                                 y: shadowHeight * 2 ,
                                 width: shadowWidth,
                                 height: shadowHeight)
        
        self.layer.shadowPath = UIBezierPath(rect: contactRect).cgPath
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowColor = SVKAppearanceBox
            .shared
            .appearance
            .buttonStyle
            .highlightedState
            .fillColor
            .color
            .cgColor
    }
    
    private func setSeparatorLine() {
        let width = self.frame.width//buttonsContainer.bounds.width
        let separatorRect = CGRect(x: 0, y: 0, width: width, height: 1)
        shadowShape?.removeFromSuperlayer()
        shadowShape = CAShapeLayer()
        shadowShape?.path = UIBezierPath(rect: separatorRect).cgPath
        
        shadowShape?.strokeColor = UIColor.dividerColor.cgColor
        self.layer.addSublayer(shadowShape!)

    }
}

public class SVKStandardImageView: UIImageView {
    
    override public var image: UIImage? {
        didSet {
            self.constraints.forEach({  (constraint)  in
                switch constraint.firstAttribute {
                case .width:
                    constraint.constant = self.image?.size.width ?? 0
                case .height:
                    constraint.constant = self.image?.size.height ?? 0
                default:
                    break
                }
            })
        }
    }
}

public class SVKCustomButtonHighlighted: SVKCustomButton {
    
}
