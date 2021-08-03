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
import AVKit
import Kingfisher
import MediaPlayer

/// The module bunble
public let SVKBundle: Bundle = {
    guard let bundle = Bundle(identifier: "de.telekom.svk") else {
        return Bundle(identifier: "org.cocoapods.SmartVoiceKit")!
    }
    return bundle
}()

/// Posted when the app change its configuration
public let SVKKitNotificationConfigurationChanged = NSNotification.Name("SVKNotificationConfigurationChanged")

/// App is in background
public let SVKKitNotificationStateBackground = NSNotification.Name("SVKKitNotificationStateBackground")

/// Posted when the app did connect to a tenant
public let SVKKitNotificationTenantDidChanged = NSNotification.Name("SVKNotificationTenantDidChanged")

/// Posted when the textfield should be autofill with some text
public let SVKNotificationAskAssistant = NSNotification.Name("SVKNotificationAskAssistant")

/// Posted when the textfield should be autofill with some text
public let SVKNotificationAudioTriggerAssistant = NSNotification.Name("SVKNotificationAudioTriggerAssistant")

/// SVKConversationViewController display options
public struct SVKConversationDisplayMode: OptionSet, CustomStringConvertible, Codable {
    public let rawValue: Int
    
    /// Display the view controller as a Djingo conversation
    public static let conversation = SVKConversationDisplayMode(rawValue: 1 << 0)
    
    /// Display the view controller as a Djingo conversation
    public static let history = SVKConversationDisplayMode(rawValue: 1 << 1)
    
    /// All modes
    public static let all: SVKConversationDisplayMode = [.conversation, .history]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var description: String {
        var str = [String]()
        if self.contains(.conversation) {
            str.append(".conversation")
        }
        if self.contains(.history) {
            str.append(".history")
        }
        return "[" + str.joined(separator: ", ") + "]"
    }

}

/// Define the input mode use for the conversation
public struct SVKConversationInputMode: OptionSet, CustomStringConvertible, Codable {
    public let rawValue: Int

    /// Use the keyboard to converse
    public static let text = SVKConversationInputMode(rawValue: 1 << 0)

    /// Use the speech to text engine to converse
    public static let audio = SVKConversationInputMode(rawValue: 1 << 1)

    /// All modes
    public static let all: SVKConversationInputMode = [.text, .audio]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var description: String {
        var str = [String]()
        if self.contains(.text) {
            str.append(".text")
        }
        if self.contains(.audio) {
            str.append(".audio")
        }
        return "[" + str.joined(separator: ", ") + "]"
    }

}


public protocol SVKConversationViewControllerDelegate: UITableViewDelegate, UITableViewDataSource {
    
    /**
     A response has been received from Djingo
     - parameter response: The result of the call
     - parameter card: The card associate to the response
     */
    func didReceiveResponse(_ response: SVKInvokeResult, card: SVKCard?,isActiveController: Bool)
    
    /**
     Informs the delegate that a request as been delivered
     - parameter request: The request made by the user
     - parameter at: The timestamp of the delivery
     */
    func request(_ request: String, didDelivered at: Date)
    
    /**
     Informs the delegate that a request as fail
     - parameter request: The request made by the user
     - parameter at: The timestamp of the FAILURE
    */
    func request(_ request: String, didFail at: Date)
    
    /**
     Informs the delegate that a text has been vocalized
     - parameter text: The request made by the user
     - parameter stream: The audio data representing the vocalized text
    */
    func didVocalizeText(_ text: String, stream: Data)
    
}

public typealias SVKInvokeResultCardHandler = (SVKInvokeResult, SVKCard?)->Void

public protocol SVKSpeechProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    /**
     return a card for the identifier reponse.cardId
     - parameter response: the SVKInvokeResult get from the STT webSocket
     - parameter completionHandler: the callback to provide the card
     */
    func translateCard(_ response: SVKInvokeResult, completionHandler: SVKInvokeResultCardHandler?)
    
    /**
     return the codec to be used
     - parameter completionHandler: the callback to provide the codec
     */
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?)
}

public extension SVKSpeechProtocol {
    func translateCard(_ response: SVKInvokeResult, completionHandler: SVKInvokeResultCardHandler?) {
        translateCardInternal(retry: true, response: response, completionHandler: completionHandler)
    }
    
    func translateCardInternal(retry:Bool, response: SVKInvokeResult, completionHandler: SVKInvokeResultCardHandler?) {
        let resultResponse = response
        if let id = response.cardId {
            SVKAPICardRequest(id: id).perform() { fetchResult in
                switch fetchResult
                {
                case .success(_, let card as SVKCard) where card.data != nil:
                    completionHandler?(resultResponse,card)
                case .error(let code, let status, let message,_):
                    SVKLogger.error("\(code):\(status):\(message)")
                    if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                        secureTokenDelegate.didInvalideToken { (success) in
                            if success {
                                translateCardInternal(retry: false, response: response, completionHandler: completionHandler)
                            } else {
                                completionHandler?(resultResponse,nil)
                            }
                        }
                    } else {
                        completionHandler?(resultResponse,nil)
                    }
                default:
                    completionHandler?(resultResponse,nil)
                }
            }
        } else {
             completionHandler?(resultResponse,nil)
        }
    }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
        supportedCodecFormatInternal(retry: true, completionHandler: completionHandler)
    }
    
    func supportedCodecFormatInternal(retry:Bool, completionHandler: ((String?) -> Void)?) {
        SVKAPIDialogSupportedFormatsRequest(converter: .stt).perform { fetchResult in
            switch fetchResult {
            case .success(_, let formats as SVKDialogSupportedFormats):
                completionHandler?(formats.defaultFormat)
            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            supportedCodecFormatInternal(retry: false, completionHandler: completionHandler)
                        } else {
                            completionHandler?(nil)
                        }
                    }
                } else {
                    completionHandler?(nil)
                }
            default:
                completionHandler?(nil)
            }
        }
    }
}

public protocol SVKHistoryScrollViewDelegate {

    /// Tells the delegate when the user finishes scrolling the content.
    /// - Parameters:
    ///   - scrollView: The scroll-view object where the user ended the touch..
    ///   - velocity: The velocity of the scroll view (in points) at the moment the touch was released.
    ///   - targetContentOffset: The expected offset when the scrolling action decelerates to a stop.
    func conversationScrollViewWillEndDragging(_ scrollView: UIScrollView,
                                               withVelocity velocity: CGPoint,
                                               targetContentOffset: UnsafeMutablePointer<CGPoint>)

    /// Tells the delegate when the scroll view is about to start scrolling the content.
    /// - Parameter scrollView: The scroll-view object that is about to scroll the content view.
    func conversationScrollViewWillBeginDragging(_ scrollView: UIScrollView)

    /// Tells the delegate when the user scrolls the content view within the receiver.
    /// - Parameter scrollView: The scroll-view object in which the scrolling occurred.
    func conversationScrollViewDidScroll(_ scrollView: UIScrollView)
}

public protocol SVKConversationProtocol: SVKHistoryProtocol, SVKSpeechProtocol {
    
    /// Implement this dynamic property to provide a title to the view controller
    var title: String { get }
    
    /// The conversation view controller delegate
    var delegate: SVKConversationViewControllerDelegate? { set get }
    
    /**
     Sends a text to Djingo
     - parameter text: the text to send
     - parameter sessionId: The id of the session that identify a ping-pong conversation or nil
     */
    func sendText(_ text: String, with sessionId: String?)
    
    /**
     Vocalize a text
     
     After the text has been vocalized if the completion handler is nil,
     the function **SVKConversationViewControllerDelegate.didVocalizeText(_: String, stream: Data)**
     of the delegate is called
     
     - parameter text: The text to be localized
     - parameter completionHandler: The completion handler.
     */
    func vocalizeText(_ text: String, completionHandler: ((Data?) -> Void)?)
    
    /**
     returns the cell idendifier for a SVKAssistantBubbleDescription
     */
    func cellIdentifier(for description: SVKAssistantBubbleDescription) -> String?
    
    /**
    returns the Skills Catalog from the cvi
    */
    func getCatalog(completionHandler: ((SVKSkillsCatalog?) -> Void)?)
    
    /**
    returns the SVKInvokeResult with quick replies
    */
    func getQuickReplyBubble(invokeResult: SVKInvokeResult) -> SVKInvokeResult
}

