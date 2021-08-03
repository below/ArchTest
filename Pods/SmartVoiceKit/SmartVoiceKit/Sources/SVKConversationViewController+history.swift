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

public protocol SVKUserProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Delete some history entries
    func delete(_ completionHandler: @escaping (_ success: Bool) -> Void)
}
public extension SVKUserProtocol {

    /**
     Sends the received text to the backend
     - parameter completionHandler: a completion handler called with the user is deleted
     */
    func delete(_ completionHandler: @escaping (_ success: Bool) -> Void) {
        deleteInternal(retry: true, completionHandler: completionHandler)
    }
    
    func deleteInternal(retry:Bool, completionHandler: @escaping (_ success: Bool) -> Void) {
        SVKAPIUserRequest(method: .delete).perform() { result in
            switch result {
            case .success:
                completionHandler(true)
            case .error(let code, let status, let message,_):
                SVKLogger.error("delete user error: [code: \(code)][status: \(status)][message:\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            deleteInternal(retry: false, completionHandler: completionHandler)
                        } else {
                            completionHandler(false)
                        }
                    }
                }
                completionHandler(false)
            }
        }
    }
}

public typealias SVKHistoryProtocol = SVKHistoryDataSoureProtocol & SVKHistoryScrollViewDelegate

public protocol SVKDeleteHistoryProtocol {
    /// Delete some history entries
    func deleteHistoryEntries(ids: [String],completionHandler: @escaping (_ success: Bool) -> Void)

    /// Delete all history entries
    @available(*,deprecated)
    func deleteAllHistoryEntries(_ completionHandler: @escaping (_ success: Bool) -> Void)
    func deleteAllHistoryEntries(serialNumber: String?, completionHandler: @escaping (_ success: Bool) -> Void)
}

public protocol SVKHistoryDataSoureProtocol: SVKDeleteHistoryProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Load messages from the history
    func loadHistoryEntries(from date: Date, direction: SVKFetchHistoryDirection, numberOfMessages: Int, suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void)
    
    /// Send a feedback on a history entry
    func sendFeedback(_ feedback: SVKFeedback, on historyId: String,
                      completionHandler: @escaping (SVKHistoryEntryShort?) -> Void)

    /// Asks the delegate if feedbacks are authorized by the user
    func canSendFeedback(completionHandler: @escaping (_ authorized: Bool?) -> Void)

    /// Tells the delegate that the user authorize or not feedbacks
    func authorizeFeedback(completionHandler: @escaping (_ success: Bool) -> Void)
    
    /// Ask the delegate for the serial number device list
    func getDeviceList(completionHandler: @escaping ([String]) -> Void)
    
    /// Ask the delegate for the device metadata
    func getDeviceMetadata(from serialNumber: String, completionHandler: @escaping (SVKDeviceMetadata?) -> Void)
    
    /// Tells the delegate that the url should be open by the Application. The application can decide to open the url or let the SDK do it. Deepkins must be processed by the application.
    func open(url: String, bubbleDescription: SVKAssistantBubbleDescription?) -> SVKOpenUrlResult
}

public enum SVKOpenUrlResult {
    case opened
    case failed
    case unprocessed
}

public extension SVKHistoryDataSoureProtocol {
    /// the default implementation does nothing
    func loadHistoryEntries(from date: Date, direction: SVKFetchHistoryDirection, numberOfMessages: Int,suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void) {
        loadHistoryEntriesInternal(retry: true, from: date, direction: direction, numberOfMessages: numberOfMessages, suppressError: suppressError, deviceSerialNumber: deviceSerialNumber, completionHandler: completionHandler)
    }
        
