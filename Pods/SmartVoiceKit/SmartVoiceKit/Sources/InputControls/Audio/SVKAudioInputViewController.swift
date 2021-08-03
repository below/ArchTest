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
import MediaPlayer
import CoreTelephony
import CallKit

public protocol SVKAudioInputSizableDelegate {
    func audioInput(_ recognitionButton: UIButton?, didUpdateItsSize size: CGSize)

}

@IBDesignable
class SVKAudioInputViewController: UIViewController, SVKConversationInputProtocol, SVKInputViewProtocol,SVKSpeechTransactionExchangeDelegate {
    
    
    @IBOutlet var startRecognitionButton: UIButton?
    @IBOutlet var buttonCenterYConstraint: NSLayoutConstraint?
    @IBOutlet var audioSignalIndicatorView: SVKAudioSignalIndicatorView!
    @IBOutlet var indicatorCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var petalsAnimationView: SVKPetalsAnimationView!
    @IBOutlet var petalsAnimationCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet var buttonHeightConstraint: NSLayoutConstraint!
    
    public var context = SVKContext()
    
    public var isMainNotificationAudioTriggerAssistantReceiver = false
    public var isSoundEffectsEnabled = true
    
    public var isStretchableSizeImage = false
    /// The input delegate
    public var delegate: (SVKInputDelegate & SVKPushToTalkDelegate)?
    
    public var resizableDelegate: SVKAudioInputSizableDelegate?
    var observation: NSKeyValueObservation?
    
    /// The input mode. Default is .audio
    public var inputMode: SVKConversationInputMode = .audio
    
    /// the audio input animation type. Default is .barGraph
    public var inputAnimationMode: SVKAudioInputAnimationType = .barGraph {
        didSet {
            hideAllAnimationViews(animated: false)
            let tmp = state
            state = tmp
        }
    }
    
    // A timer for audio level polling
    private var skAudioTimer: Timer?
    
    // A timer for listening timeout
    private var skListenTimer: Timer?
    
    /** The amount of time in seconds before the controller state change from
     *.sstListening* to *.idle* if any recognition has started. Default to 15.*/
    public var listenInterval: TimeInterval = 15
    /// used for petal animation: to be sure the vc is launched for the first time
    
    var isAlreadyPresented = false
    /// The preferred contentsize of the view controller
    override var preferredContentSize: CGSize {
        get {
            switch inputAnimationMode {
            case .barGraph:
                return CGSize(width: 375, height: 72)
            case .petals:
                return CGSize(width: 375, height: 120)
            }
        }
        set {}
    }
    
    var buttonHCoefficient: CGFloat {
        get{
            switch inputAnimationMode {
            case .barGraph:
                return 1
            case .petals:
                return 0.55
            }
        }
    }
    /// The view animator
    private var springAnimatorHide: UIViewPropertyAnimator?
    private var springAnimatorShow: UIViewPropertyAnimator?
    
    // The current speech session
    private var session: SVKSpeechSession?
    
    // The current speech transaction
    private var transaction: SVKSpeechTransaction?
    
    private var systemMusicPlaybackState: MPMusicPlaybackState = .stopped
    
    var observer : CXCallObserver?
    
    var isInCall = false
    /// Reflect the state of the conversation to the UI
    
    var notificationAudioTriggerObserver: NSObjectProtocol? = nil
    
    var isHistoryRefreshing: Bool = false {
        didSet {
            let s = state
            state = s
        }
    }
    