public extension SVKConversationProtocol {
    func sendText(_ text: String, with sessionId: String?) {
        sendTextInternal(retry: true, text: text, with: sessionId)
    }
    
    func sendTextInternal(retry:Bool, text: String, with sessionId: String?) {
        
        SVKAPIInvokeTextRequest(text: text, sessionId: sessionId).perform() { result in
            switch result {
            case .success(_, let invokeResult as SVKInvokeResult):
                self.delegate?.request(text, didDelivered: Date())
                
                //Check response error
                if isResponseContainsError(status: invokeResult.status) {
                    //Get quick replies for SVK assistant
                    let newResultResponse = getQuickReplyBubble(invokeResult: invokeResult)
                    DispatchQueue.main.safeAsync {
                        if let isQuickRepliesEmpty = newResultResponse.quickReplies?.replies.isEmpty, isQuickRepliesEmpty {
                            self.delegate?.didReceiveResponse(invokeResult, card: nil, isActiveController: true)
                        } else {
                            self.delegate?.didReceiveResponse(newResultResponse, card: nil, isActiveController: true)
                        }
                    }
                } else {
                    // retreive the associated card if needed
                    if let id = invokeResult.cardId {
                        SVKAPICardRequest(id: id).perform() { fetchResult in
                            switch fetchResult {
                            case .success(_, let card as SVKCard) where card.data != nil:
                                self.delegate?.didReceiveResponse(invokeResult, card: card, isActiveController: true)
                            default:
                                SVKAnalytics.shared.log(event: "myactivity_view_card_error")
                                self.delegate?.didReceiveResponse(invokeResult, card: nil, isActiveController: true)
                            }
                        }
                    } else {
                        self.delegate?.didReceiveResponse(invokeResult, card: nil, isActiveController: true)
                    }
                }
                
            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            sendTextInternal(retry: false, text: text, with: sessionId)
                        } else {
                            self.delegate?.request(text, didFail: Date())
                        }
                    }
                } else {
                    self.delegate?.request(text, didFail: Date())
                }
            default: break
            }
        }
    }
    
    func getQuickReplyBubble(invokeResult: SVKInvokeResult) -> SVKInvokeResult {
        let keyAssistantResponse = SVKConstant.getKeyAssistantResponse(status: invokeResult.status)
        var replies = [SVKQuickReply]()
        SVKConversationAppearance.shared.skillCatalog.forEach { (skill, skillCatalog) in
            skillCatalog.finalContent?.examplePhrases.forEach({ (string) in
                let action = SVKQuickReplyAction(type: .publishText, value: string)
                let reply = SVKQuickReply(type: .button, tooltip: string, title: string, iconUrl: nil, action: action)
                replies.append(reply)
            })
        }

        while replies.count > recommendationHackNbMax {
            let r = Int.random(in: 0..<replies.count)
            replies.remove(at: r)
        }
        let quickReplies = SVKQuickReplies(type: .quickReplies, itemAligment: .vertical, replies: replies)
        let newResultResponse = SVKInvokeResult(cardId: invokeResult.cardId, intent: invokeResult.intent, session: invokeResult.session, skill: invokeResult.skill, stt: invokeResult.stt, sttCandidates: invokeResult.sttCandidates, text: keyAssistantResponse.localizedWithTenantLang, status: invokeResult.status, smarthubTraceId: invokeResult.smarthubTraceId, conversationId: invokeResult.conversationId, jsonData: invokeResult.jsonData, quickReplies: quickReplies)
        return newResultResponse
    }
    
    func isResponseContainsError(status: String) -> Bool {
        return SVKConstant.isResponseContainsMisunderstoodError(status: status) || SVKConstant.isResponseContainsSkillError(status: status)
    }
    
    func vocalizeText(_ text: String, completionHandler: ((Data?) -> Void)?) {
        vocalizeTextInternal(retry: true, text: text, completionHandler: completionHandler)
    }
 
    func vocalizeTextInternal(retry:Bool, text: String, completionHandler: ((Data?) -> Void)?) {
        
        SVKAPIVoiceRequest(converter: .tts(text)).perform() { result in
            switch result {
            case .success (_, let decodable):
                if let rawData = decodable as? SVKRawData {
                    if let completion = completionHandler {
                        completion(rawData.data)
                    } else {
                        self.delegate?.didVocalizeText(text, stream: rawData.data)
                    }
                }

            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            vocalizeTextInternal(retry: false, text: text, completionHandler: completionHandler)
                        } else {
                            completionHandler?(nil)
                        }
                    }
                } else {
                    completionHandler?(nil)
                }
            }
        }
    }
    
    func cellIdentifier(for description: SVKAssistantBubbleDescription) -> String? {
        return nil
    }
    
    func getCatalog(completionHandler: ((SVKSkillsCatalog?) -> Void)?) {
        getCatalogInternal(retry: true, completionHandler: completionHandler)
    }
    func getCatalogInternal(retry: Bool, completionHandler: ((SVKSkillsCatalog?) -> Void)?) {
        
        SVKAPISkillCatalogRequest().perform() { result in
            switch result {
            case .success(_, let container as SVKSkillsCatalog):
                completionHandler?(container)
            case .error(let code, let status, let message,_):
                SVKLogger.error("\(code):\(status):\(message)")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            getCatalogInternal(retry: true, completionHandler: completionHandler)
                        } else {
                            completionHandler?(nil)
                        }
                    }
                } else {
                    completionHandler?(nil)
                }
            default:
                completionHandler?(nil)
            }
        }
    }
}

/**
 The main conversation ViewController
 It's manage the conversation and the history functionalities
 */
public final class SVKConversationViewController: UIViewController, SVKFilterDelegate, SVKPickerViewable {

    let animationDuration: TimeInterval = 0.2
    
    var needsScrollToBottom = false
    
    // Do not use directly, use updateFilterValue instead
    internal var internalFilterValue: SVKFilter = SVKFilter(range: .all, device: nil)

    public var filterValue: SVKFilter {
        return internalFilterValue
    }

    public var showOnlyDeviceHistory: Bool = false
    
    public var isDevicesFeatureAvailable: Bool {
        return !showOnlyDeviceHistory
    }

    private var deviceFilterSourceList = [SVKFilterDevice]()

    public func updateFilterValue(_ newFilterValue: SVKFilter) {
        updateHeaderFilterStyle()
        timeFilterImageView.transform = .identity
        speakerFilterImageView.transform = .identity

        if !isHistoryRefreshing {
            if newFilterValue.range != filterValue.range || newFilterValue.device?.serialNumber != filterValue.device?.serialNumber {
                self.internalFilterValue = newFilterValue
                self.loadNewerControl?.trigger()
            }
        }
    }

    public func updateRangeFilter(value: SVKFilterRange) {
        updateHeaderFilterStyle()
        timeFilterImageView.transform = .identity
        if !isHistoryRefreshing {
            selectedPeriodFilterLabel.text = ("Filters.enum.\(value)").localized
            if value != filterValue.range {
                self.internalFilterValue = SVKFilter(range: value, device: internalFilterValue.device)
                self.loadNewerControl?.trigger()
            }
        }
    }

    public func updatePeriodFilter(value: SVKFilterDevice?) {
        updateHeaderFilterStyle()
        speakerFilterImageView.transform = .identity

        if !isHistoryRefreshing {
            selectedSpeakerFilterLabel.text =  value?.name ?? "\("Filters.speaker.all".localized)"
            if value?.serialNumber != filterValue.device?.serialNumber {
                self.internalFilterValue = SVKFilter(range: internalFilterValue.range, device: value)
                self.loadNewerControl?.trigger()
            }
        }
    }

    var queueDelegateGetDeviceList = DispatchQueue.init(label: "SVKGetDeviceList")
    