    func loadHistoryEntriesInternal(retry: Bool,from date: Date, direction: SVKFetchHistoryDirection, numberOfMessages: Int,suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void) {
        
        SVKAPIHistoryRequest(method: .get(date, numberOfMessages, direction, suppressError, deviceSerialNumber)).perform() { result in
            switch result {
            case .success(_, let result as SVKHistoryEntries):
                completionHandler(result, nil)
            
            case .success(let code, _):
                SVKLogger.debug("fetch terminated with code: \(code)")
                completionHandler(nil, nil)
                
            case .error(let code, let status, let message,_):
                SVKLogger.error("fetch history error: [code: \(code)][status: \(status)][message:\(message)]")
                
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    DispatchQueue.main.async {
                        secureTokenDelegate.didInvalideToken { (success) in
                            if success {
                                loadHistoryEntriesInternal(retry: false, from: date, direction: direction, numberOfMessages: numberOfMessages, suppressError: suppressError, deviceSerialNumber: deviceSerialNumber, completionHandler: completionHandler)
                            } else {
                                completionHandler(nil, nil)
                            }
                        }
                    }
                } else if let statusCode = Int(status), SVKHTTPStatusCode(rawValue: statusCode) == .networkConnection {
                    completionHandler(nil, message)
                } else {
                    completionHandler(nil, nil)
                }
            }
        }
    }
    func deleteHistoryEntries(ids : [String], completionHandler: @escaping (_ success: Bool) -> Void) {
        deleteHistoryEntriesInternal(retry: true, ids: ids, completionHandler: completionHandler)
    }
    
    func deleteHistoryEntriesInternal(retry: Bool, ids : [String], completionHandler: @escaping (_ success: Bool) -> Void) {
        
        SVKAPIHistoryRequest(method: .post(ids)).perform() { result in
            switch result {
            case .success:
                completionHandler(true)
            case .error(let code, let status, let message,_):
                SVKLogger.error("delete history entries error: [code: \(code)][status: \(status)][message:\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            deleteHistoryEntriesInternal(retry: false, ids: ids, completionHandler: completionHandler)
                        } else {
                            completionHandler(false)
                        }
                    }
                }
                completionHandler(false)
            }
        }
    }
    
    func deleteAllHistoryEntries(serialNumber: String?, completionHandler: @escaping (_ success: Bool) -> Void) {
        deleteAllHistoryEntriesInternal(retry: true, serialNumber: serialNumber, completionHandler: completionHandler)
    }
    
    func deleteAllHistoryEntries(_ completionHandler : @escaping (_ success: Bool) -> Void) {
        deleteAllHistoryEntries(serialNumber: nil, completionHandler: completionHandler)
    }
    
    func deleteAllHistoryEntriesInternal(retry: Bool, serialNumber: String?, completionHandler : @escaping (_ success: Bool) -> Void) {
        
        SVKAPIHistoryRequest(method: .delete(serialNumber)).perform() { result in
            switch result {
            case .success:
                completionHandler(true)
            case .error(let code, let status, let message,_):
                SVKLogger.error("delete history all entries error: [code: \(code)][status: \(status)][message:\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            deleteAllHistoryEntriesInternal(retry: false, serialNumber: serialNumber, completionHandler: completionHandler)
                        } else {
                            completionHandler(false)
                        }
                    }
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    
    func sendFeedback(_ feedback: SVKFeedback, on historyId: String, completionHandler: @escaping (SVKHistoryEntryShort?) -> Void) {
        sendFeedbackInternal(retry: true, feedback: feedback, on: historyId, completionHandler: completionHandler)
    }
    
    func sendFeedbackInternal(retry: Bool, feedback: SVKFeedback, on historyId: String, completionHandler: @escaping (SVKHistoryEntryShort?) -> Void) {
        SVKAPIHistoryRequest(method: .put(historyId, feedback)).perform() { result in
            switch result {
            case .success(_, let result as SVKHistoryEntryShort):
                completionHandler(result)
            case .success(let code, _):
                SVKLogger.debug("sendFeedback terminated with code: \(code)")
                completionHandler(nil)
            case .error(let code, let status, let message,_):
                SVKLogger.error("sendFeedback error: [code: \(code)][status: \(status)][message:\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            sendFeedbackInternal(retry: false, feedback: feedback, on: historyId, completionHandler: completionHandler)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    func canSendFeedback(completionHandler: @escaping (_ authorized: Bool?) -> Void)  {
        canSendFeedbackinternal(retry: true, completionHandler:completionHandler)
    }
    
    func canSendFeedbackinternal(retry: Bool, completionHandler: @escaping (_ authorized: Bool?) -> Void)  {
        SVKAPIUserAgreementsRequest().perform { result in
            switch result {
            case .success(_, let agreements as SVKUserAgreements):
                let authorized = agreements.elements.filter {
                    SVKContext.consentFeedbackCheckRaw.contains($0.tncId)
                    }
                    .reduce(true, { (authorized, agreement) -> Bool in
                        return authorized && agreement.userAgreement ?? false
                    })
                completionHandler(authorized)

            case .success(let code, _):
                SVKLogger.debug("canSendFeedback terminated with code: \(code)")
                completionHandler(nil)

            case .error(let code, let status, let message,_):
                SVKAnalytics.shared.log(event: "myactivity_feedback_rights_acceptance_error")
                SVKLogger.error("canSendFeedback error: [code: \(code)][status: \(status)][message:\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            canSendFeedbackinternal(retry: false, completionHandler:completionHandler)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    func authorizeFeedback(completionHandler: @escaping (_ success: Bool) -> Void) {
        authorizeFeedbackInternal(retry: true, completionHandler: completionHandler)
    }
    func authorizeFeedbackInternal(retry: Bool, completionHandler: @escaping (_ success: Bool) -> Void) {
        var agreements:[SVKTNCAgreement] = []
        SVKContext.consentFeedbackCheckRaw.forEach { (tncId) in
            let tncAgreement = SVKTNCAgreement(true,tncId)
            agreements.append(tncAgreement)
        }
        SVKAPIUserAgreementsRequest(method: .post(agreements)).perform { result in
            switch result {
            case .success(_, _):
                completionHandler(true)
            case .error(let code, let status, let message,_):
                SVKLogger.error("[\(code)]:[\(status)]:[\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            authorizeFeedbackInternal(retry: false, completionHandler: completionHandler)
                        } else {
                            completionHandler(false)
                        }
                    }
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    
    func getDeviceList(completionHandler: @escaping ([String]) -> Void) {
        getDeviceListInternal(retry: true, completionHandler: completionHandler)
    }
    
    func getDeviceListInternal(retry: Bool, completionHandler: @escaping ([String]) -> Void) {
        SVKAPIDeviceRequest(method: .get).perform { result in
            switch result {
                case .success(_, let result as SVKDevices):
                    completionHandler(result.devices)
               
            case .error(let code, let status, let message,_):
                SVKLogger.error("[\(code)]:[\(status)]:[\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            getDeviceListInternal(retry: false, completionHandler: completionHandler)
                        } else {
                            completionHandler([String]())
                        }
                    }
                } else {
                    completionHandler([String]())
                }
            case .success(_, _):
                completionHandler([String]())
            }
        }
    }
    
    func getDeviceMetadata(from serialNumber: String, completionHandler: @escaping (SVKDeviceMetadata?) -> Void) {
        getDeviceMetadataInternal(retry: true, from: serialNumber, completionHandler: completionHandler)
    }
    
    func getDeviceMetadataInternal(retry: Bool, from serialNumber: String, completionHandler: @escaping (SVKDeviceMetadata?) -> Void) {
        SVKAPIDeviceMetadataRequest(method: .get(serialNumber)).perform { result in
            switch result {
                case .success(_, let result as SVKDeviceMetadata):
                    completionHandler(result)
               
            case .error(let code, let status, let message,_):
                SVKLogger.error("[\(code)]:[\(status)]:[\(message)]")
                if let errorCode = SVKApiErrorCode(rawValue: status), errorCode == .missingToken || errorCode == .invalidExternalToken, retry {
                    secureTokenDelegate.didInvalideToken { (success) in
                        if success {
                            getDeviceMetadataInternal(retry: false, from: serialNumber, completionHandler: completionHandler)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    completionHandler(nil)
                }
                
            case .success(_, _):
                completionHandler(nil)
            }
        }
    }
    
    func open(url: String, bubbleDescription: SVKAssistantBubbleDescription?) -> SVKOpenUrlResult {
        return .unprocessed
    }
}


/**
 An extension that manages history stuff
 
 */
extension SVKConversationViewController {
    /**
     Display a welcome message on conversation mode or indicate to the user that
     the history is empty.
     */
    func displayMessageForEmptyHistory(animated: Bool = true) {
        isHistroyEmpty = true
        if self.displayMode.contains(.conversation),filterValue.range == .all, filterValue.device?.serialNumber == nil, !SVKConversationAppearance.shared.isFirstTimeWelcomeMessageShown, self.displayMode.contains(.conversation) {
            self.insertWelcomeMessage()
            isWelcomeMsgAdded = true
            isPrimaryWelcomeMsgAdded = true
            UserDefaults.standard.set(true, forKey: "WelcomeMessage")
            SVKConversationAppearance.shared.isFirstTimeWelcomeMessageShown = !SVKConversationAppearance.shared.isFirstTimeWelcomeMessageShown
            SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable = !SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable
        } else if filterValue.range == .all,
                  filterValue.device?.serialNumber == nil,
                  SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable, self.displayMode.contains(.conversation) {
            self.insertSecondaryWelcomeMessage()
            isWelcomeMsgAdded = true
            SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable = !SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable
        } else {
            let emptyKey: String = self.context.dedicatedPreFixLocalisationKey + ( filterValue.range == .all && filterValue.device?.serialNumber == nil ? ".history.empty.title":".history.filter.empty.title")
            let emptyTxtKey: String = self.context.dedicatedPreFixLocalisationKey + ( filterValue.range == .all && filterValue.device?.serialNumber == nil ? ".history.empty.text":".history.filter.empty.text")
            let msg = (emptyKey.localized, emptyTxtKey.localized)
            self.setEmptyMessageHidden(false, animated: animated,message: msg)
        }
    }
    
    /**
     Scroll to the bottom of the history if requested (happens change tenant is changing for eg)
     */
    internal func scrollToBottomIfNeeded() {
        if self.needsScrollToBottom && self.conversation.sections.count > 0 {
            self.needsScrollToBottom = false
            let index = self.conversation.lastElementIndexPath
            if index != self.conversation.startIndex {
                if #available(iOS 13.0, *){
                    self.tableView.scrollToRow(at: index, at: .bottom, animated: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
                        self?.tableView.scrollToRow(at: index, at: .bottom, animated: false)
                    }
                }
            }
        }
    }
    
    /**
     Refresh the history from the older messages
     */
    @objc internal func loadHistoryOlderMessages(loadMoreControl: SVKLoadMoreControl) {
        
        guard userInputViewController?.state != .kbdSendingText,
            userInputViewController?.state != .sttSendingText, userInputViewController?.state != .sttListening,
            userInputViewController?.state != .sttStarting, userInputViewController?.state != .sttStopping,
            userInputViewController?.state != .sttRecognizing, !isHistoryRefreshing else {
                loadMoreControl.beginLoading()
                loadMoreControl.endLoading(animated: false)
                return }
        
        self.isHistoryRefreshing = true
        SVKAnalytics.shared.log(event: "myactivity_refresh_past")
        SVKLogger.debug("oldest: \(oldest)")
        
        self.setEmptyMessageHidden(true, animated: false)
        
        loadMoreControl.beginLoading()
        let deviceSerialNumber = showOnlyDeviceHistory ? SVKUserIdentificationManager.shared.serialNumber : self.filterValue.device?.serialNumber
        delegate?.loadHistoryEntries(from: oldest, direction: .before, numberOfMessages: maxMessagesToLoad,suppressError: self.context.isSuppressErrorHistory, deviceSerialNumber: deviceSerialNumber) { result, errorMessage in
            
            DispatchQueue.main.async {
                
                guard var history = result else {
                    SVKAnalytics.shared.log(event: "myactivity_view_error")
                    self.clear()
                    let titleKey: String = self.context.dedicatedPreFixLocalisationKey + (".history.empty.title")
                    self.setEmptyMessageHidden(false, animated: true, message: (titleKey.localized, errorMessage ?? "history.error".localized))
                    self.refreshTableviewHeaderAndFooter()
                    loadMoreControl.endLoading(animated: true) {
                        self.isHistoryRefreshing = false
                    }
                    return
                }
                history.checkTimestampOfAllEntry()
                SVKLogger.debug("\(history.entries.count) item(s) fetched from the history")
                
                let beginDate = self.beginFilterDate()
                
                
                var isOlderReachedInfilter = false
                var entriesFiltered = history.entries.filter { (entry) -> Bool in
                    if !(entry.timestampNotFormated?.isEmpty ?? false),
                       let date = SVKTools.date(from: entry.timestampNotFormated ?? "") {
                        if beginDate < date {
                        return true
                        } else {
                            isOlderReachedInfilter = true
                            return false
                        }
                    } else {
                    return false
                    }
                }
                //Sort array with timestamp value
                entriesFiltered = entriesFiltered.sorted(by: {
                    if let date = SVKTools.date(from: $0.timestampNotFormated ?? ""), let nextDate = SVKTools.date(from: $1.timestampNotFormated ?? "") {
                        return date > nextDate
                    }
                    return false
                })
                
                self.isOlderReached = history.entries.count < self.maxMessagesToLoad || isOlderReachedInfilter
                
                SVKLogger.debug("\(entriesFiltered.count) item(s) filtered from the history")
                
                loadMoreControl.endLoading(animated: entriesFiltered.count == 0) {
                    defer {
                        self.isHistoryRefreshing = false
                    }
                    if entriesFiltered.count == history.entries.count , entriesFiltered.count != 0  {
                        let timestampOldest = (history.oldest?.requestTimestamp ?? history.oldest?.responseTimestamp) ?? ""
                        let timestampNewest = (history.newest?.requestTimestamp ?? history.newest?.responseTimestamp) ?? ""
                        self.oldestId = (timestampOldest < timestampNewest ? history.oldest?.id : history.newest?.id) ?? self.oldestId
                    } else {
                            self.oldestId = entriesFiltered.last?.id
                    }
                    
                    var descriptions = entriesFiltered
                        .reversedHistoryDescriptions(isHideErrorInteractionsEnabled: self.isHideErrorInteractionsEnabled,isHideDeviceDefaultNameEnabled:  self.isHideDeviceDefaultNameEnabled, skin: self.context.dedicatedPreFixLocalisationKey, isHideGlobalCommand: !self.context.isShowGlobalCommandsConfirmationEnable)
                        .updateIsTimestampHidden(with: self.groupedMessageDelay, reversedOrder: false)
                        .updateIsAssistantLineSperatorHidden(reversedOrder: false)
                    
                    self.insertBubbles(from: &descriptions, at: 0, in: 0)
                    self.groupingErrors()
                    if (self.tableView.isEditing) {
                      self.expandAllError()
                    }
                    // Be careful insertBubble do a clear =W oldest is reset
                    self.oldest = entriesFiltered.last?.timestampFormated ?? self.oldest
                    SVKLogger.debug("New oldest: \(self.oldest)")
                    if self.conversation.count == 0 {
                        self.displayMessageForEmptyHistory(animated: true)
                    }
                    self.refreshTableviewHeaderAndFooter()
                }
                SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable = !SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable
            }
        }
        
    }
    
    internal func endFilterDate () -> Date {
        switch filterValue.range {
        case .all,.last7days,.thisMonth,.today:
            return Date.distantFuture
        case .lastMonth:
            let calendar = Calendar.current
            let components = DateComponents(day:1)
            let endOfTheMonth = calendar.nextDate(after:Date(), matching: components, matchingPolicy: .nextTime,direction: .backward)!
            return endOfTheMonth
        case .yesterday:
            let y = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
            return y
        }
    }
    
    internal func beginFilterDate () -> Date {
        switch filterValue.range {
        case .all:
            return Date.distantPast
        case .today:
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        case .last7days :
            let today = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
            let last7DayDate = Calendar.current.date(byAdding: .day, value: -6, to: today)
                  
            return last7DayDate ?? Date() // should always returning last7DayDate
        case .thisMonth :
            let calendar = Calendar.current
            let components = DateComponents(day:1)
            let endOfTheMonth = calendar.nextDate(after:Date(), matching: components, matchingPolicy: .nextTime,direction: .backward)!
            return endOfTheMonth
        case .lastMonth:
            let calendar = Calendar.current
            let components = DateComponents(calendar: calendar, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)
            let endOfTheMonth = calendar.nextDate(after:Date(), matching: components, matchingPolicy: .nextTime,direction: .backward)!
            let endOfLastMonth = calendar.date(byAdding: .month, value: -1, to: endOfTheMonth)
            return endOfLastMonth ?? Date() // should always returning endOfLastMonth
        case .yesterday:
            let today = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
            let components = DateComponents(day:-1)
            let yesterdayDate = Calendar.current.date(byAdding: components, to: today)

            return yesterdayDate ?? Date() // should always returning yesterdayDate
        }
    }
    /**
     Refresh the history from the newer messages
     */
    @objc internal func loadHistoryNewerMessages(loadMoreControl: SVKLoadMoreControl) {
        guard userInputViewController?.state != .kbdSendingText,
            userInputViewController?.state != .sttSendingText, userInputViewController?.state != .sttListening,
            userInputViewController?.state != .sttStarting, userInputViewController?.state != .sttStopping,
            userInputViewController?.state != .sttRecognizing, !isHistoryRefreshing else {
                loadMoreControl.beginLoading()
                loadMoreControl.endLoading(animated: false)
                return
        }
        
        self.isWelcomeMsgAdded = false
        self.isPrimaryWelcomeMsgAdded = false
        self.isHistoryRefreshing = true
        SVKAnalytics.shared.log(event: "myactivity_refresh_present")
        SVKLogger.debug("newest: \(newest)")
        self.setEmptyMessageHidden(true, animated: false)
        loadMoreControl.beginLoading()
        let date = endFilterDate()
        let deviceSerialNumber = showOnlyDeviceHistory ? SVKUserIdentificationManager.shared.serialNumber : self.filterValue.device?.serialNumber
        delegate?.loadHistoryEntries(from: date, direction: .before, numberOfMessages: maxMessagesToLoad,suppressError: self.context.isSuppressErrorHistory, deviceSerialNumber: deviceSerialNumber) { result, errorMessage in
            
            DispatchQueue.main.async {
                guard var history = result else {
                    SVKAnalytics.shared.log(event: "myactivity_view_error")
                    self.clear()
                    let titleKey: String = self.context.dedicatedPreFixLocalisationKey + (".history.empty.title")
                    self.setEmptyMessageHidden(false, animated: true, message: (titleKey.localized, errorMessage ?? "history.error".localized))
                    self.refreshTableviewHeaderAndFooter()
                    loadMoreControl.endLoading(animated: true) {
                        self.isHistoryRefreshing = false
                        self.loadOlderControl?.isHidden = false
                        self.loadOlderControl?.isEnabled = true
                        self.loadNewerControl?.isHidden = false
                        self.loadNewerControl?.isEnabled = true
                    }
                    return
                }
                history.checkTimestampOfAllEntry()
                SVKLogger.debug("\(history.entries.count) item(s) fetched from the history")
                
                let beginDate = self.beginFilterDate()
                
                var isOlderReachedInfilter = false
                var entriesFiltered = history.entries.filter { (entry) -> Bool in
                    if !(entry.timestampNotFormated?.isEmpty ?? false),
                        let date = SVKTools.date(from: entry.timestampNotFormated ?? "") {
                        if beginDate < date {
                        return true
                        } else {
                            isOlderReachedInfilter = true
                            return false
                        }
                    } else {
                    return false
                    }
                }
                //Sort array with timestamp value
                entriesFiltered = entriesFiltered.sorted(by: {
                    if let date = SVKTools.date(from: $0.timestampNotFormated ?? ""), let nextDate = SVKTools.date(from: $1.timestampNotFormated ?? "") {
                        return date > nextDate
                    }
                    return false
                })
                self.isOlderReached = history.entries.count < self.maxMessagesToLoad || isOlderReachedInfilter
                SVKLogger.debug("\(entriesFiltered.count) item(s) left after the filter from the history")
                loadMoreControl.endLoading(animated: entriesFiltered.count == 0) {
                    defer {
                        self.isHistoryRefreshing = false
                    }
                    if entriesFiltered.count > 0  {

                        var descriptions = entriesFiltered.reversedHistoryDescriptions(isHideErrorInteractionsEnabled: self.isHideErrorInteractionsEnabled,isHideDeviceDefaultNameEnabled: self.isHideDeviceDefaultNameEnabled, skin: self.context.dedicatedPreFixLocalisationKey, isHideGlobalCommand: !self.context.isShowGlobalCommandsConfirmationEnable).updateIsTimestampHidden(with: self.groupedMessageDelay, reversedOrder: false)
                        
                        if descriptions.count > 0 {
                            self.insertBubbles(from: &descriptions,at: 0, in: 0, scrollEnabled: true, shouldClear: true,animation: .none)
                            SVKConversationAppearance.shared.isSecondTimeWelcomeMessageApplicable = false
                        } else {
                            self.clear(animated: false)
                            self.displayMessageForEmptyHistory(animated: true)
                        }
                        
                        if (self.tableView.isEditing) {
                          self.expandAllError()
                        }
                        // Be careful insertBubble do a clear =W oldest is reset
                        if entriesFiltered.count == history.entries.count , entriesFiltered.count != 0  {
                            let timestampOldest = (history.oldest?.requestTimestamp ?? history.oldest?.responseTimestamp) ?? ""
                            let timestampNewest = (history.newest?.requestTimestamp ?? history.newest?.responseTimestamp) ?? ""
                            self.oldestId = (timestampOldest < timestampNewest ? history.oldest?.id : history.newest?.id) ?? self.oldestId
                        } else {
                            self.oldestId = entriesFiltered.last?.id
                        }
                        // get the session id
                        let assitantDescription = descriptions.last as? SVKAssistantBubbleDescription
                        self.context.sessionId = assitantDescription?.sessionID

                        
                        self.newest = history.newestTimestamp ?? self.newest
                        self.oldest = history.oldestTimestamp ?? self.oldest
                        SVKLogger.debug("New oldest: \(self.oldest)")
                        SVKLogger.debug("New newest: \(self.newest)")
                        self.refreshTableviewHeaderAndFooter()
                        switch self.filterValue.range {
                            case .all:
                                let shouldNotVisible = self.conversation.sections.count > 0 && self.isOlderReached
                                self.loadOlderControl?.isHidden = shouldNotVisible
                                self.loadOlderControl?.isEnabled = !shouldNotVisible
                                self.loadNewerControl?.isHidden = false
                                self.loadNewerControl?.isEnabled = true
                            case .last7days where self.conversation.sections.count > 0 && self.isOlderReached,
                                 .thisMonth where self.conversation.sections.count > 0 && self.isOlderReached,
                                 .today where self.conversation.sections.count > 0 && self.isOlderReached:
                                self.loadOlderControl?.isHidden = true
                                self.loadOlderControl?.isEnabled = false
                                self.loadNewerControl?.isHidden = false
                                self.loadNewerControl?.isEnabled = true
                            case .last7days where !(self.conversation.sections.count > 0 && self.isOlderReached),
                                 .thisMonth where !(self.conversation.sections.count > 0 && self.isOlderReached),
                                 .today where !(self.conversation.sections.count > 0 && self.isOlderReached):
                                self.loadOlderControl?.isHidden = false
                                self.loadOlderControl?.isEnabled = true
                                self.loadNewerControl?.isHidden = false
                                self.loadNewerControl?.isEnabled = true
                            case .lastMonth where !(self.conversation.sections.count > 0 && self.isOlderReached):
                                self.loadOlderControl?.isHidden = false
                                self.loadOlderControl?.isEnabled = true
                                self.loadNewerControl?.isHidden = true
                                self.loadNewerControl?.isEnabled = false
                            case .lastMonth where (self.conversation.sections.count > 0 && self.isOlderReached):
                                self.loadOlderControl?.isHidden = true
                                self.loadOlderControl?.isEnabled = false
                                self.loadNewerControl?.isHidden = true
                                self.loadNewerControl?.isEnabled = false
                            default:
                                self.loadNewerControl?.isHidden = true
                                self.loadNewerControl?.isEnabled = false
                        }
//                    } else if history.entries.count > 0,entriesFiltered.count == 0 {
                      } else {
                        self.clear(animated: false)
                        if entriesFiltered.count == 0 {                        
                            self.displayMessageForEmptyHistory(animated: true)
                        }
                        self.refreshTableviewHeaderAndFooter()
                        self.loadOlderControl?.isHidden = true
                        self.loadOlderControl?.isEnabled = false
                        switch self.filterValue.range {
                        case .all,.last7days,.thisMonth,.today:
                            self.loadNewerControl?.isHidden = false
                            self.loadNewerControl?.isEnabled = true
                        default:
                            self.loadNewerControl?.isHidden = true
                            self.loadNewerControl?.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    /**
     Delete the history with confirmation
     
     The confirmation view controller is presented from the rootViewController.
     If a viewController is already presented, the confirmation view controller is pushed into the presended navigationController.
     */
    public func deleteHistory() {
        guard SVKReachability.isInternetAvailable() else {
            self.view.showNoInternetToast()
            return
        }
        
        if isHistroyEmpty {
            let alert = UIAlertController(title: "SVK.no.histroy.error.title".localized, message: "SVK.no.histroy.error.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            if let confirmViewController = storyboard?.instantiateViewController(withIdentifier: "SVKDeleteHistoryViewController") as? SVKDeleteHistoryViewController {
                confirmViewController.showOnlyDeviceHistory = self.showOnlyDeviceHistory
                confirmViewController.delegate = self
                confirmViewController.successCompletionHandler = {
                    let message = "DC.toast.deleteall.message".localized
                    
                    let toastData = SVKToastData(with: .confirmation, message: message, offset: Float(self.inputViewContainer.bounds.height), action: SVKAction(title: "DC.toast.delete.action".localized))
                    self.view.showToast(with: toastData) {
                        let serialNumber = self.showOnlyDeviceHistory ? SVKUserIdentificationManager.shared.serialNumber : nil
                        self.delegate?.deleteAllHistoryEntries(serialNumber: serialNumber) {(success) in
                            DispatchQueue.main.async {
                                if (success) {
                                    self.oldestId = nil
                                    self.clear(animated: true)
                                    let emptyTitleKey: String = self.context.dedicatedPreFixLocalisationKey + ".history.empty.title"
                                    let emptyTxtKey: String = self.context.dedicatedPreFixLocalisationKey + ".history.empty.text"
                                    let message = (emptyTitleKey.localized, emptyTxtKey.localized)
                                    self.setEmptyMessageHidden(self.conversation.sections.count > 0, animated: true, message: message)
                                    self.refreshTableviewHeaderAndFooter()
                                    self.loadOlderControl?.isEnabled = false
                                    self.loadOlderControl?.isHidden = true
                                } else {
                                    DispatchQueue.main.safeAsync {
                                        let toastData = SVKToastData(with: .default, message: "SVK.toast.deletion.error.message".localized, offset: Float(self.inputViewContainer.bounds.height))
                                        
                                        self.view.showToast(with: toastData)
                                    }
                                }
                            }
                        }
                    }
                }
                confirmViewController.modalPresentationStyle = .overFullScreen
                self.present(confirmViewController, animated: true, completion: nil)
            }
        }
        SVKAnalytics.shared.log(event: "myactivity_delete_all")
    }
    
    @objc func deleteSelectedHistoryEntries() {
        SVKAnalytics.shared.log(event: "myactivity_delete_selection_delete")
        
        DispatchQueue.main.async {
            var entries = [String]()
            var indexPaths = [IndexPath]()
            
            // Gets the selected items and indexPaths in reverted order
            for (indexPath, element) in self.conversation.enumerated().reversed() {
                if let id = element.historyID, element.isSelected, element.bubbleIndex == 0 {
                    entries.append(id)
                    indexPaths.append(indexPath)
                }
            }
            
            DispatchQueue.main.safeAsync {
                let key = entries.count == 1 ? "DC.toast.delete.message.format.single" : "DC.toast.delete.message.format"
                let message = String(format: key.localized, entries.count)
                
                self.restoreDisplayMode(animated: true)
                
                DispatchQueue.main.async {
                    
                    let toastData = SVKToastData(with: .confirmation, message: message, offset: Float(self.inputViewContainer.bounds.height), action: SVKAction(title: "DC.toast.delete.action".localized))
                    self.view.showToast(with: toastData) {
                        self.delegate?.deleteHistoryEntries(ids: entries) { success in
                            DispatchQueue.main.async {
                                if !success {
                                    SVKAnalytics.shared.log(event: entries.count == 1 ? "myactivity_item_delete_error" : "myactivity_delete_selection_confirmation_error")
                                    let toastData = SVKToastData(with: .default, message: "SVK.toast.deletion.error.message".localized, offset: Float(self.inputViewContainer.bounds.height))
                                    
                                    self.view.showToast(with: toastData)
                                    
                                } else {
                                    self.updateConverstation(withDeleted: indexPaths)
                                    self.groupingErrors()
                                    // switch back the UI to normal mode
                                    self.cancelEditHistoryEntries(nil)
                                    //check error message
                                    if self.conversation.first == nil {
                                        self.displayMessageForEmptyHistory(animated: true)
                                        self.refreshTableviewHeaderAndFooter()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
            removes all bubbles of the same historyId for each IndexPath
     */
    func updateConverstation(withDeleted indexPaths: [IndexPath]) {
        var rowsToDelete = [IndexPath]()
        var sectionsToDelete = IndexSet()
        
        var historyId:String?
        if let last = indexPaths.last {
            if conversation.isBounded(indexPath: last){
                historyId = self.conversation[last].historyID
            }
            
        }
        // build an array of indexPath and an IndexSet of sections to delete
        if historyId != nil {
            indexPaths.forEach({ (indexPath) in
                if let historyId = self.conversation[indexPath].historyID {
                    var rowToDeleteTmp = self.conversation.indexPathOfElements(from: indexPath) {
                        return $0.historyID == historyId
                    }
                    rowToDeleteTmp.reverse()
                    rowsToDelete.append(contentsOf: rowToDeleteTmp)
                    rowToDeleteTmp.forEach ({ (indexPathTodelete) in
                        let element = self.conversation[indexPathTodelete.section].elements.remove(at: indexPathTodelete.row)
                        if let errorCode = element.errorCode, SVKConstant.filteredErrorCode.contains(errorCode) {
                            var foundErrorHeader = false
                            var currentHeaderErrorIndexpath:IndexPath? = self.conversation.indexPath(before: indexPathTodelete)
                            while !foundErrorHeader && currentHeaderErrorIndexpath != nil {
                                if let headerErrorIndexpath = currentHeaderErrorIndexpath {
                                    if var headerErrorDescription = self.conversation[headerErrorIndexpath] as? SVKHeaderErrorBubbleDescription {
                                        foundErrorHeader = true
                                        if let i = headerErrorDescription.bubbleDescriptionEntries.firstIndex(where: { (bubbleDescription) -> Bool in
                                            return bubbleDescription.bubbleKey == element.bubbleKey
                                        }) {
                                            headerErrorDescription.bubbleDescriptionEntries.remove(at: i)
                                            self.conversation[headerErrorIndexpath] = headerErrorDescription
                                            if headerErrorDescription.bubbleDescriptionEntries.isEmpty {
                                                self.conversation.remove(at: [headerErrorIndexpath])
                                                rowsToDelete.append(headerErrorIndexpath)
                                            }
                                        }
                                    } else {
                                        currentHeaderErrorIndexpath = self.conversation.indexPath(before: headerErrorIndexpath)
                                    }
                                }
                            }
                        }
                    })
                    // for a historyId all bubble are in the same section (timestamp is now at the top level
                    if rowsToDelete.count > 0 {
                        
                        let s = rowsToDelete[0].section
                        if self.conversation[s].isEmpty {
                            self.conversation.sections.remove(at: s)
                            sectionsToDelete.insert(s)
                        }
                    }
                }
            })
        }
        
        
        
        // delete rows and sections from the tableView
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: rowsToDelete, with: .fade)
        self.tableView.deleteSections(sectionsToDelete, with: .fade)
        self.tableView.endUpdates()
        
        // synchronize the var storing the oldest history id
        if historyId == self.oldestId {
            if self.conversation.first?.origin == .history {
                self.oldestId = self.conversation.first?.historyID
            } else {
                self.oldestId = nil
            }
        }
    }

    public func editHistoryEntries() {
        guard SVKReachability.isInternetAvailable() else {
            self.view.showNoInternetToast()
            return
        }
        /// Delete empty/misunderstood live conversation messages
        let isLastElementEmptyRequest = conversation.lastElement?.contentType == SVKBubbleContentType.recoText ? true : false
        while conversation.lastElement?.contentType == SVKBubbleContentType.recoText {
            conversation.remove(at: [conversation.lastElementIndexPath])
        }
        if isLastElementEmptyRequest {
            conversation.remove(at: [conversation.lastElementIndexPath])
            reloadData()
        }
        
        /// check if histroy is empty or not
        if isHistroyEmpty {
            let alert = UIAlertController(title: "SVK.no.histroy.error.title".localized, message: "SVK.no.histroy.error.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            /// delete welcome message 
            if isWelcomeMsgAdded {
                conversation.remove(at: [IndexPath(row: 0, section: 0)])
                isWelcomeMsgAdded = false
                if isPrimaryWelcomeMsgAdded {
                    conversation.remove(at: [IndexPath(row: 0, section: 0)])
                    isPrimaryWelcomeMsgAdded = false
                }
                reloadData()
            }
            if let deleteViewController = storyboard?.instantiateViewController(withIdentifier: "SVKDeleteViewController") as? SVKDeleteViewController {
                deleteViewController.conversation = conversation
                deleteViewController.delegate = self
                deleteViewController.modalPresentationStyle = .overFullScreen
                self.present(deleteViewController, animated: true, completion: nil)
            }
        }
        SVKAnalytics.shared.startActivity(name: "myactivity_delete_selection", with: nil)
    }
    
    internal func expandAllError() {
        let collapsedHeaders = self.conversation.filter { (bubbleDescrition) -> Bool in
            if let bubbleErrorDescriton = bubbleDescrition as? SVKHeaderErrorBubbleDescription, !bubbleErrorDescriton.isExpanded {
                return true
            } else {
                return false
            }
        }
        
        let collapsedHeadersIndex = collapsedHeaders.map { (bubbleDescription) -> IndexPath in
            let ip = self.conversation.firstIndex { (bubbleDescriptionIt) -> Bool in
                return bubbleDescription.bubbleKey == bubbleDescriptionIt.bubbleKey
            }
            return ip ?? self.conversation.endIndex
        }
        
        collapsedHeadersIndex.reversed().forEach { (indexPath) in
            if var bubbleDescription = self.conversation[indexPath] as? SVKHeaderErrorBubbleDescription,  !bubbleDescription.isExpanded {
                bubbleDescription.isExpanded = true
                self.conversation[indexPath] = bubbleDescription
                var errorDescriptionEntries = bubbleDescription.bubbleDescriptionEntries
                let nextIndex = self.conversation.index(after: indexPath)
                insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: false,animation: .fade)
                bubbleDescription.bubbleDescriptionEntries = errorDescriptionEntries
                self.conversation[indexPath] = bubbleDescription
            }
        }
        
    }
    
    internal func collapseAllError() {
        let collapsedHeaders = self.conversation.filter { (bubbleDescrition) -> Bool in
            if let bubbleErrorDescriton = bubbleDescrition as? SVKHeaderErrorBubbleDescription, bubbleErrorDescriton.isExpanded {
                return true
            } else {
                return false
            }
        }
        
        let collapsedHeadersIndex = collapsedHeaders.map { (bubbleDescription) -> IndexPath in
            let ip = self.conversation.firstIndex { (bubbleDescriptionIt) -> Bool in
                return bubbleDescription.bubbleKey == bubbleDescriptionIt.bubbleKey
            }
            return ip ?? self.conversation.endIndex
        }
        
        collapsedHeadersIndex.reversed().forEach { (indexPath) in
            if var bubbleDescription = self.conversation[indexPath] as? SVKHeaderErrorBubbleDescription,  bubbleDescription.isExpanded {
                bubbleDescription.isExpanded = false
                self.conversation[indexPath] = bubbleDescription
                let nextIndex = self.conversation.index(after: indexPath)
                removeErrorBubbleCollapsed(from: nextIndex)
                self.conversation[indexPath] = bubbleDescription
                
            }
        }
        
    }
    
    internal func groupingErrors() {
        var s = 0
        while s < self.conversation.sections.count {
            let sectionDescription = self.conversation.sections[s]
            var i = 0
            while i < sectionDescription.elements.count {
                if var errorBubbleDescription = sectionDescription.elements[i] as? SVKHeaderErrorBubbleDescription {
                    if errorBubbleDescription.isExpanded {
                        // we have to find the first no bubble with no errorCode
                        var iTmp = i + 1
                        var found = false
                        while iTmp < sectionDescription.elements.count && !found {
                            let bubbleDescription = sectionDescription.elements[iTmp]
                            if let errorCode = bubbleDescription.errorCode, SVKConstant.filteredErrorCode.contains(errorCode) {
                                iTmp += 1
                            } else {
                                found = true
                            }
                        }
                        // We found a second error Bubble
                        if iTmp < sectionDescription.elements.count, let errorBubbleDescriptionSecond = sectionDescription.elements[iTmp] as? SVKHeaderErrorBubbleDescription {
                            // the second errorBubble is expanded
                            if errorBubbleDescriptionSecond.isExpanded {
                                removeErrorBubbleCollapsed(from: IndexPath(row: iTmp + 1, section: s))
                                sectionDescription.elements.remove(at: iTmp)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [IndexPath(row: iTmp, section: s)], with: .fade)
                                self.tableView.endUpdates()
                                removeErrorBubbleCollapsed(from: IndexPath(row: i + 1, section: s))
                                errorBubbleDescription.bubbleDescriptionEntries.insert(contentsOf: errorBubbleDescriptionSecond.bubbleDescriptionEntries, at:0)
                                errorBubbleDescription.isExpanded = true
                                sectionDescription.elements[i] = errorBubbleDescription
                                var errorDescriptionEntries = errorBubbleDescription.bubbleDescriptionEntries
                                let nextIndex = self.conversation.index(after: IndexPath(row: i, section: s))
                                insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: false,animation: .fade)
                                errorBubbleDescription.bubbleDescriptionEntries = errorDescriptionEntries
                                sectionDescription.elements[i] = errorBubbleDescription
                            } else {
                                // the second errorBubble is collapsed
                                sectionDescription.elements.remove(at: iTmp)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [IndexPath(row: iTmp, section: s)], with: .fade)
                                self.tableView.endUpdates()
                                removeErrorBubbleCollapsed(from: IndexPath(row: i + 1, section: s))
                                errorBubbleDescription.bubbleDescriptionEntries.insert(contentsOf: errorBubbleDescriptionSecond.bubbleDescriptionEntries, at: 0)
                                errorBubbleDescription.isExpanded = true
                                sectionDescription.elements[i] = errorBubbleDescription
                                var errorDescriptionEntries = errorBubbleDescription.bubbleDescriptionEntries
                                let nextIndex = self.conversation.index(after: IndexPath(row: i, section: s))
                                insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: false,animation: .fade)
                                errorBubbleDescription.bubbleDescriptionEntries = errorDescriptionEntries
                                sectionDescription.elements[i] = errorBubbleDescription
                            }
                        } else {
                            i = iTmp + 1
                        }
                        
                    } else {
                        // first errorBubble collaped and the next item is a errorBubble
                        if i + 1 < sectionDescription.elements.count, let errorBubbleDescriptionSecond = sectionDescription.elements[i + 1] as? SVKHeaderErrorBubbleDescription {
                            // the second errorBubble is expanded
                            if errorBubbleDescriptionSecond.isExpanded {
                                removeErrorBubbleCollapsed(from: IndexPath(row: i + 2, section: s))
                                sectionDescription.elements.remove(at: i + 1)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [IndexPath(row: i + 1, section: s)], with: .fade)
                                self.tableView.endUpdates()
                                errorBubbleDescription.bubbleDescriptionEntries.insert(contentsOf: errorBubbleDescriptionSecond.bubbleDescriptionEntries, at: 0)
                                errorBubbleDescription.isExpanded = true
                                sectionDescription.elements[i] = errorBubbleDescription
                                var errorDescriptionEntries = errorBubbleDescription.bubbleDescriptionEntries
                                let nextIndex = self.conversation.index(after: IndexPath(row: i, section: s))
                                insertBubbles(from: &errorDescriptionEntries, at: nextIndex.row, in: nextIndex.section, scrollEnabled: false,animation: .fade)
                                errorBubbleDescription.bubbleDescriptionEntries = errorDescriptionEntries
                                sectionDescription.elements[i] = errorBubbleDescription
                            } else {
                                // the second errorBubble is collapsed
                                sectionDescription.elements.remove(at: i + 1)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [IndexPath(row: i + 1, section: s)], with: .fade)
                                self.tableView.endUpdates()
                                errorBubbleDescription.bubbleDescriptionEntries.insert(contentsOf: errorBubbleDescriptionSecond.bubbleDescriptionEntries, at: 0)
                                errorBubbleDescription.isExpanded = false
                                sectionDescription.elements[i] = errorBubbleDescription
                            }
                        } else {
                            i += 2
                        }
                    }
                } else {
                    i += 1
                }
            }
            s += 1
        }
        
    }


    @objc func cancelEditHistoryEntries(_ button: UIButton?) {
        self.collapseAllError()
        restoreDisplayMode(animated: true)
    }
    
    /**
     Restore the view controller display mode
     - parameter animated: **true** if the view sould be animated
     */
    public func restoreDisplayMode(animated: Bool) {
        if animated == false {
            self.setNeedsScrollToBottom()
        }
        DispatchQueue.main.async {
            self.isEditing = false
            UIView.animate(withDuration: animated ? 0.3 : 0) {
                self.tableView.superview?.layoutIfNeeded()
                self.tableTopLayoutConstraint.constant  = 0
            }
            
            self.addLongGestureRecognizer()
            self.tableView.reloadData()
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = self.leftBarButtonItemBackup
            self.isMoreButtonHidden = self.shouldRestoreMoreButton
            self.displayMode = self.displayModeBackup
            self.setToolbarStyle(animated: true)
            self.headerFilterView.isHidden = false
        }
    }
    
    /**
     Displays or hide a message indicating that the history is empty
     - parameter hidden: true if the message must be hidden
     - parameter animated: true if the message must be animated
     - parameter message: a messages tuple with title and text to display or nil
     */
    internal func setEmptyMessageHidden(_ hidden: Bool, animated: Bool, message: (title: String, text: String)? = nil) {
        isHistroyEmpty = !hidden
        
        DispatchQueue.main.safeAsync {
            
            
            if hidden {
      
      
                UIView.animate(withDuration: animated ? 0.7 : 0, animations: {
                    self.tableView.backgroundView?.alpha = 0
                }) { (finished) in
                    self.tableView.hideEmptyState()
                }
            } else {

                self.tableView.backgroundView?.alpha = 0
                var title = ""
                var description = "history.error".localized
                var image = SVKAppearanceBox.Assets.emptyScreen
                if let msg = message {
                    title = msg.title
                    description = msg.text
                    if description == "feedback.networkFailure".localized {
                        title = "feedback.networkFailure.title".localized
                        image = SVKAppearanceBox.Assets.networkErrorScreen
                    }
                }
                
                self.tableView.showEmptyState(withImage: image, title: title, text: description, fonts: self.context.emptyScreenfontType)
                UIView.animate(withDuration: animated ? 0.7 : 0,
                               delay: 0.3,
                               options: UIView.AnimationOptions.curveEaseIn,
                               animations: {
                                self.tableView.backgroundView?.alpha = 1
                }, completion: nil)
            }
        }
    }
    
    func registerSkillsAppearance(completionHandler: (() -> Void)? = nil) {
        SVKAPISkillCatalogRequest().fetchSkillSkins() { skins in
            SVKConversationAppearance.shared.skillsAppearance = [:]
            skins?.forEach { (entry) in
                let (key, value) = entry
                if value.content?.conversationHistory != nil {
                    var assistantBubbleAppearance = SVKConversationAppearance.shared.defaultSkillAppearance.assistantBubbleAppearance
                    
                    assistantBubbleAppearance.foregroundColor = UIColor(hex: value.content?.conversationHistory?.backgroundColor ?? "")
                    assistantBubbleAppearance.textColor = UIColor(hex: value.content?.conversationHistory?.textColor ?? "")
                    let appearance = SDKSkillAppearance(assistantBubbleAppearance: assistantBubbleAppearance,
                                                       userBubbleAppearance: assistantBubbleAppearance,
                                                       headerErrorCollapsedBubbleAppearance: assistantBubbleAppearance,
                                                       headerErrorExpandedBubbleAppearance: assistantBubbleAppearance,
                                                       userErrorBubbleAppearance: assistantBubbleAppearance,
                                                       assistantErrorBubbleAppearance: assistantBubbleAppearance,
                                                       recoBubbleAppearance: assistantBubbleAppearance,
                                                       avatarURL: URL(string: value.content?.conversationHistory?.iconUrl ?? ""))
                    SVKConversationAppearance.shared.skillsAppearance[key] = appearance
                }
                SVKConversationAppearance.shared.skillCatalog[key] = value
            }
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
}

extension SVKConversationViewController: SVKDeleteHistoryProtocol {
    public func deleteHistoryEntries(ids: [String], completionHandler: @escaping (Bool) -> Void) {
        // Nothing to do
    }
    
    public func deleteAllHistoryEntries(_ completionHandler: @escaping (Bool) -> Void) {
        // Nothing to do deprecated
    }
    
    public func deleteAllHistoryEntries(serialNumber: String?, completionHandler: @escaping (Bool) -> Void) {
       completionHandler(true)
    }
    
    
}
/**
 Build SVKAssistantBubbleDescriptions from a string
 
 The string is processed to extract data used to build the bubble descriptions.
 SSML tag like **break** or **img** found in the string generates several bubble descriptions
 
 - parameter djingoText: The string from which bubble descriptions are builded
 - returns: An array of SVKBubbleDescription
 */
func buildDescriptions(_ djingoText: String?, _ timestamp: String?,
                       _ entry: SVKHistoryEntry? = nil , _ invokeResult: SVKInvokeResult? = nil,
                       _ card: SVKCard? = nil, _ bubbleIndex: inout Int,
                       _ reverse: Bool = false, _ skin: String = "djingo") -> [SVKBubbleDescription] {
    
    
    var bubblesDescription = [SVKBubbleDescription]()
    
    if let text = djingoText {
        
        if text.contains("::") {
            var splittedText: StringStatusArray = text.process(with: SVKSSMLProcessorBehaviour.splitContentForParner("::"))
            if reverse {
                splittedText.reverse()
            }
            for (var index, stringStatus) in splittedText.enumerated() {
                if reverse {
                    index = (splittedText.count - 1) - index
                }
                let string = stringStatus.0.process(with: SVKSSMLProcessorBehaviour.sentence).reduce("", +)
                let djingo = stringStatus.1
                let style = splittedText.bubbleStyle(for: index)
                var djingoBubbleDescription:SVKAssistantBubbleDescription
                
                if djingo {
                    djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: style, text: string, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult)
                    djingoBubbleDescription.skillId = ""
                    djingoBubbleDescription.isAvatarVisible = true
                    djingoBubbleDescription.bubbleIndex = bubbleIndex
                    bubbleIndex += 1
                    bubblesDescription.append(djingoBubbleDescription)
                } else {
                    let bubblesDescriptionTmp = buildDescriptions(string, timestamp, entry, invokeResult, card, &bubbleIndex, reverse, skin)
                    bubblesDescription.append(contentsOf: bubblesDescriptionTmp)
                }
            }
            
        }
        else if text.contains("<p") {
            var paragraphDescriptions = [SVKBubbleDescription]()
            
            var paragraphs = text.process(with: SVKSSMLProcessorBehaviour.paragraphs)
                .map { $0.process(with: SVKSSMLProcessorBehaviour.sentence).reduce("", +) }
            paragraphs = paragraphs.filter {
                !$0.isEmpty && $0 != "/s" && $0 != "/p" && $0 != "p"
            }
            paragraphs.forEach {
                if $0.contains("<p img-src") {
                    let dictionary: SVKSSMLCompositeProcessor.Output = $0.process(with: .imageAttributesAndCaptions(["url", "layout", "caption"]))
                    if let url = dictionary["url"] {
                        var djingoBubbleDescription = SVKAssistantBubbleDescription(text: url, type: .image, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult)
                        djingoBubbleDescription.mediaLayout = SVKMediaLayout(string: dictionary["layout"])
                        paragraphDescriptions.append(djingoBubbleDescription)
                        
                    }
                    
                    if let caption = dictionary["caption"],
                        !caption.isEmpty {
                        paragraphDescriptions.append(SVKAssistantBubbleDescription(text: caption, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult))
                    }
                } else {
                    paragraphDescriptions.append(SVKAssistantBubbleDescription(text: $0, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult))
                }
            }
            
            paragraphDescriptions.setBubblesStyle()
            if reverse {
                paragraphDescriptions.reverse()
            }
            paragraphDescriptions = paragraphDescriptions.map {
                var description = $0
                description.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                return description
            }
            bubblesDescription.append(contentsOf: paragraphDescriptions)
        }
            // processing s tags
        else  if text.contains("<s ") {
            let string = text.process(with: SVKSSMLProcessorBehaviour.sentence).reduce("", +)
            var djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: .default(.left),
                                                                    text: string, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult)
            djingoBubbleDescription.bubbleIndex = bubbleIndex
            bubbleIndex += 1
            bubblesDescription.append(djingoBubbleDescription)
        }
            // processing break tags
        else if text.contains("<break") {
            var splittedText: StringArray = text.process(with: SVKSSMLProcessorBehaviour.splitContent("break", true))
            if reverse {
                splittedText.reverse()
            }
            for (var index, string) in splittedText.enumerated() {
                if reverse {
                    index = (splittedText.count - 1) - index
                }
                let style = splittedText.bubbleStyle(for: index)
                var djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: style, text: string, timestamp: timestamp, historyEntry: entry, invokeResult: invokeResult)
                djingoBubbleDescription.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                bubblesDescription.append(djingoBubbleDescription)
            }
            
        }
            // Nothing else to process
        else {
            var style = SVKBubbleStyle.default(.left)
            var type = SVKBubbleContentType.text
            var text = text
            let excludeStatus = ["WAKE_UP_PHRASE_VALIDATION_FAILED","CLIENT_ABORTED_STREAMING"]
            if text.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty, entry?.response?.card == nil, entry?.response?.errorCode != nil || excludeStatus.contains(invokeResult?.status ?? "")   {
                // nothing to do, we should not add a bot bubble
            } else {
                if text.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty, entry?.response?.card == nil {
                    type = skin != "djingo" ? .errorText : .disabledText
                    text = "disabled.response.text".localizedWithTenantLang
                } else {
                    let isValidCard = (entry?.response?.card != nil && entry?.response?.card?.data != nil) ||
                        (card != nil)
                     style = isValidCard ? .top(.left) : .default(.left)
                }
                var djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: style,
                                                                        text: text,
                                                                        type: type,
                                                                        timestamp: timestamp, card: nil,  historyEntry: entry, invokeResult: invokeResult)
                djingoBubbleDescription.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                bubblesDescription.append(djingoBubbleDescription)
            }
        }
    }
    return bubblesDescription
}


/**
 A Sequence exension helper that provide easy navigation
 through history items
 */
extension Sequence where Iterator.Element == SVKHistoryEntry {
    
    /**
     Use this computed property to build an array of SVKBubbleDescritpion from a Sequence of SVKHistoryEntry
     
     Returns an reversed array of SVKBubbleDescritpion
     */
    func reversedHistoryDescriptions(isHideErrorInteractionsEnabled: Bool,isHideDeviceDefaultNameEnabled: Bool, skin: String, isHideGlobalCommand: Bool) -> [SVKBubbleDescription] {
        var bubblesDescription = [SVKBubbleDescription]()
        
        for entry in self {
            var bubbleIndex = 0
            
            let djingoText: String? = entry.response?.text?.process(with: .removeUnknownTags(keepTags: ["speak","audio","sub","p","s"]))
                .process(with: .removeTag("speak"))
                .process(with: .removeTag("audio"))
                .process(with: .removeTag("sub"))
                .process(with: .removeTagValue(tag: "s", attributeName: "display", attributeValue: "none"))
            
            if let userText = entry.request?.text,
                userText.lowercased() == "ok djingo",
                let text = djingoText,
                text.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                continue
            }
            
            var bubblesDescriptionTmp = [SVKBubbleDescription]()
            if let card = entry.response?.card, let data = card.data, !data.isEmpty(),
               !(entry.timestampNotFormated?.isEmpty ?? false) {
                var djingoBubbleDescription = SVKAssistantBubbleDescription(bubbleStyle: .bottom(.left),
                                                                        text: djingoText, timestamp: entry.timestampNotFormated,
                                                                        card: card, historyEntry: entry)
                djingoBubbleDescription.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                bubblesDescriptionTmp.append(djingoBubbleDescription)
                if skin == "djingo" {
                    bubblesDescriptionTmp.append(contentsOf: buildDescriptions(djingoText, entry.timestampNotFormated, entry, nil, nil, &bubbleIndex, true, skin))
                }
            } else {
                let responseBubble = buildDescriptions(djingoText, entry.timestampNotFormated, entry, nil, nil, &bubbleIndex, true, skin)
                if !(responseBubble.first?.skillId == SVKConstant.globalCommand && isHideGlobalCommand) {
                    bubblesDescriptionTmp.append(contentsOf: responseBubble)
                }
            }
            bubblesDescriptionTmp.setBubblesStyle(reversed: true)
            
            // insert the user question bubble
            if !(entry.timestampNotFormated?.isEmpty ?? false),
                let userText = entry.request?.text, !userText.isEmpty {
                var userBubbleDescription = SVKUserBubbleDescription(bubbleStyle: .default(.left),
                                                                    text: userText, isDelivered: true,
                                                                    timestamp: entry.timestampNotFormated, historyEntry: entry)
                
                userBubbleDescription.isDefaultDeviceNameHide = isHideDeviceDefaultNameEnabled && entry.device?.name == SVKConstant.defaultDeviceName
                userBubbleDescription.bubbleIndex = bubbleIndex
                bubbleIndex += 1
                bubblesDescriptionTmp.append(userBubbleDescription)
            }
            
            if let errorCode = entry.response?.errorCode {
                if !isHideErrorInteractionsEnabled, SVKConstant.filteredErrorCode.contains(errorCode) {
                    var errorDescription: SVKHeaderErrorBubbleDescription
                    var shouldAppendError = true
                    if let last = bubblesDescription.last as? SVKHeaderErrorBubbleDescription, let date = SVKTools.date(from: entry.timestampNotFormated ?? ""), let dateLastDescription = SVKTools.date(from: last.timestamp), dateLastDescription.inSameDayAs(date) {
                        errorDescription = last
                        shouldAppendError = false
                    } else {
                        errorDescription = SVKHeaderErrorBubbleDescription(bubbleStyle: .default(.left), text: "DC.bubble.error.header.message".localizedWithTenantLang, timestamp: entry.timestampNotFormated, bubbleDescriptionEntries: [])
                    }
                    bubblesDescriptionTmp.forEach({ (bubbleDescription) in
                        var newBubbleDescrition = bubbleDescription
                        newBubbleDescrition.markAsError()
                        newBubbleDescrition.bubbleIndex = bubbleIndex - (bubbleDescription.bubbleIndex ?? 0) - 1
                        errorDescription.bubbleDescriptionEntries.append(newBubbleDescrition)
                    })
                    if shouldAppendError {
                        bubblesDescription.append(errorDescription)
                    } else {
                        let _ = bubblesDescription.popLast()
                        errorDescription.timestamp = errorDescription.bubbleDescriptionEntries.last?.timestamp ?? ""
                        bubblesDescription.append(errorDescription)
                    }
                }
            } else {
                bubblesDescriptionTmp.forEach({ (bubbleDescription) in
                    var newBubbleDescrition = bubbleDescription
                    newBubbleDescrition.bubbleIndex = bubbleIndex - (bubbleDescription.bubbleIndex ?? 0) - 1
                    bubblesDescription.append(newBubbleDescrition)
                })
            }
        }
        
        return bubblesDescription
    }
}

extension SVKHistoryEntry {
    var timestampFormated: Date? {
        return self.timestampNotFormated?.iso8061Date?.addingTimeInterval(-1)
    }
}

extension String {
    var iso8061Date: Date? {        
        let date = SVKTools.date(from: self)
        return date
    }
}

extension SVKHistoryEntries {
    var isEmpty: Bool {
        return entries.isEmpty
    }
    
    var newestTimestamp: Date? {
        return entries.first?.timestampFormated
    }
    
    var oldestTimestamp: Date? {
        return entries.last?.timestampFormated
    }
    
}