    open var state: SVKConverstationInputState = .idle {
        didSet {
            let testCase = (state,isInCall,isHistoryRefreshing)
            SVKLogger.debug("state = \(testCase)")
            switch testCase {
                
            case (.idle,false,false):
                updateMicImage()
                startRecognitionButton?.isEnabled = true
                hideAnimationView(animated: true)
            case (.idle,true,_),(.idle,_,true):
                updateMuteMicImage()
                startRecognitionButton?.isEnabled = true
                hideAnimationView(animated: true)
            case (.sttSendingText,_,_):
                sendingTextState()
            case (.sttStarting,_,_):
                startRecognitionButton?.isEnabled = false
                showAnimationView(animated: true)
            case (.sttListening,_,_):
                skListenTimer?.invalidate()
                skListenTimer = Timer.scheduledTimer(withTimeInterval: listenInterval, repeats: false) { _ in
                    if self.state == .sttListening {
                        self.stopSpeechRecognition()
                    }
                }
                startPollingAudioLevel()
                
            case (.sttStopping,_,_):
                skListenTimer?.invalidate()
                skListenTimer = nil
                skAudioTimer?.invalidate()
                skAudioTimer = nil
                showVocalizedView()
            case (.sttWaitUntilDisconnection,_,_):
                updateMuteMicImage()
                startRecognitionButton?.isEnabled = true
                hideAnimationView(animated: true)
            case (.ttsRunning,false,_):
                showVocalizedView()
            break
            case (.ttsRunning,true,_):
                SVKSpeechSession.shared.stopVocalize()
                break
            case (.disabled, _, _):
                updateMuteMicImage()
                SVKSpeechSession.shared.stopRecognize()
                startRecognitionButton?.isEnabled = false
                skListenTimer?.invalidate()
                skListenTimer = nil
                skAudioTimer?.invalidate()
                skAudioTimer = nil
                hideAnimationView(animated: true)
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePetalsAnimationView()
        self.view.constraints.forEach {
            $0.constant = 0
        }
        hideAllAnimationViews(animated: false)
        setupCallObserver()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        if isMainNotificationAudioTriggerAssistantReceiver {
            notificationAudioTriggerObserver = NotificationCenter.default.addObserver(forName: SVKNotificationAudioTriggerAssistant, object: nil, queue: nil) { notification in
                self.startSpeechRecognition()
            }
        }
        session = SVKSpeechSession.shared
        session?.addObserver(self)
        
        updateMicImage()
        view.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        
        NotificationCenter.default.addObserver(forName: SVKKitNotificationStateBackground, object: nil, queue: nil) { _ in
            if self.state == .sttStarting || self.state == .sttListening {
                self.state = .sttStopping
                SVKSpeechSession.shared.cancelRequest()
            }
            SVKSpeechSession.shared.stopVocalize()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
        // set again state to update the mic image
        view.layoutIfNeeded() // needed for update in conversation mode
        buttonHeightConstraint?.constant = (buttonHCoefficient - 0.55) * view.frame.height
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded() // to layout updated constraint
        if !isAlreadyPresented {
            updatePetalsAnimationViewPosition()
        }
        
        isAlreadyPresented = true
        updateMicImage()

        let tmpState = state
        state = tmpState
        view.layoutSubviews()
        petalsAnimationView.layoutSubviews()
    }
    
    func updateUI(){
        buttonHeightConstraint?.constant = (buttonHCoefficient - 0.55) * view.frame.height
        view.setNeedsUpdateConstraints()
        view.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        petalsAnimationView.backgroundColor = SVKAppearanceBox.shared.appearance.audioInputAnimationBackgroundColor.color
        petalsAnimationView.innerCircleColor = SVKAppearanceBox.shared.appearance.audioInputAnimationTorusColor.color
        view.layoutIfNeeded()
        updateMicImage()
        
        view.layoutIfNeeded()
        view.layoutSubviews()

        
    }
    func updateAppearance(){
        updateMicImage()
        view.backgroundColor = SVKConversationAppearance.shared.backgroundColor
        petalsAnimationView.backgroundColor = SVKAppearanceBox.shared.appearance.audioInputAnimationBackgroundColor.color
        petalsAnimationView.innerCircleColor = SVKAppearanceBox.shared.appearance.audioInputAnimationTorusColor.color
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection){
                updateAppearance()
            }
        }
    }
    
    func clearNotification() {
        if let observer = notificationAudioTriggerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if self.observer != nil {
            self.observer?.setDelegate(nil, queue: nil)
            self.observer = nil
        }
        session?.removeObserver(self)
    }
    
    
    

    
    func updatePetalsAnimationViewPosition(){
        if inputAnimationMode == .petals {
            self.petalsAnimationView.reloadUI()
            switch state {
            case .sttStarting:
                self.petalsAnimationView.restart(animation: .awaiting)
            case .sttListening:
                self.petalsAnimationView.restart(animation: .listening(volume: -80.0))
            case .sttSendingText, .sttRecognizing:
                petalsAnimationView.restart(animation: .processing)
            case .ttsRunning, .sttStopping:
                petalsAnimationView.restart(animation: .vocalising)
            default:
                break
            }
        }
    }
    func updateMicImage() {
        var image = SVKAppearanceBox.Assets.audioRecOn
        var hightlightedImage = SVKAppearanceBox.Assets.audioRecHighlighted
        if isStretchableSizeImage ,
            let size = SVKAppearanceBox.Assets.audioRecordingImageSize {
            image = image?.resizeImage(size, opaque: false)
            hightlightedImage = hightlightedImage?.resizeImage(size, opaque: false)
        }
        if let updatedSize = image?.size{
            resizableDelegate?.audioInput(startRecognitionButton, didUpdateItsSize: updatedSize)
        }
        startRecognitionButton?.setImage(image , for: .normal)
        startRecognitionButton?.setImage(hightlightedImage, for: .highlighted)
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    
    func updateSpeechVocalizationImage() {
        guard let images = SVKAppearanceBox.Assets.animatedImages else {return}        
        var animatedImages = UIImage.animatedImage(with: images, duration: 0.8)
        if isStretchableSizeImage,
            let size = SVKAppearanceBox.Assets.audioRecordingImageSize {
            let newImages = images.compactMap {$0.resizeImage(size, opaque: false)}
            animatedImages = UIImage.animatedImage(with: newImages, duration: 0.8)
        }
        if let updatedSize = animatedImages?.size{
            resizableDelegate?.audioInput(startRecognitionButton, didUpdateItsSize: updatedSize)
        }
        startRecognitionButton?.setImage(animatedImages, for: .normal)
        startRecognitionButton?.setImage(animatedImages, for: .highlighted)
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    
    func updateMuteMicImage() {
        var image = SVKAppearanceBox.Assets.audioRecOff
        if isStretchableSizeImage,
            let size = SVKAppearanceBox.Assets.audioRecordingImageSize {
            image = image?.resizeImage(size, opaque: false)
        }
        if let updatedSize = image?.size{
            resizableDelegate?.audioInput(startRecognitionButton, didUpdateItsSize: updatedSize)
        }
        startRecognitionButton?.setImage(image, for: .normal)
        startRecognitionButton?.setImage(image?.withRenderingMode(.alwaysOriginal), for: .highlighted)
        audioSignalIndicatorView.channelColor = SVKConversationAppearance.shared.audioInputColor
    }
    /**
     Resign the first responder
     
     The first responder is the mic. So the recognition is stooped
     when this function is called.
     */
    @discardableResult
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        if state == .sttStarting ||
            state == .sttListening ||
            state == .sttRecognizing {
            stopSpeechRecognition()
        }
        return true
    }
    
    /**
     Start a speech recognition session
     - parameter sender: The message sender
     */
    @IBAction func startSpeechRecognition(_ sender: Any? = nil) {
        if isInCall { return}
        if isHistoryRefreshing { return }
        if state == .ttsRunning {
            SVKSpeechSession.shared.stopVocalize()
            return
        }
        if state != .idle { return}
        
        state = .sttStarting
        //        session = SVKSpeechSession(delegate: self)
        transaction = session?.recognize(self)
        SVKAnalytics.shared.log(event: "conversation_question_audio")
    }
    
    /**
     Stop the current speech recognition session
     - parameter sender: The message sender
     */
    @IBAction func stopSpeechRecognition(_ sender: Any? = nil) {
        if state == .sttStarting || state == .sttListening {
            state = .sttStopping
            SVKSpeechSession.shared.stopRecognize()
            SVKAnalytics.shared.log(event: "conversation_question_audio_stop")
        }
    }
    
    /*
     Handle the tap gesture
     */
    @objc
    func handleTap(_ sender: Any?) {
        if state == .sttListening {
            stopSpeechRecognition()
        } else if inputAnimationMode == .petals, state == .ttsRunning{
            SVKSpeechSession.shared.stopVocalize()
        }
        
    }
    
    //MARK: SVKTextInputViewController
    var contentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //
    ////MARK: AudioSignalIndicator and PetalsAnimationView animations
    func hideAllAnimationViews(animated: Bool){
        hideAudioSignalIndicator(animated: animated)
        hidePetalsAnimationView(animated: animated)
    }
    
    func hideAnimationView(animated: Bool){
        switch inputAnimationMode {
        case .barGraph:
            hideAudioSignalIndicator(animated: animated)
        case .petals:
            hidePetalsAnimationView(animated: animated)
        }
    }
    func showAnimationView(animated: Bool){
        switch inputAnimationMode {
        case .barGraph:
            showAudioSignalIndicator(animated: animated)
        case .petals:
            showPetalsAnimationView(animated: animated)
        }
    }
    
    func showVocalizedView(){
        switch inputAnimationMode {
        case .barGraph:
            updateSpeechVocalizationImage()
            hideAnimationView(animated: true)
            startRecognitionButton?.isEnabled = true
        case .petals:
            showAnimationView(animated: true)
            petalsAnimationView.restart(animation: .vocalising)
        }
    }
    
    //    private func hideAudioSignalIndicator(animated: Bool) {
    func hideAudioSignalIndicator(animated: Bool) {
        guard audioSignalIndicatorView.isHidden == false else { return }
        guard springAnimatorHide?.isRunning ?? false  == false else { return }
        springAnimatorShow?.stopAnimation(true)
        
        let yOffset = self.audioSignalIndicatorView.frame.height * 3
        indicatorCenterYConstraint.constant = yOffset
        buttonCenterYConstraint?.constant = 0
        self.startRecognitionButton?.isHidden = false
        
        if animated {
            springAnimatorHide = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
            springAnimatorHide?.addAnimations {
                self.startRecognitionButton?.isHidden = false
                self.view.layoutIfNeeded()
            }
            springAnimatorHide?.addCompletion { position in
                if position == .end {
                    self.audioSignalIndicatorView.isHidden = true
                    self.startRecognitionButton?.isHidden = false
                }
            }
            springAnimatorHide?.startAnimation()
        } else {
            self.view.layoutIfNeeded()
            self.audioSignalIndicatorView.isHidden = true
        }
    }
    
    func showAudioSignalIndicator(animated: Bool) {
        
        guard let startRecognitionButton = startRecognitionButton,
            audioSignalIndicatorView.isHidden == true else { return }
        guard springAnimatorShow?.isRunning ?? false == false else { return }
        
        springAnimatorHide?.stopAnimation(true)
        let yOffset = startRecognitionButton.frame.height * 3
        indicatorCenterYConstraint.constant = 0
        buttonCenterYConstraint?.constant = yOffset
        self.audioSignalIndicatorView.isHidden = false
        
        
        if animated {
            springAnimatorShow = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
            springAnimatorShow?.addAnimations {
                self.view.layoutIfNeeded()
            }
            springAnimatorShow?.addCompletion { position in
                if position == .end {
                    startRecognitionButton.isHidden = true
                }
            }
            
            springAnimatorShow?.startAnimation()
        } else {
            self.view.layoutIfNeeded()
            startRecognitionButton.isHidden = true
        }
    }
    
    func hidePetalsAnimationView(animated: Bool){
        guard petalsAnimationView.isHidden == false else { return }
        
        petalsAnimationView.alpha = 1
        startRecognitionButton?.alpha = 0
        
        self.startRecognitionButton?.isHidden = false
        petalsAnimationView.isHidden = false
        
        let animatedFadeOut = {
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.petalsAnimationView.alpha = 0
                self.startRecognitionButton?.alpha = 1
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.startRecognitionButton?.isHidden = false
                self.petalsAnimationView.isHidden = true
            }
        }
        if animated {
            animatedFadeOut()
        } else {
            self.petalsAnimationView.isHidden = true
            self.startRecognitionButton?.isHidden = false
            self.petalsAnimationView.alpha = 0
            self.startRecognitionButton?.alpha = 1
        }
    }
    func showPetalsAnimationView(animated: Bool){
        guard let startRecognitionButton = startRecognitionButton,
            petalsAnimationView.isHidden == true else { return }
        petalsAnimationView.alpha = 0
        startRecognitionButton.alpha = 1
        self.petalsAnimationView.isHidden = true
        self.view.layoutIfNeeded()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        petalsAnimationView.reloadUI()
        CATransaction.commit()
        self.view.layoutIfNeeded()
//
        self.petalsAnimationView.isHidden = false
        startRecognitionButton.isHidden = false
        
        let animatedFadeIn = {
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.petalsAnimationView.alpha = 1
                startRecognitionButton.alpha = 0
            } completion: { [weak self] _ in
                guard let self = self else { return }
                startRecognitionButton.isHidden = true
                self.petalsAnimationView.isHidden = false
            }
        }
        
        if animated {
            animatedFadeIn()
        } else {
            startRecognitionButton.isHidden = true
            self.petalsAnimationView.alpha = 1
            startRecognitionButton.alpha = 0
        }
        
        petalsAnimationView.restart()
    }
    