    public func getDeviceList(completionHandler: (([SVKFilterDevice]) -> Void)?) {
        self.delegate?.getDeviceList(completionHandler: { (devices) in
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            var deviceNumbersList = [SVKFilterDevice]()
            self.queueDelegateGetDeviceList.async {
                for (_, device) in devices.enumerated() {
                    
                    operationQueue.addOperation {
                        let semaphore = DispatchSemaphore(value: 0)
                        self.delegate?.getDeviceMetadata(from: device, completionHandler: { (metadata) in
                            if let metadata = metadata, let name = metadata.deviceName {
                                let filterDevice = SVKFilterDevice(name: name, serialNumber: device)
                                deviceNumbersList.append(filterDevice)
                            }
                            semaphore.signal()
                        })
                        semaphore.wait()
                    }
                }
                operationQueue.waitUntilAllOperationsAreFinished()
                completionHandler?(deviceNumbersList)
            }
        })
    }
    
    
    @IBOutlet var headerFilterView: SVKFilterHeaderView!

    @IBOutlet weak var speakerFilterStackViewView: UIStackView!
    @IBOutlet weak var speakerFilterView: UIView!
    @IBOutlet weak var speakerFilterImageView: UIImageView!
    @IBOutlet weak var timeFilterView: UIView!
    @IBOutlet weak var timeFilterImageView: UIImageView!
    @IBOutlet weak var selectedSpeakerFilterLabel: UILabel!
    @IBOutlet weak var selectedPeriodFilterLabel: UILabel!
    @IBOutlet weak var filterCloseButton: UIButton!
    @IBOutlet weak var speakerActivityIndicator: UIActivityIndicatorView! {
        didSet {
            speakerActivityIndicator.hidesWhenStopped = true
        }
    }

    @IBOutlet var headerFilterTopConstraint: NSLayoutConstraint!
    /// The tableView thats handles bubbles display
    @IBOutlet var tableView: UITableView!
    
    /// The toolbar
    @IBOutlet var toolbar: UIView!
    
    /// The textfield
    @IBOutlet var textField: SVKTextField?
    @IBOutlet var inputViewContainer: UIView!
    
    @IBOutlet var tableTopLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet var quickBottomButton: UIButton!
    
    /// The conversation delegate
    public var delegate: SVKConversationProtocol?
    
    /// The state of the system music player at the beginning of a Push To Talk transaction
    internal var systemMusicPlaybackState: MPMusicPlaybackState = .stopped
    
    // TODO : put this parameter for SVKAudioRecorderViewController and remove it on SVKAudioPlayer
    /// Set to false to disable sound effects. Default to true
    public var isSoundEffectsEnabled: Bool = true {
        didSet {
            if let vc = userInputViewController as? SVKAudioInputViewController {
                vc.isSoundEffectsEnabled = isSoundEffectsEnabled
            }
        }
    }
    public var isVocalizationEnabled: Bool = true

    public var isHideErrorInteractionsEnabled: Bool = false
    
    public var isHideDeviceDefaultNameEnabled: Bool = false
    
    /// The number of message to load at refresh time. Default is 35
    public var maxMessagesToLoad = 35
    
    /// The id of the oldest loaded message
    internal var oldestId: String?
    
    internal var isOlderReached = false
    
    /// The timestamp of the newest loaded message
    internal var newest = Date()
    
    /// The timestamp of the oldest loaded message
    internal var oldest = Date()
    
    /// The user inputViewController
    internal var userInputViewController: SVKConversationInputProtocol?
    
    /// The conversation state
    internal var state: SVKConverstationInputState = .idle {
        didSet {
            userInputViewController?.state = state
        }
    }
    
    internal var bubbleKeyIndex: Int = 0
    
    internal var nextBubbleKey: Int {
        bubbleKeyIndex += 1
        return bubbleKeyIndex
    }
    
    internal func isUserBubbleConversation(at indexPath: IndexPath) -> Bool {
        if let description = self.conversation[indexPath] as? SVKUserBubbleDescription,
            description.contentType == .text,
            self.displayMode.contains(.conversation) {
            return true
        }
        return false
    }
    
    internal func isAssistantBubbleConversation(at indexPath: IndexPath) -> Bool {
        if self.conversation[indexPath] is SVKAssistantBubbleDescription,
            self.displayMode.contains(.conversation) {
            return true
        }
        return false
    }
    
    var isHistoryRefreshing = false {
        didSet {
            self.userInputViewController?.isHistoryRefreshing = self.isHistoryRefreshing
        }
    }
    
    public var isHistroyEmpty = false
    public var isWelcomeMsgAdded = false
    public var isPrimaryWelcomeMsgAdded = false
    
    /// Define the way the view controller should be display: Default to .conversation
    public var displayMode = SVKConversationDisplayMode.conversation {
        willSet(newDisplayMode) {
            if (!isDisplayModeInitialized) {
                displayModeBackup = newDisplayMode
                isDisplayModeInitialized = true
            }
        }
    }
    var isDisplayModeInitialized = false
    
    var isMainNotificationAudioTriggerAssistantReceiver = true
    
    var displayModeBackup = SVKConversationDisplayMode.conversation
    
    /// Used to manage the delete check/uncheck of cells and avoid
    /// weird scrolling/artefact displays on various iOS version
    /// see method tableView...wilDisplayCell and tableView...estimatedRowHeight
    var cellHeightDict = [Int:CGFloat]()

    /// Defines the way the user converse with Djingo: Default to .text
    public var inputMode = SVKConversationInputMode.text {
        didSet {
            setToolbarStyle(animated: true)
        }
    }
    public var inputAnimationMode = SVKAudioInputAnimationType.barGraph

    // MARK: FIlterView Functionality

    @IBAction public func showFilterstHistoryEntries(_ sender: Any) {
        showFilterView()
    }
    