    // based on currently used image
    func calculateButtonSize() -> CGSize{
        guard let image = SVKAppearanceBox.Assets.audioRecOn else{// check if there is image
            return startRecognitionButton?.frame.size ?? CGSize()
        }
        
        guard let side = SVKAppearanceBox.Assets.audioRecordingImageSize,
        isStretchableSizeImage else{
            return image.size
        }
        return CGSize(width: side, height: side)
    }
    
    func configurePetalsAnimationView(){
        petalsAnimationView.numberOfPetals = 0b100
        petalsAnimationView.petalPivotStride = 0x41//0x5a
        petalsAnimationView.listeningPulsingSpeed = 0.2
        petalsAnimationView.backgroundColor = SVKAppearanceBox.shared.appearance.audioInputAnimationBackgroundColor.color
        petalsAnimationView.innerCircleColor = SVKAppearanceBox.shared.appearance.audioInputAnimationTorusColor.color
    }
    
    func sendingTextState(){
        switch inputAnimationMode {
        case .barGraph:
            audioSignalIndicatorView.setSilentAnimated(true)
        case .petals:

            if state == .sttStopping {
                petalsAnimationView.restart(animation: .processing)
            }
            break
        }
    }
    func setAudioLevel(volume: Float){
        switch inputAnimationMode {
        case .barGraph:
            self.audioSignalIndicatorView.setDecibelLevel(volume)
        case .petals:
            if volume >= -50{ // 30 + (minimumDB -80)
                let power = scaledPower(power: volume)
                petalsAnimationView.restart(animation: .listening(volume: power))
            }
        }
    }
    