    public func showFilterView() {
        guard SVKReachability.isInternetAvailable() else {
            self.view.showNoInternetToast()
            return
        }

        if displayMode.contains(.conversation), !(userInputViewController?.state == .idle)  {
            return
        }

        if isHistroyEmpty {
            let alert = UIAlertController(title: "SVK.filter.no.histroy.error.title".localized, message: "SVK.filter.no.histroy.error.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            if displayMode.contains(.conversation)  {
                setToolbarHidden(true, animated: false)
            }
            
            state = .disabled
            self.headerFilterTopConstraint.constant = 0
            self.tableTopLayoutConstraint.constant  = 66
            selectedSpeakerFilterLabel.text = "- \("Filters.speaker.title".localized) -"
            selectedPeriodFilterLabel.text = "- \(("Filters.range.title").localized) -"

            UIView.animate(withDuration: animationDuration, animations: {
                self.tableView.superview?.layoutIfNeeded()
            })

            if isDevicesFeatureAvailable {
                speakerActivityIndicator.startAnimating()
                self.getDeviceList { [weak self] (devices) in
                    self?.deviceFilterSourceList = devices
                    DispatchQueue.main.async {
                        self?.speakerActivityIndicator.stopAnimating()
                        self?.speakerFilterStackViewView.isHidden = devices.count <= 0
                    }
                }
            } else {
                speakerFilterStackViewView.isHidden = true
            }
            let indexPath = self.conversation.lastElementIndexPath
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @IBAction public func dismissHeaderFilter(_ sender: Any) {
        dismissFilter()
    }

    func dismissFilter() {
        state = .idle
        setToolbarStyle(animated: false)
        if displayMode.contains(.conversation) && !conversation.isEmpty {
            let indexPath = self.conversation.lastElementIndexPath
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
        self.loadNewerControl?.isHidden = false
        self.loadNewerControl?.isEnabled = true
        self.updateFilterValue(SVKFilter(range: .all, device: nil))
        self.headerFilterTopConstraint.constant = -headerFilterView.frame.height
        self.tableTopLayoutConstraint.constant  = 0
        UIView.animate(withDuration: animationDuration) { [weak self] in
            self?.tableView.superview?.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.selectedSpeakerFilterLabel.text = "- \("Filters.speaker.title".localized) -"
            self?.selectedPeriodFilterLabel.text = "- \(("Filters.range.title").localized) -"
        }
    }

    @IBAction func didTapOnSpeakerFilter(_ sender: UIControl) {
        let pickerView = displayPicker(type: .speaker, delegate: self)
        pickerView?.setTimeFilterPicker(list: SVKFilterRange.allCases, selectedTimeFilter: filterValue.range)
        pickerView?.updateSpeaker(sourceList: deviceFilterSourceList, defaultDeviceSerialNumber: filterValue.device?.serialNumber)
        speakerFilterImageView.transform = speakerFilterImageView.transform.rotated(by: CGFloat(Double.pi))
    }

    @IBAction func didTapOnTimeFilter(_ sender: UIControl) {
        let pickerView = displayPicker(type: .time, delegate: self)
        pickerView?.setTimeFilterPicker(list: SVKFilterRange.allCases, selectedTimeFilter: filterValue.range)
        pickerView?.updateSpeaker(sourceList: deviceFilterSourceList, defaultDeviceSerialNumber: filterValue.device?.serialNumber)
        timeFilterImageView.transform = timeFilterImageView.transform.rotated(by: CGFloat(Double.pi))
    }
    /// The delay in minutes that defines a conversation session to group messages. Default is 10
    public var groupedMessageDelay: TimeInterval = 10
    
    internal var conversation = SVKConversationDescription()
    public var context = SVKContext()
    
    /// A load more control for newer messages
    internal lazy var loadNewerControl: SVKLoadMoreControl? = {
        let control = SVKLoadMoreControl(position: .bottom, animationType: SVKConversationAppearance.shared.loadMoreControlAppearance.animationType)
        control.backgroundColor = SVKConversationAppearance.shared.loadMoreControlAppearance.backgroundColor
        control.addTarget(self, action: #selector(loadHistoryNewerMessages(loadMoreControl:)), for: .valueChanged)
        tableView.addSubview(control)
        return control
    }()
    
    /// A load more control for older messages
    internal lazy var loadOlderControl: SVKLoadMoreControl? = {
        let control = SVKLoadMoreControl(position: .top,animationType: SVKConversationAppearance.shared.loadMoreControlAppearance.animationType)
        control.backgroundColor = SVKConversationAppearance.shared.loadMoreControlAppearance.backgroundColor
        control.addTarget(self, action: #selector(loadHistoryOlderMessages(loadMoreControl:)), for: .valueChanged)
        tableView.addSubview(control)
        return control
    }()
    
    internal var shouldRestoreMoreButton = false
    
    internal var leftBarButtonItemBackup: UIBarButtonItem?
    /// true is the viewController is in edit mode
    override public var isEditing: Bool {
        set {
            tableView.allowsMultipleSelectionDuringEditing = newValue
            self.tableView.setEditing(newValue, animated: true)
        }
        get {
            return tableView.isEditing && tableView.allowsMultipleSelectionDuringEditing
        }
    }
    
    override public var navigationItem: UINavigationItem {
        if let topViewController = self.navigationController?.topViewController {
            return self == topViewController ? super.navigationItem : topViewController.navigationItem
        }
        return super.navigationItem
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deregisterFromKeyboardNotifications()
    }
    
    public func setNeedsScrollToBottom() {
        self.needsScrollToBottom = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = UIView(frame: .zero)
        delegate?.delegate = self
        self.quickBottomButton.alpha = 0.0
        SVKLogger.debug("Display mode: \(displayMode)")

        let nib = UINib(nibName: "SVKSectionHeader", bundle: SVKBundle)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "SVKSectionIdentifier")
                
        headerFilterTopConstraint.constant = -headerFilterView.frame.height
        tableTopLayoutConstraint.constant = 0
        
        setToolbarStyle(animated: false)
        registerToKeyboardNotifications()
        addGestureRecognizers()
        isMoreButtonHidden = false
        registerNotifications()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = delegate?.title
        self.navigationItem.title = delegate?.title
        tableView.backgroundView = SVKConversationAppearance.shared.backgroundView
        tableView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        tableView.backgroundView?.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        headerFilterView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        self.loadNewerControl?.backgroundColor = SVKConversationAppearance.shared.loadMoreControlAppearance.backgroundColor
        self.loadNewerControl?.animationType = SVKConversationAppearance.shared.loadMoreControlAppearance.animationType
        
        self.loadOlderControl?.backgroundColor = SVKConversationAppearance.shared.loadMoreControlAppearance.backgroundColor
        self.loadOlderControl?.animationType = SVKConversationAppearance.shared.loadMoreControlAppearance.animationType
        if let userInputViewController = userInputViewController as? UIViewController {
            userInputViewController.viewWillAppear(animated)
        }
        
        updateHeaderFilterStyle()
        SVKAnalytics.shared.startActivity(name: "myactivity_view", with: nil)
    }
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *){
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) &&
                SVKAppearanceBox.shared.appearance.userInterfaceStyle.contains(.dark){
                reloadData()
            }
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reloadData()
    }

    func updateHeaderFilterStyle() {
        timeFilterImageView.image = SVKAppearanceBox.shared.appearance.assets?.filterDropDown
        speakerFilterImageView.image = SVKAppearanceBox.shared.appearance.assets?.filterDropDown
        filterCloseButton.setImage(SVKAppearanceBox.shared.appearance.assets?.filterClose, for: .normal)
        selectedPeriodFilterLabel.font = SVKAppearanceBox.shared.appearance.filterViewStyle.font.font
        selectedSpeakerFilterLabel.font = SVKAppearanceBox.shared.appearance.filterViewStyle.font.font
        headerFilterView.backgroundColor = SVKAppearanceBox.FilterStyle.backgroundColor
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadOlderControl?.setNeedsLayout()
        self.loadNewerControl?.setNeedsLayout()
        speakerFilterView.addRoundedCorner(radius: SVKAppearanceBox.FilterStyle.cornerRadius,
                                           withBorder: SVKAppearanceBox.FilterStyle.borderWidth,
                                           borderColor: SVKAppearanceBox.FilterStyle.borderColor)
        timeFilterView.addRoundedCorner(radius: SVKAppearanceBox.FilterStyle.cornerRadius,
                                        withBorder: SVKAppearanceBox.FilterStyle.borderWidth,
                                        borderColor: SVKAppearanceBox.FilterStyle.borderColor)
    }

    public override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
        if conversation.sections.count == 0, displayMode.contains(.history),!(self.filterValue.range == .all && self.filterValue.device?.serialNumber != nil) {
            registerSkillsAppearance { [weak self] in
                self?.loadNewerControl?.locale = SVKContext.locale
                self?.loadOlderControl?.locale = SVKContext.locale
                self?.loadNewerControl?.trigger()
            }
        }
        self.scrollToBottomIfNeeded()
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = userInputViewController as? SVKAudioInputViewController {
            vc.clearNotification()
        }
        if segue is SVKInputSelectionSegue {
            userInputViewController = segue.destination as? SVKConversationInputProtocol
            userInputViewController?.inputMode = inputMode
            (userInputViewController as? SVKAudioInputViewController)?.delegate = self
            (userInputViewController as? SVKAudioInputViewController)?.context = self.context
            (userInputViewController as? SVKTextInputViewController)?.prefixLocalisationKey = self.context.dedicatedPreFixLocalisationKey
            
            (userInputViewController as? SVKAudioInputViewController)?.isMainNotificationAudioTriggerAssistantReceiver = isMainNotificationAudioTriggerAssistantReceiver
        }
    }
    func reloadInputUI(){
        setToolbarStyle(animated: false)
    }
    func resetAudioRecorderWasPresented(){
        (userInputViewController as? SVKAudioInputViewController)?.cancelWasAlreadyPresented()
    }
    
    public func setUpAnimationType(animationType: SVKAudioInputAnimationType = .barGraph){
        (userInputViewController as? SVKAudioInputViewController)?.inputAnimationMode = animationType
        self.inputAnimationMode = animationType
        resetAudioRecorderWasPresented()
        reloadInputUI()
    }
    
    public func refreshQuickDownButton() {
        tableView.layoutIfNeeded()
        let contentHeight = self.tableView.contentSize.height
        let tableViewHeight = self.tableView.bounds.height
        if contentHeight > tableViewHeight {
            let offset = self.tableView.contentOffset.y
            if offset + tableViewHeight > contentHeight - (tableViewHeight / 2) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.quickBottomButton.alpha = 0.0
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.quickBottomButton.alpha = 1.0
                })
            }
        }
    }
    
    @IBAction func scrollToBottom(_ sender: Any) {
        let indexPath = self.conversation.lastElementIndexPath
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // update loadControl when user scrolls de tableView
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.conversationScrollViewDidScroll(scrollView)
        guard displayMode.contains(.history), userInputViewController?.state != .kbdSendingText,
            userInputViewController?.state != .sttSendingText, userInputViewController?.state != .sttListening,
            userInputViewController?.state != .sttStarting, userInputViewController?.state != .sttStopping,
            userInputViewController?.state != .sttRecognizing else { return }
        guard let loadOlderControl = self.loadOlderControl, !loadOlderControl.isLoading else { return }
        guard let loadNewerControl = self.loadNewerControl, !loadNewerControl.isLoading else { return }
        
        let headerOffset = self.tableTopLayoutConstraint.constant
        loadOlderControl.evaluateValueChanged(for: scrollView,headerOffset: headerOffset)
        loadNewerControl.evaluateValueChanged(for: scrollView,headerOffset: headerOffset)
        refreshQuickDownButton()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.conversationScrollViewWillBeginDragging(scrollView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.conversationScrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDelegate
    public func numberOfSections(in tableView: UITableView) -> Int {
        return conversation.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation[section].elements.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isEditing {
            return 0
        }
        if section == 0 && !isOlderReached {
            return 0
        }
        return 62.0
    }
        
    // see https://stackoverflow.com/questions/46232473/ios-11-reloadsections-create-duplicate-header-section
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let bubbleDescription = self.conversation[indexPath]
        cellHeightDict[bubbleDescription.bubbleKey] = cell.frame.size.height        
    }
    
    // see http://jtdz-solenoids.com/stackoverflow_/questions/47690381/uitableview-reload-rows-unnaturally-jerking-the-tableview-in-ios-11-2
    // and also mentioned here https://openradar.appspot.com/46806232
    // see https://stackoverflow.com/questions/46232473/ios-11-reloadsections-create-duplicate-header-section
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let bubbleDescription = self.conversation[indexPath]
        if let cellHeight = cellHeightDict[bubbleDescription.bubbleKey] {
            return cellHeight
        }
        return UITableView.automaticDimension
    }
    
    internal func refreshTableviewHeaderAndFooter() {
        self.refreshTableviewHeader()
        if self.conversation.sections.count > 0 && (self.filterValue.range != .all) {
            self.addTableviewFooter()
        } else {
            self.removeTableviewFooter()
        }
    }
    
    internal func addTableviewFooter() {
        let footerView = UIView(frame: .zero)
        footerView.backgroundColor = UIColor.clear
        var frame = footerView.frame
        frame.size.height = CGFloat(128)
        footerView.frame = frame
        
        let messageView = UIView(frame: .zero)
        messageView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        messageView.translatesAutoresizingMaskIntoConstraints = false
        var messsageViewFrame = messageView.frame
        messsageViewFrame.size.height = CGFloat(120)
        messageView.frame = messsageViewFrame
        let contentInsetMessage = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        
        let messageLabel = UILabel(frame: footerView.frame)
        let dedicatedPostFixLocalisationKey = self.context.dedicatedPreFixLocalisationKey
        let topMessageKey = dedicatedPostFixLocalisationKey + ".DC.history.filter.reached.end.bottom.message"
        messageLabel.text = topMessageKey.localized
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.loader.withSize(13)
        messageLabel.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
        messageLabel.textAlignment = .center
        let contentInsetLabel = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        
        messageView.addSubview(messageLabel)
        footerView.addSubview(messageView)
        
        messageView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[label]-(right)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: ["left": contentInsetLabel.left, "right": contentInsetLabel.right],
                                                           views: ["label": messageLabel]))
        messageView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[label]-(bottom)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: ["top": contentInsetLabel.top, "bottom": contentInsetLabel.bottom],
                                                           views: ["label": messageLabel]))
        
        
        footerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[messageView]-(right)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: ["left": contentInsetMessage.left, "right": contentInsetMessage.right],
                                                           views: ["messageView": messageView]))
        footerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[messageView]-(bottom)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: ["top": contentInsetMessage.top, "bottom": contentInsetMessage.bottom],
                                                           views: ["messageView": messageView]))
        
        tableView.tableFooterView = footerView
    }
    
    internal func removeTableviewFooter() {
        tableView.tableFooterView?.removeFromSuperview()
        tableView.tableFooterView = UIView()
    }

    internal func refreshTableviewHeader() {
        if conversation.sections.count > 0 && (isOlderReached)  {
            let headerView = UIView(frame: .zero)
            headerView.backgroundColor = SVKConversationAppearance.shared.backgroundColor
            var frame = headerView.frame
            frame.size.height = CGFloat(120)
            frame.size.width = self.tableView.frame.width
            headerView.frame = frame
            
            let messageLabel = UILabel(frame: headerView.frame)
            let dedicatedPostFixLocalisationKey = self.context.dedicatedPreFixLocalisationKey
            let filterKey = self.filterValue.range != .all  || self.filterValue.device?.serialNumber != nil ? "filter." : ""
            let topMessageKey = dedicatedPostFixLocalisationKey + ".DC.history." + filterKey + "reached.end.message"
            
            messageLabel.text = topMessageKey.localized
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.numberOfLines = 0
            messageLabel.font = UIFont.loader.withSize(13)
            messageLabel.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
            messageLabel.textAlignment = .center
            let contentInset = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
            headerView.addSubview(messageLabel)
            
            headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[label]-(right)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["left": contentInset.left, "right": contentInset.right],
                                                               views: ["label": messageLabel]))
            headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[label]-(bottom)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["top": contentInset.top, "bottom": contentInset.bottom],
                                                               views: ["label": messageLabel]))
            
            tableView.tableHeaderView = headerView
            loadOlderControl?.isEnabled = false
            loadOlderControl?.isHidden = true
        } else {
            tableView.tableHeaderView?.removeFromSuperview()
            tableView.tableHeaderView = nil
            loadOlderControl?.isEnabled = true
            loadOlderControl?.isHidden = false
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard isEditing else { return nil }
        
        if section == 0 && !isOlderReached {
            return nil
        }
        let header = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "SVKSectionIdentifier") as! SVKTableSectionHeader
        header.titleLabel.text = SVKTools.formattedDate(from: self.conversation[section].title)
        header.isSelected = self.conversation[section].isSelected
        header.backgroundView?.backgroundColor = SVKAppearanceBox.cardBackgroundColor
        header.titleLabel.textColor = SVKAppearanceBox.cardTextColor
        header.section = section
        return header
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let bubbleDescription = conversation[indexPath.section].elements[indexPath.row]
        
        var tableViewCell: SVKTableViewCell!
        
        if let description = bubbleDescription as? SVKUserBubbleDescription {
            switch description.contentType {
            case .waitingIndicator:
                tableViewCell = tableView.dequeueReusableCell(SVKUserThinkingIndicatorTableViewCell.self, for: indexPath)

            default:
                tableViewCell = tableView.dequeueReusableCell(SVKUserTextTableViewCell.self, for: indexPath)
            }
        } else if bubbleDescription is SVKHeaderErrorBubbleDescription {
            tableViewCell = tableView.dequeueReusableCell(SVKErrorHeaderTableViewCell.self, for: indexPath)
            if let errorCell = tableViewCell as? SVKErrorHeaderTableViewCell {
                errorCell.errorDelegate = self
            }
            
        } else {
            let description = bubbleDescription as! SVKAssistantBubbleDescription
            
            
            if let identifier = self.delegate?.cellIdentifier(for: description),
               let externalTableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SVKTableViewCell {
                tableViewCell = externalTableViewCell
            } else {
                if description.card?.version == 3 || description.card?.version == 2 || (description.card?.version == 1 && description.card?.type == .genericDefault) || (description.card?.version == 1 && description.card?.type == .generic) {
                    tableViewCell = tableView.dequeueReusableCell(SVKGenericDefaultCardV3TableViewCell.self, for: indexPath)
                } else {
                    switch description.contentType {
                    case .waitingIndicator:
                        tableViewCell = tableView.dequeueReusableCell(SVKThinkingIndicatorTableViewCell.self, for: indexPath)
                        
                    case .genericCard:
                        if let layout = description.card?.data?.layout {
                            switch layout {
                            case .partner:
                                tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardPartnerTableViewCell.self, for: indexPath)
                            default:
                                tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                            }
                        } else {
                            tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                        }
                        
                    case .memolistCard,
                         .timerCard,
                         .iotCard:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                        
                    case .image:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantImageTableViewCell.self, for: indexPath)
                        
                    case .imageCard:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                        
                    case .weatherCard:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                        
                    case .musicCard:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardPartnerTableViewCell.self, for: indexPath)
                        
                    case .audioController:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantGenericTableViewCell.self, for: indexPath)
                        
                    case .recipeCard:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantCardImageTableViewCell.self, for: indexPath)
                        
                    case .disabledText:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantDisabledTextTableViewCell.self, for: indexPath)
                        
                    default:
                        tableViewCell = tableView.dequeueReusableCell(SVKAssistantTextTableViewCell.self, for: indexPath)
                    }
                }
            }
        }
        tableViewCell.isCardHackEnabled = context.isCardHackEnabled
        tableViewCell.dedicatedPreFixLocalisationKey = context.dedicatedPreFixLocalisationKey

        // fill the cell with some content
        tableViewCell.fill(with: bubbleDescription)
        
        // provide a delegate to the cell thats conforms to SVKTableViewCellProtocol
        // and set the bubble's long press action
        if let cell = tableViewCell as? SVKTableViewCellProtocol,
            let bubble = cell.concreteBubble() {
            tableViewCell.delegate = self
            setLongPressAction(for: bubble)
        }
        
        tableViewCell.isTimestampHidden = isEditing || bubbleDescription.isTimestampHidden
        tableViewCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.view.frame.width)
        
        if isEditing {
            if self.conversation[indexPath.section].isLastElement(at: indexPath.row) {
                tableViewCell.bottomConstraint?.constant = 7
            } else if bubbleDescription is SVKAssistantBubbleDescription {
                if let cell = tableViewCell as? SVKTableViewCellProtocol,
                    cell.bubbleStyle != .top(.left) {
                    tableViewCell.bottomConstraint?.constant = 7
                }
            }
        }
        return tableViewCell
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == conversation.sections.count - 1 {
            return 16.0
        }
        return 8.0
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        return footer
    }

    public func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        // reposition the load more control
        self.loadNewerControl?.setNeedsLayout()
        self.loadOlderControl?.setNeedsLayout()
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? SVKTableViewCellProtocol {
            cell.cancelDownloadTask()
        }
        // reposition the load more control
        self.loadNewerControl?.setNeedsLayout()
        self.loadOlderControl?.setNeedsLayout()
    }
    
    //MARK: Conversation public APIs
    /**
     A Boolean indicating whether the navigation controller’s built-in toolbar is visible.
     
     Discussion
     If this property is set to true, the more button is not visible. The default value of this property is true
     */
    public var isMoreButtonHidden: Bool {
        get {
            return self.navigationItem.rightBarButtonItem  == nil
        }
        set {
            if newValue == true {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "∙∙∙", style: .plain, target: self, action: #selector(showMoreMenu(_:)))
            }
        }
    }
    
    /**
     Reload the conversation
     */
    public func reloadData() {
        self.tableView.reloadData()
    }
    
    /**
     Clear the conversation
     - parameter animated: true to animate the deletion. Default is false
     */
    public func clear(animated: Bool = false,reset: Bool = false) {
        newest = Date()
        oldest = Date()
        oldestId = nil
        self.tableView.tableHeaderView?.removeFromSuperview()
        self.tableView.tableHeaderView = nil
        self.refreshTableviewHeaderAndFooter()
        self.loadOlderControl?.isEnabled = true
        self.quickBottomButton.alpha = 0.0
        self.cellHeightDict.removeAll()
        func innerClear() {
            if animated {
                self.tableView.beginUpdates()
                
                var indexSet = IndexSet()
                for (index, _) in self.conversation.sections.enumerated() {
                    indexSet.insert(index)
                }
                
                self.conversation.sections.removeAll()
                self.tableView.deleteSections(indexSet, with: .automatic)
                self.tableView.endUpdates()
            } else {
                self.conversation.sections.removeAll()
                self.tableView.reloadData()
            }
            if (reset) {
                isDisplayModeInitialized = false
            }
        }
        if (Thread.isMainThread) {
            innerClear()
        } else {
            DispatchQueue.main.async {
                innerClear()
            }
        }
    }
    
    /**
     Insert the welcome message if the conversation is empty
     at startup
     */
    func insertWelcomeMessage() {
        guard self.conversation.sections.count == 0 else { return }
        let dedicatedPostFixLocalisationKey = self.context.dedicatedPreFixLocalisationKey
        
        let welcomeMessageKey = dedicatedPostFixLocalisationKey + ".welcome.message"
        var description = SVKAssistantBubbleDescription(bubbleStyle: .default(.left),
                                                    text: welcomeMessageKey.localizedWithTenantLang, type: .text, timestamp: SVKTools.iso8061DateFormatter.string(from: Date()), invokeResult: nil)
        description.origin = .conversation
        var secondaryDescription = SVKAssistantBubbleDescription(bubbleStyle: .default(.left),
                                                    text: "secondary.welcome.message".localizedWithTenantLang, type: .text, timestamp: SVKTools.iso8061DateFormatter.string(from: Date()), invokeResult: nil)
        secondaryDescription.origin = .conversation
        var descriptions: [SVKBubbleDescription] = [secondaryDescription, description]
        self.insertBubbles(from: &descriptions, at: 0, in: 0)
    }
    
    /**
     Insert the secondarywelcome message when the app launch
     at startup
     */
    func insertSecondaryWelcomeMessage() {
        var description = SVKAssistantBubbleDescription(bubbleStyle: .default(.left),
                                                    text: "secondary.welcome.message".localizedWithTenantLang, type: .text, timestamp: SVKTools.iso8061DateFormatter.string(from: Date()), invokeResult: nil)
        description.origin = .conversation
        var descriptions: [SVKBubbleDescription] = [description]
        self.insertBubbles(from: &descriptions, at: 0, in: 0)
    }
    
    
    ///MARK: showMoreMenu
    @objc
    public func showMoreMenu(_ sender: Any) {
        if headerFilterTopConstraint.constant == 0 {
            self.dismissFilter()
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle:  .actionSheet)

        alert.addAction(
            UIAlertAction(title: "navigationBar.menu.filters".localized, style: .default) { _ in
                self.showFilterView()
        })
        
        alert.addAction(
            UIAlertAction(title: "navigationBar.menu.delete".localized, style: .default) { _ in
                self.editHistoryEntries()
        })

        alert.addAction(
            UIAlertAction(title: "navigationBar.menu.deleteall".localized, style: .default) { _ in
                self.deleteHistory()
        })
        alert.addAction(UIAlertAction(title: "navigationBar.menu.cancel".localized, style: .cancel, handler: nil))
        
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem
            popoverPresentationController.permittedArrowDirections = []
        }

        self.present(alert, animated: true)
    }
    
}

// MARK: SVKConversationViewControllerDelegate
extension SVKConversationViewController: SVKConversationViewControllerDelegate {
    
    /*
     Called when a request has been successfully delivered
     */
    public func request(_ request: String, didDelivered at: Date) {

        SVKLogger.debug("Request '\(request)' delivered at \(at)")
        SVKAnalytics.shared.log(event: "conversation_question_text")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.state == .kbdSendingText {
                SVKAudioPlayer.shared.play(resource: "received.m4a")
            }
            
            self.state = .idle
            
            if let indexPath = self.conversation.indexPath(before: self.conversation.lastElementIndexPath) {
                if var description = self.conversation[indexPath] as? SVKUserBubbleDescription {
                    description.deliveryState = .delivered
                    self.conversation[indexPath] = description
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    SVKLogger.error("Request delivered before'\(request)' must be a DCUserBubbleDescription at IndexPath \(indexPath)")
                }
            }
        }
    }
    
    /*
     Called when a request has fail
     */
    public func request(_ request: String, didFail at: Date) {
        SVKLogger.error("Request '\(request)' failed at \(at)")
        SVKAnalytics.shared.log(event: "conversation_question_text_error")
        
        DispatchQueue.main.async {
            self.state = .idle
            if !self.conversation.isEmpty,
                !self.conversation[self.conversation.sections.count - 1].elements.isEmpty {
                
                self.tableView.beginUpdates()
                if let indexPath = self.conversation.indexPath(before: self.conversation.lastElementIndexPath) {
                    var description = self.conversation[indexPath] as! SVKUserBubbleDescription
                    description.deliveryState = .notDelivered
                    self.conversation[indexPath] = description
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                self.conversation[self.conversation.sections.count - 1].elements.removeLast()
                let numberOfRows = self.conversation[self.conversation.sections.count - 1].elements.count
                self.tableView.deleteRows(at: [IndexPath(row: numberOfRows, section: self.conversation.sections.count - 1)], with: .top)
                self.tableView.endUpdates()
                
                if self.conversation[self.conversation.sections.count - 1].elements.count == 0 {
                    let indexset = IndexSet(integer: self.conversation.sections.count - 1)
                    self.conversation.removeLastSection()
                    self.tableView.deleteSections(indexset, with: .none)
                }
            }
        }
    }
    
    /*
     Called when a response is coming from Djingo
     */
    public func didReceiveResponse(_ response: SVKInvokeResult, card: SVKCard?, isActiveController: Bool) {
        SVKLogger.debug("\n<RESPONSE>\n:\(response)\n</RESPONSE>")
        SVKLogger.debug("\n<CARD>\n\(String(describing: card))\n</CARD>")

        self.removeThinkingIndicator()
        // link the response with the question
        if let requestIndexPath = (self.conversation.lastElement as? SVKUserBubbleDescription) != nil ? self.conversation.lastElementIndexPath :    self.conversation.indexPath(before: conversation.lastElementIndexPath) {
          
            if var requestDescription = conversation[requestIndexPath] as? SVKUserBubbleDescription {
                requestDescription.smarthubTraceId = response.smarthubTraceId
                requestDescription.historyID = response.conversationId
                conversation[requestIndexPath] = requestDescription
            }
        }
        var descriptions = [SVKBubbleDescription]()
        var descriptionsReplies = [SVKBubbleDescription]()
        var execDescription: SVKAssistantBubbleDescription?
        
        DispatchQueue.main.async {
            defer {
                if (isActiveController && self.isVocalizationEnabled) {
                    if execDescription?.skillId == SVKConstant.globalCommand && !self.context.isVocaliseGlobalCommandsConfirmationEnable {
                        //no vocalisation for global commands
                        SVKSpeechSession.shared.stopRunning()
                    } else {
                        SVKSpeechSession.shared.startVocalize(descriptions,delegateConversation: self.delegate) {
                            if let execDescription = execDescription {
                                if execDescription.card != nil {
                                    self.play(from: execDescription)
                                } else {
                                    self.executeAction(from: execDescription, completionHandler: nil)
                                }
                            }
                        }
                    }
                } else if isActiveController {
                    if let execDescription = execDescription {
                        if execDescription.card != nil {
                            self.play(from: execDescription)
                        } else {
                            self.executeAction(from: execDescription, completionHandler: nil)
                        }
                    }
                }
            }
            let text: String = response.text.process(with: .escape)
                .process(with: .removeUnknownTags(keepTags: ["speak","audio","sub","p","s"]))
                .process(with: .removeTag("speak"))
                .process(with: .removeTag("audio"))
                .process(with: .removeTag("sub"))
                .process(with: .removeTagValue(tag: "s", attributeName: "display", attributeValue: "none"))
                .replacingOccurrences(of: "\u{1B}", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            if let cardData = card {
                let textDescription = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
                let description = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, type: .genericCard,
                                                                card: cardData, invokeResult: response)
                descriptions.append(description)
                if self.context.dedicatedPreFixLocalisationKey == "djingo" {
                    descriptions.append(textDescription)
                }
                self.insertBubbles(from: &descriptions)
                execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                if self.isHistroyEmpty {
                    self.setEmptyMessageHidden(true, animated: false)
                }
                return
            }

            if let kit = response.skill?.data?.kit, text != "" {
                SVKLogger.debug("kit type: \(kit.type)")
                switch kit.type {
                case .deezer:
                    if let urls = kit.parameters?.urls, urls.count > 0, let card = card, let data = card.data, !data.isEmpty() {
                        // a bottom left music card bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, card: card, invokeResult: response))
                        
                        // a top left text bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response))
                        
                    } else {
                        // a default left text bubble description
                        descriptions.append(SVKAssistantBubbleDescription(bubbleStyle: .default(.left), text: text, invokeResult: response))
                    }
                    
                    self.insertBubbles(from: &descriptions)
        
                    // execute the card action if possible
                    if descriptions.count == 2, let cardDescription = descriptions.last as? SVKAssistantBubbleDescription {
                        execDescription = cardDescription
                    }
                    if self.isHistroyEmpty {
                        self.setEmptyMessageHidden(true, animated: false)
                    }
                    return
                    
//                case .audioPlayer:
//                    let description = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
//                    let audioControllerDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), type: .audioController, invokeResult: response)
//                    descriptions.append(audioControllerDescription)
//                    descriptions.append(description)
//                    self.insertBubbles(from: &descriptions)
//                    execDescription = descriptions[0] as? SVKAssistantBubbleDescription
//                    return
                
                case .system:
                    let description = SVKAssistantBubbleDescription(bubbleStyle: .default(.left), text: text, invokeResult: response)
                    descriptions.append(description)
                    self.insertBubbles(from: &descriptions)
                    execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                    if self.isHistroyEmpty {
                        self.setEmptyMessageHidden(true, animated: false)
                    }
                    return

                case .timer:
                    if let card = card, let data = card.data, !data.isEmpty() {
                        let timerDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left), text: text, card: card, invokeResult: response)
                        var description = SVKAssistantBubbleDescription(bubbleStyle: .top(.left), text: text, invokeResult: response)
                        description.origin = .conversation
                        descriptions.append(timerDescription)
                        descriptions.append(description)
                        self.insertBubbles(from: &descriptions)
                        execDescription = descriptions[1] as? SVKAssistantBubbleDescription
                    } else {
                        var description = SVKAssistantBubbleDescription(bubbleStyle: .default(.left), text: text, invokeResult: response)
                        description.origin = .conversation
                        descriptions.append(description)
                        
                        self.insertBubbles(from: &descriptions)
                        execDescription = descriptions[0] as? SVKAssistantBubbleDescription
                    }
                    if self.isHistroyEmpty {
                        self.setEmptyMessageHidden(true, animated: false)
                    }
                    return

                default:
                    SVKLogger.warn("Kit '\(kit.name)' not implemented")
                }
            }
            let timestamp = SVKTools.iso8061DateFormatter.string(from: Date())
            var bubbleIndex = 0
            
            let responseBubble = buildDescriptions(text, timestamp, nil, response, card, &bubbleIndex, false, self.context.dedicatedPreFixLocalisationKey)
            
            if ((SVKConstant.isResponseContainsSkillError(status: response.status) && !self.context.isMisunderstoodRequestRecommendationHackEnable) || (SVKConstant.isResponseContainsMisunderstoodError(status: response.status) && !self.context.isEmptyRequestRecommendationHackEnable)) {
                //no response needed
                return
            } else if responseBubble.first?.skillId == SVKConstant.globalCommand && !self.context.isShowGlobalCommandsConfirmationEnable {
                //Global commands text not needed as response
                return
            }
            descriptions = responseBubble
            execDescription = descriptions.first as? SVKAssistantBubbleDescription
            
            if let replies = response.quickReplies?.replies {
                replies.forEach { (reply) in
                    var messageDescription = SVKUserBubbleDescription(bubbleStyle: .default(.left), text: reply.title, timestamp: timestamp)
                    messageDescription.historyID = execDescription?.historyID
                    messageDescription.markAsReco()
                    descriptionsReplies.append(messageDescription)
                }
                
            }

            /// Sets the bubbles style
            descriptions.setBubblesStyle()
            descriptions.append(contentsOf: descriptionsReplies)
            descriptions.reverse()
            
            // insert the bubbles in the table view
            self.insertBubbles(from: &descriptions,animation: .fade)

            if card?.data?.layout == .mediaPlayer {
                let description = descriptions.first {
                    if let bubbleDescription = $0 as? SVKAssistantBubbleDescription,
                        let _ = bubbleDescription.skill as? SVKGenericAudioPlayerSkill {
                        return true
                    }
                    return false
                }
                
                execDescription = description as? SVKAssistantBubbleDescription
                if let execDescription = execDescription {
                    self.prepareAction(from: execDescription)
                }
            }
            // get the session id
            if descriptions.count > 0, let sessionDescription = descriptions.last as? SVKAssistantBubbleDescription {
                self.context.sessionId = sessionDescription.sessionID
            }
            if self.isHistroyEmpty {
                self.setEmptyMessageHidden(true, animated: false)
            }
            
        }
    }

    /*
     Called when a text has been vocalized
     */
    public func didVocalizeText(_ text: String, stream: Data) {
        SVKSpeechSession.shared.startVocalize(text, stream: stream)
    }
    

    /**
     Insert bubbles in the conversation or in the history
     - parameter descriptions: bubbles descriptions
     - parameter position: the position from where the bubbles must be inserted
     - parameter section: the section in where the bubbles must be inserted
     - parameter scrollEnabled: true if the tableView should scrolls after insertions. Default is true
     */
    func insertBubbles(from descriptions: inout [SVKBubbleDescription], at position: Int = Int.max, in section: Int = Int.max, scrollEnabled: Bool = true, shouldClear: Bool = false,idForScrool: String? = nil,animation: UITableView.RowAnimation = .none) {
        
        guard descriptions.count > 0 else { return }
        
        /// take a snap shot of the screen in order to mask the scrolling caused by the rows insertion
        var snapshot: UIView? = nil
        if animation == .none, let view = self.tableView.snapshotView(afterScreenUpdates: true) {
            self.view.addSubview(view)
            snapshot = view
        }
        if shouldClear == true {
            clear(animated: false)
        }
        
        // updating the tableview
        var numberOfInsertedRows = 0
        var numberOfInsertedSections = 0
        var indexPath = IndexPath(row: position, section: section)
        if position == Int.max || section == Int.max {
            indexPath = self.conversation.endIndex
        }
        for (i,d) in descriptions.enumerated() {
            
            self.tableView.beginUpdates()
            var description = d
            if let descriptionTimestamp = SVKTools.date(from: description.timestamp), !description.isEmpty {
                description.bubbleKey = self.nextBubbleKey
                if (self.conversation.sections.count == 0) {
                    // Creation de la premiere section si besoin
                    self.conversation.insert(SVKSectionDescription(timestamp: description.timestamp), at: 0)
                    self.tableView.insertSections(IndexSet(integer: 0), with: animation)
                    indexPath = IndexPath(row: 0, section: 0)
                }
                
                let sectionDescription = self.conversation[indexPath.section]
                if sectionDescription.shouldContains(bubbleDescription: description) {
                    // l'insertion se fait en haut de la section
                    self.conversation[indexPath.section].elements.insert(description, at: indexPath.row)
                    self.tableView.insertRows(at: [indexPath], with: animation)
                    if (numberOfInsertedSections == 0) {
                        numberOfInsertedRows += 1
                    }
                } else if indexPath.section - 1 >= 0, self.conversation[indexPath.section - 1 ].shouldContains(bubbleDescription: description) {
                    let newSection = indexPath.section - 1
                    let newRow = self.conversation[newSection].elements.count
                    self.conversation[newSection].elements.insert(description, at: self.conversation[newSection].elements.count)
                        indexPath = IndexPath(row: newRow, section: newSection)
                        self.tableView.insertRows(at: [indexPath], with: animation)
                        numberOfInsertedSections += 1
                } else if indexPath.section + 1 < self.conversation.sections.count, self.conversation[indexPath.section + 1 ].shouldContains(bubbleDescription: description) {
                    let newSection = indexPath.section + 1
                    let newRow = 0
                    self.conversation[newSection].elements.insert(description, at: self.conversation[newSection].elements.count)
                        indexPath = IndexPath(row: newRow, section: newSection)
                        self.tableView.insertRows(at: [indexPath], with: animation)
                        numberOfInsertedSections += 1
                } else if sectionDescription.timestamp < descriptionTimestamp {
                    // Ajout d'une nouvelle section tout en bas et insertion dans la nouvelle section
                    self.conversation.append(SVKSectionDescription(timestamp: description.timestamp))
                    self.tableView.insertSections(IndexSet(integer: indexPath.section + 1), with: animation)
                    indexPath = IndexPath(row: 0, section: indexPath.section + 1)
                    self.conversation[indexPath.section].elements.insert(description, at: 0)
                    self.tableView.insertRows(at: [indexPath], with: animation)
                    numberOfInsertedSections += 1
                } else {
                    // Ajout d'une nouvelle section en haut et insertion dans la nouvelle section
                    self.conversation.insert(SVKSectionDescription(timestamp: description.timestamp), at: indexPath.section )
                    self.tableView.insertSections(IndexSet(integer: indexPath.section ), with: animation)
                    indexPath = IndexPath(row: 0, section: indexPath.section)
                    self.conversation[indexPath.section].elements.insert(description, at: 0)
                    self.tableView.insertRows(at: [indexPath], with: animation)
                    numberOfInsertedSections += 1
                }
            
            } else {
                SVKLogger.warn("DATA NOT INSERTED: \(description)")
            }
            descriptions[i] = description
            self.tableView.endUpdates()
        }

        /// force the tableView to update it's content size
        self.tableView.layoutIfNeeded()
        if idForScrool != nil, let firstIndex = self.conversation.firstIndex(where: { $0.historyID == idForScrool || $0.smarthubTraceId == idForScrool}) {
            let indexPaths = self.conversation.indexPathOfElements(from: firstIndex, groupedBy: { $0.historyID == idForScrool || $0.smarthubTraceId == idForScrool })
            if indexPaths.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    let index = indexPaths[indexPaths.count - 1]
                    snapshot?.removeFromSuperview()
                    var scrollIndex = index
                    scrollIndex = scrollIndex == self.conversation.endIndex ? self.conversation.lastElementIndexPath : scrollIndex
                    self.tableView.scrollToRow(at: scrollIndex, at: .none, animated: true)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    let row = self.conversation.sections[self.conversation.sections.count - 1].elements.count - 1
                    let section = self.conversation.sections.count - 1
                    self.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .bottom, animated: true)
                    snapshot?.removeFromSuperview()
                }
            }
        } else if shouldClear || position != 0 || section != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                let count = self.conversation.sections.count
                if scrollEnabled, count > 0 {
                    let row = self.conversation.sections[count - 1].elements.count - 1
                    let section = self.conversation.sections.count - 1
                    // we double the scrollToRow because it failed the first time when we ask for somthing and then do a refresh for newer item
                    // and next the ask failed to scroll
                    self.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .bottom, animated: false)
                    self.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .bottom, animated: false)
                }
                snapshot?.removeFromSuperview()
            }
        } else if position == 0 {
            self.tableView.contentInset.top = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                if scrollEnabled {
                    let index = self.conversation.indexPath(before: IndexPath(row: numberOfInsertedRows, section: numberOfInsertedSections))
                    if let index = index {
                        self.tableView.scrollToRow(at: IndexPath(row: index.row, section: index.section), at: .top, animated: false)
                    }
                }
                snapshot?.removeFromSuperview()
            }
        }
        // reposition the load more control
        self.loadNewerControl?.setNeedsLayout()
        self.loadOlderControl?.setNeedsLayout()
    }
    
    /**
     Remove bubbles in the conversation or in the history from the indexPath
     The function removes data from the [data] ans the tableView
     - parameter bounds: bubbles descriptions
     */
    func removeBubbles(from index: IndexPath) {
        self.tableView.beginUpdates()
        let rowCount = self.conversation[index.section].elements.count
        self.conversation[index.section].elements.removeLast(rowCount - index.row)
        var indexes = [IndexPath]()
        for row in index.row..<rowCount {
            indexes.append(IndexPath(row: row, section: index.section))
        }
        self.tableView.deleteRows(at: indexes, with: .none)
        let sectionCount = self.conversation.sections.count
        if (sectionCount - index.section > 1) {
            let indexset = IndexSet(integersIn: (index.section + 1)..<sectionCount)
            self.conversation.removeLastSection(k: sectionCount - index.section - 1)
            self.tableView.deleteSections(indexset, with: .none)
        }
        if (self.conversation[index.section].elements.count == 0) {
            self.conversation.removeLastSection()
            self.tableView.deleteSections(IndexSet(integer: index.section), with: .none)
        }
        self.tableView.endUpdates()
    }
    
}

extension SVKConversationViewController: SVKDeleteDelegate {
    func deleteSelectedMessages(conversations: SVKConversationDescription) {
        conversation = conversations
        deleteSelectedHistoryEntries()
    }
    
    func cancelRequest() {
        self.loadNewerControl?.trigger()
    }
}