    fileprivate func scaledPower(power: Float) -> CGFloat {
        /// The mininum decibel level representing the dynamic range [0..minimumDB] Default is -80
        let minumumDB: Float = -80.0
        guard power.isFinite else { return 0.0 }
        if power <= minumumDB {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        }
        return CGFloat((abs(minumumDB) - abs(power)) / abs(minumumDB))
    }
    
    public func cancelWasAlreadyPresented(){
        isAlreadyPresented = false
        self.view.layoutIfNeeded()
    }
}

//MARK: Transaction Delegate
extension SVKAudioInputViewController: SVKSpeechTransactionDelegate, SVKSpeechObserverDelegate {
    
    func sessionState(_ speechSessionState: SVKSpeechState) {
        if speechSessionState == .speaking {
            state = .ttsRunning
        } else if speechSessionState == .idle {
            state = .idle
        } else if speechSessionState == .running {
            state = .sttStarting
            state = .sttListening
        } else if speechSessionState == .stopping {
            state = .sttWaitUntilDisconnection
        }
    }
    
    func getHashValue() -> Int {
        return self.hashValue
    }
    
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?) {
        self.delegate?.supportedCodecFormat(completionHandler: completionHandler)
    }
    
    var sessionId: String? {
        return self.delegate?.sessionId
    }
    
    
    func transactionDidStop(_ transaction: SVKSpeechTransaction, with error: Error?) {
        SVKLogger.error("\(String(describing: error))")
        
        if let _ = error {
            SVKAnalytics.shared.log(event: "conversation_question_audio_error")
        }
        
        self.stopPollingAudioLevel()
        if error == nil, self.transaction == transaction, isSoundEffectsEnabled, let audioFileName = context.soundConfiguration.resources[SVKSoundConfiguration.SVKSpeechRecognitionKeys.stopListening] {
            SVKAudioPlayer.shared.play(resource: audioFileName)
        }
        self.delegate?.didStopRecognition()
        self.delegate?.didFinishPTTransaction()
        self.state = .idle
    }
    
    func transactionDidFinish(_ transaction: SVKSpeechTransaction) {
        if !(state == .sttStopping || state == .ttsRunning || state == .idle || state == .sttWaitUntilDisconnection) {
            stopPollingAudioLevel()
            if self.transaction == transaction, isSoundEffectsEnabled, let audioFileName = context.soundConfiguration.resources[SVKSoundConfiguration.SVKSpeechRecognitionKeys.stopListening] {
                SVKAudioPlayer.shared.play(resource: audioFileName)
            }
            delegate?.didFinishRecognition()
        } else if state == .ttsRunning {
            stopPollingAudioLevel()
        }
        if state != .ttsRunning && state != .idle {
            state = .idle
        }
    }
    
    func transaction(_ transaction: SVKSpeechTransaction, didReceive message: SVKSttWsMessage, rawText: String) {
        switch message.type {
        case .invokeResult:
            if var response = message.result {
                response.jsonData = rawText.data(using: .utf8)
                self.state = .sttStopping
                if self.transaction == transaction, isSoundEffectsEnabled, let audioFileName = context.soundConfiguration.resources[SVKSoundConfiguration.SVKSpeechRecognitionKeys.stopListening] {
                    SVKAudioPlayer.shared.play(resource: audioFileName)
                }
                delegate?.didFinishRecognition()
                self.delegate?.inputController(self, didReceive: response,isActiveController: self.transaction == transaction)
            }
        case .enOfSpeech:
            SVKLogger.debug("\(message)")
            delegate?.didAcceptSpeech()
        case .partialAsr:
            if let text = message.partialTranscription {
                self.delegate?.inputController(self, partialText: text)
            }
        default:
            break
        }
    }
    
    func transactionWillStartRecording(_: SVKSpeechTransaction) {
        DispatchQueue.main.safeAsync {
            self.state = .sttListening
            self.delegate?.willStartPTTransaction()
        }
    }
    
    func transactionDidStartRecording(_ transaction: SVKSpeechTransaction) {
        // TODO : put a parameter for listening all transactions or only the dedicated transaction
        if self.transaction == transaction , state == .sttListening {
            SVKAudioPlayer.shared.stop(resumeMusic: false)
            if self.transaction == transaction, isSoundEffectsEnabled, let audioFileName = context.soundConfiguration.resources[SVKSoundConfiguration.SVKSpeechRecognitionKeys.startListening] {
                SVKAudioPlayer.shared.play(resource: audioFileName)
            }
        }
        delegate?.didStartRecognition()
    }
    
    
}

//MARK: Audio polling
extension SVKAudioInputViewController {
    
    /**
     Begin to poll the current transaction audio level.
     
     Perform a polling with a time interval of 0.05sec.
     */
    internal func startPollingAudioLevel() {
        
        DispatchQueue.main.safeAsync {
            SVKLogger.debug("Start audio level polling")
            self.skAudioTimer?.invalidate()
            self.skAudioTimer = nil
            self.skAudioTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                if let audioLevel = SVKSpeechSession.shared.audioLevel {
                    DispatchQueue.main.safeAsync {
//                        self.audioSignalIndicatorView.setDecibelLevel(-20 + audioLevel)
                        self.setAudioLevel(volume: -20 + audioLevel)
                    }
                }
            }
            self.skAudioTimer != nil ? RunLoop.current.add(self.skAudioTimer!, forMode: .common) : {}()
            self.skAudioTimer?.tolerance = 0.1
        }
    }
    
    /**
     Stop the polling of the current transation audio level
     */
    internal func stopPollingAudioLevel() {
        SVKLogger.debug("Stop audio level polling")
        skAudioTimer?.invalidate()
        skAudioTimer = nil
        DispatchQueue.main.safeAsync {
//            self.audioSignalIndicatorView.setSilentAnimated(true)
            self.sendingTextState()
        }
    }
}

extension SVKAudioInputViewController: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        isInCall = !call.hasEnded
        let oldState = state
        state = oldState
    }
    
    final func setupCallObserver() {
        self.observer = CXCallObserver()
        self.observer?.setDelegate(self, queue: nil)
        if self.observer?.calls.count ?? 0 > 0 {
            isInCall = true
            let oldState = state
            state = oldState
        }
    }
    
}

public enum SVKAudioInputAnimationType: Int{
    case barGraph
    case petals
}

extension SVKAudioInputViewController{

}


