//
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
/// CALayer helper: used for debbuging
fileprivate extension CALayer{
    func pauseAnimation() {
        if isPaused() == false {
            let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
            speed = 0.0
            timeOffset = pausedTime
        }
    }
    
    func resumeAnimation() {
        if isPaused() {
            let pausedTime = timeOffset
            speed = 1.0
            timeOffset = 0.0
            beginTime = 0.0
            let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            beginTime = timeSincePause
        }
    }
    
    func deferAnimation() {
        autoreverses = false
        beginTime = convertTime(CACurrentMediaTime(), from: nil) - timeOffset
    }
    var startTime: CFTimeInterval {
        get{
            return convertTime(CACurrentMediaTime(), from: nil) - timeOffset
        }
    }
    func isPaused() -> Bool {
        return speed == 0
    }
}

fileprivate extension CGFloat {
    
    static var innerCircleRatio: CGFloat = 0.55
    static var petalRatio: CGFloat = 0.58
    //: Petal constants
    static var petalHCoefficient: CGFloat = 1.3
    static var petalHCoefficientSmall: CGFloat = 1.1
    static var petalHCoefficientBig: CGFloat = 1.5
}

// Animation library
fileprivate extension CAAnimation{
    static func pulsingAnimation(speed: CFTimeInterval = 0.9, scale: CGFloat = 1.1, fromValue: CGFloat = 1, repeatCount: Float = .greatestFiniteMagnitude)-> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = CATransform3DMakeScale(scale, 1, 1)
        animation.fromValue = CATransform3DMakeScale(fromValue, 1, 1)
        animation.duration = speed
        
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.autoreverses = true
        animation.repeatCount = repeatCount
        return animation
    }
    static func pulsingV2Animation()->CASpringAnimation{
        let pulse1 = CASpringAnimation(keyPath: "transform.scale")
        pulse1.duration = 1.1
        pulse1.fromValue = 0.8
        pulse1.toValue = 1.0
        pulse1.autoreverses = true
        
        pulse1.repeatCount = 1//.greatestFiniteMagnitude
        pulse1.damping = 9
        pulse1.mass = 1.2
        pulse1.fillMode = .both
        
        return pulse1
    }
    
    static func pulsingV3Animation()->CASpringAnimation{
        let pulse1 = CASpringAnimation(keyPath: "transform.scale")
        pulse1.duration = 1.1
        pulse1.fromValue = 1
        pulse1.toValue = 1.3
        pulse1.autoreverses = true
        
        pulse1.repeatCount = .greatestFiniteMagnitude
        pulse1.damping = 9
        pulse1.mass = 1.2
        pulse1.fillMode = .both
        
        return pulse1
    }
    static func wobbleAnimation(startingAngle: Double = 0, angle: Double = .pi / 6, speed: CFTimeInterval = 1.0, repeatCount: Float = .greatestFiniteMagnitude ) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = startingAngle
        animation.toValue = angle
        animation.duration = speed // speed
        animation.repeatCount = repeatCount
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.autoreverses = true
        return animation
    }
    static func gyreAnimation(startingAngle: Double = 0, angle: Double = .pi * 2, speed: CFTimeInterval = 1.0, repeatCount: Float = .greatestFiniteMagnitude ) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = startingAngle
        animation.toValue = angle
        animation.duration = speed // speed
        animation.repeatCount = repeatCount
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        //        animation.autoreverses = true
        return animation
    }
    
    static func pulsingV3Animation(speed: CFTimeInterval = 0.9, scale: CGFloat = 1.1, repeatCount: Float = .greatestFiniteMagnitude)-> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = CATransform3DMakeScale(scale, 0, 0)
        animation.fromValue = CATransform3DMakeScale(0.9, 0, 0)
        animation.duration = speed
        
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.autoreverses = true
        animation.repeatCount = repeatCount
        animation.setValue("jumping", forKey: "listening")
        return animation
    }
    static func listeningAnimation(speed: CFTimeInterval = 0.9, scale: CGFloat = 1.3, repeatCount: Float = .greatestFiniteMagnitude) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.scale.y")
        animation.fromValue = 1
        animation.toValue = scale
        animation.duration = speed
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.autoreverses = true
        animation.repeatCount = repeatCount
        return animation
    }
    
    static func morphingAnimation(speed: CFTimeInterval = 0.3, scale: CGFloat = 0.9, fromValue: CGFloat = 1, repeatCount: Float = 1)-> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = CATransform3DMakeScale(scale, scale, 1)
        animation.fromValue = CATransform3DMakeScale(fromValue, fromValue, 1)
        animation.duration = speed
        
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.repeatCount = repeatCount
        return animation
    }
    
//    vocalising
    static func vocalisingAnimation(speed: CFTimeInterval = 0.5, scale: CGFloat = 1.1, repeatCount: Float = .greatestFiniteMagnitude) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 0.9
        animation.toValue = scale
        animation.duration = speed
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.autoreverses = true
        animation.repeatCount = repeatCount
//        animation.setValue("jumping", forKey: "listening")
        return animation
    }
}
fileprivate extension CALayer {
    var side: CGFloat{
        self.bounds.width
    }
}

public extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(origin: center.applying(CGAffineTransform(translationX: size.width / -2, y: size.height / -2)), size: size)
    }
    
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    var largestContainedSquare: CGRect {
        let side = min(width, height)
        return CGRect(center: center, size: CGSize(width: side, height: side))
    }
    
    var smallestContainingSquare: CGRect {
        let side = max(width, height)
        return CGRect(center: center, size: CGSize(width: side, height: side))
    }
    
}

public extension CGSize {
    func rescale(_ scale: CGFloat) -> CGSize {
        return applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}


final public class SVKPetalsAnimationView: UIView{
    public enum AnimationType: Equatable {
        case awaiting, listening(volume: CGFloat), processing, vocalising
        var petalHeightCoefficient: CGFloat{
            switch self{
            
            case .awaiting:
                return .petalHCoefficient
            case .listening:
                return .petalHCoefficientBig
            case .processing, .vocalising:
                return .petalHCoefficientSmall
            }
        }
    }
    struct ListeningData {
        var inListeningMode = false // global sequence of listening
        var isListeningFinished = true // to know if inidividual animation is finished
        var audioLevels: [CGFloat] = []
    }
    fileprivate var listeningData = ListeningData()
    
    private let containerLayer = CALayer()
    
    private var petals: [CAGradientLayer] = []
    fileprivate var _numberOfPetals:UInt8 = 0b110
    public var numberOfPetals:UInt8{
        get{
            return _numberOfPetals
        }
        set{
            _numberOfPetals = newValue
            configureLayers()
        }
    }
    var _petalPivotStride: CGFloat = 60
    public var petalPivotStride: CGFloat{
        get{
            return _petalPivotStride
        }
        set{
            _petalPivotStride = newValue
            configureLayers()
        }
    }
    var _listeningPulsingSpeed: CFTimeInterval = 0.2
    public var listeningPulsingSpeed: CFTimeInterval{
        get{
            return _listeningPulsingSpeed
        }
        set{
            _listeningPulsingSpeed = newValue
            configureLayers()
        }
    }
    var _backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    public override var backgroundColor: UIColor?{
        get {
            return _backgroundColor
        }
        set{
            if let color = newValue{
                _backgroundColor = color
                containerLayer.backgroundColor = backgroundColor?.cgColor
    
                // Refreshing the color : need to remove the layer and
                // add it again to avoid crash when animation is playing
//                innerCircle.removeFromSuperlayer()
//                innerCircle = createInnerCircle()
//                innerCircle.fillColor = _backgroundColor.cgColor
//                containerLayer.addSublayer(innerCircle)
            }
        }
    }
    var _innerCircleColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    public var innerCircleColor: UIColor?{
        get {
            return _innerCircleColor
        }
        set{
            if let color = newValue{
                _innerCircleColor = color
    
                // Refreshing the color : need to remove the layer and
                // add it again to avoid crash when animation is playing
                innerCircle.removeFromSuperlayer()
                innerCircle = createInnerCircle()
                innerCircle.fillColor = _innerCircleColor.cgColor
                containerLayer.addSublayer(innerCircle)
            }
        }
    }
    /// ## initializaiton
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLayers()
    }
    /// layers

    var innerCircle: CAShapeLayer = CAShapeLayer()
    private func createInnerCircle() -> CAShapeLayer{
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(ovalIn: CGRect(center: containerLayer.bounds.center,
                                                 size: containerLayer.bounds.size.rescale(.innerCircleRatio))).cgPath
        shape.lineWidth = 2
        shape.fillColor = innerCircleColor?.cgColor
        return shape
    }
    private func fillPetals(animation type: AnimationType = .awaiting){
        for index in 0..<numberOfPetals{
            let petal = createPetal(animation: type)
            let radians = getRadians(for: Int(index))
            
            petal.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
            if type == .processing || type == .vocalising {
                petal.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            }
            petals.append(petal)
        }
    }
    
    private func addPetalsSublayers(){
        petals.forEach { containerLayer.addSublayer($0)}
    }
    
    private func removePetalsSublayers(){
        petals.forEach {$0.removeFromSuperlayer()}
        petals = []
    }
    private func layoutPetals(){
        petals.forEach {
            $0.bounds = containerLayer.bounds
            $0.position = containerLayer.bounds.center
        }
    }
    
    private func createPetal(animation type: AnimationType = .awaiting)->CAGradientLayer{
        let startColor = UIColor(red: 226 / 255, green: 0 / 255, blue: 116 / 255, alpha: 0.46)
        let endColor = UIColor(red: 226 / 255, green: 0 / 255, blue: 116 / 255, alpha: 0)
        let shape = CAGradientLayer()
        shape.colors = [startColor, endColor].map{$0.cgColor}
        shape.frame = containerLayer.bounds
        shape.mask = createPetalMask(animation: type)
        return shape
    }
    private func createPetalMask(animation type: AnimationType = .awaiting)->CAShapeLayer{
        let layer_ = CAShapeLayer()
        layer_.path = UIBezierPath(ovalIn:rectangleForPetal(animation: type)).cgPath//ovalPath
        return layer_
    }
    
    private func getRadians(for index: Int)-> CGFloat{
        let degrees = CGFloat(integerLiteral: index) * petalPivotStride
        let radians = CGFloat(degrees * .pi / 180)
        return radians
    }
    /// helpers for animatePetals(animation type:) and animateInnerCircle(animation type:)
    fileprivate func animateInListeningMode(_ petal: CAGradientLayer, with angle: Double, and scale: CGFloat, and startingAngle: Double) {
        let randomRange = 1.0...Double(scale)
        if let animKeys = petal.animationKeys() {
            if !animKeys.contains("wobble_listening") {//there is no yet wobbling animation
                petal.add(.wobbleAnimation(startingAngle: startingAngle, angle: angle, speed: Double.random(in: randomRange) * 2) , forKey: "wobble_listening")
            }
        }else{//there is not yet animation added
            petal.add(.wobbleAnimation(startingAngle: startingAngle, angle: angle, speed: Double.random(in: randomRange)), forKey: "wobble_listening")
        }
        
        petal.add(.pulsingAnimation(speed: listeningPulsingSpeed,
                                    scale: scale ,
                                    repeatCount: 1), forKey: "pulse_listening")
    }
    fileprivate func animateCircleInListeningMode(with scale: CGFloat) {
        innerCircle.add(.morphingAnimation(speed: 0.3, scale: 0.9, fromValue: 1), forKey: "morphing_listening")
        let innerCircleAnimation: CABasicAnimation = .pulsingV3Animation(speed: listeningPulsingSpeed,
                                                                         scale: scale,
                                                                         repeatCount: 1)
        innerCircleAnimation.delegate = self
        innerCircle.add(innerCircleAnimation, forKey: "pulse_listening")
    }
    ///main animation routine
    private func animatePetals(animation type: AnimationType = .awaiting){
        for (index, petal) in petals.enumerated(){
            
            // index % 2 will return 1 or 0 :  each even element should be negative
            // index % 2 - 1 will return 0 or -1 : we need to transform 0 to 1
            // (index % 2 - 1) | 1 will return 1 or -1
            // ((index % 2 - 1) | 1) * Double.pi / 6
            //            let angle: Double = Double((index % 2 - 1) | 1) * .pi / Double((Int(numberOfPetals) - index))
//            let angle: Double = Double((index % 2 - 1) | 1) * .pi * 2
            let startingAngle = Double(getRadians(for: index))
            let angle: Double = Double((index % 2 - 1) | 1) * .pi * 2 + startingAngle
            switch type{
            
            case .awaiting:
                let speed: TimeInterval = Double(index) + 2//Double(index) * 0.1 + 2.4
                
                petal.add(.gyreAnimation(startingAngle: startingAngle, angle: angle, speed: speed), forKey: "gyre_awaiting")
                
                petal.add(.pulsingAnimation(speed: speed, scale: CGFloat.random(in: 1...1.1), fromValue: 1), forKey: "pulse_awaiting")
            case .listening(let volume):
                animateInListeningMode(petal, with: angle, and: volume, and: startingAngle)
            case .processing:
                petal.add(.morphingAnimation(), forKey: "morphing_processing")

                petal.add(.gyreAnimation(startingAngle: startingAngle, angle: angle, speed: 1.8), forKey: "gyre_processing")
            case .vocalising:
                petal.add(.morphingAnimation(scale: 0.8), forKey: "morphing_vocalising")
                let rotationAngle: Double = 2 * .pi + startingAngle
                let speed: TimeInterval = Double(index) * 0.1 + 0.7//2.8
                petal.add(.gyreAnimation(startingAngle: startingAngle, angle: rotationAngle, speed: speed), forKey: "gyre_vocalising")
                petal.add(.vocalisingAnimation(), forKey: "xpulsing_vocalising")
            }
            
        }
    }

    
    private func animateInnerCircle(animation type: AnimationType = .awaiting){
        innerCircle.bounds = containerLayer.bounds
        innerCircle.position = containerLayer.bounds.center
        switch type{
        case .awaiting:
            break
        case .listening(let scale):
            animateCircleInListeningMode(with: scale)
        case .processing:
            innerCircle.add(.morphingAnimation(scale: 0.9, fromValue: 0.7), forKey: "morphing_processing")
        case .vocalising:
            innerCircle.add(.morphingAnimation(scale: 0.9, fromValue: 0.7), forKey: "morphing_vocalising")
        
        }
    }
    
    private func configureLayers() {
        containerLayer.frame = bounds.largestContainedSquare
        containerLayer.backgroundColor = backgroundColor?.cgColor
        
        layer.addSublayer(containerLayer)
        //empty old petals
        removePetalsSublayers()
        
        // constract petals
        fillPetals()
        addPetalsSublayers()
        
        // MARK: - innerCircle should be always on top
        innerCircle.removeFromSuperlayer()
        innerCircle = createInnerCircle()
        innerCircle.fillColor = innerCircleColor?.cgColor
        
        containerLayer.addSublayer(innerCircle)
        
    }
    
}
extension SVKPetalsAnimationView{
    public func reloadUI(){
        configureLayers()
    }
    private func rectangleForPetal(animation type: AnimationType = .awaiting)->CGRect{
        let s = CGSize(width: self.containerLayer.side, height: self.containerLayer.side * type.petalHeightCoefficient)
        let r = CGRect(center: containerLayer.bounds.center,
                       size: s.rescale(.petalRatio))
        
        return r
    }
    
    public func start(animation: AnimationType = .awaiting){
        
        
        if containerLayer.sublayers?.count == 1{ // there is only inner circle
            fillPetals(animation: animation)
            addPetalsSublayers()
            innerCircle.zPosition = 1 // move up
        }
        
        layoutPetals()
        
       restart(animation: animation)
    }
    public func stop(){
        pause()
        removePetalsSublayers()
    }
    public func pause(){
        listeningData.inListeningMode = false
        innerCircle.removeAllAnimations()
        petals.forEach { $0.removeAllAnimations()}
    }
    public func freeze(){
        innerCircle.pauseAnimation()
        petals.forEach { $0.pauseAnimation()}
    }
    public func unfreeze(){
        innerCircle.resumeAnimation()
        petals.forEach { $0.resumeAnimation()}
    }

    // remove silently animations from CALayer started on previus cicle
    private func clean(animation:AnimationType){
        switch animation {
        case .awaiting:
            petals.forEach {
                $0.removeAnimation(forKey: "wobble_listening")// remove listening
                $0.removeAnimation(forKey: "pulse_listening")// remove listening
                $0.removeAnimation(forKey: "gyre_processing")// remove processing
                $0.removeAnimation(forKey: "morphing_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "xpulsing_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "gyre_vocalising")// remove vocalising
            }
            ["pulse_listening", "morphing_processing"].forEach { innerCircle.removeAnimation(forKey:$0) }
    
            listeningData.inListeningMode = false
            listeningData.audioLevels = []
        case .listening:
            petals.forEach {
                $0.removeAnimation(forKey: "gyre_awaiting")// remove awaiting
                $0.removeAnimation(forKey: "gyre_processing")// remove processing
                $0.removeAnimation(forKey: "pulse_awaiting")// remove awaiting
                $0.removeAnimation(forKey: "morphing_processing")// remove processing
                $0.removeAnimation(forKey: "morphing_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "xpulsing_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "gyre_vocalising")// remove vocalising
            }
            innerCircle.removeAnimation(forKey: "morphing_processing")
        case .processing:
            petals.forEach {
                $0.removeAnimation(forKey: "wobble_listening")// remove listening
                $0.removeAnimation(forKey: "pulse_listening")// remove listening
                $0.removeAnimation(forKey: "morphing_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "gyre_vocalising")// remove vocalising
                $0.removeAnimation(forKey: "xpulsing_vocalising")// remove vocalising
            }
            innerCircle.removeAnimation(forKey: "pulse_listening")
            listeningData.inListeningMode = false
            listeningData.audioLevels = []
        case .vocalising:
            petals.forEach {
                $0.removeAnimation(forKey: "gyre_awaiting")// remove awaiting
                $0.removeAnimation(forKey: "gyre_processing")// remove processing
                $0.removeAnimation(forKey: "pulse_awaiting")// remove awaiting
                $0.removeAnimation(forKey: "morphing_processing")// remove processing
            }
            innerCircle.removeAnimation(forKey: "pulse_listening")
            innerCircle.removeAnimation(forKey: "morphing_vocalising")
            listeningData.inListeningMode = false
            listeningData.audioLevels = []
        }
    }
    //may be |resume| is better name ?
    public func restart(animation: AnimationType = .awaiting){
        SVKLogger.debug("animation = \(animation)")
        clean(animation: animation)
        switch animation {
        case .awaiting:
            animatePetals(animation: .awaiting)
            animateInnerCircle()
        case .listening:
            enterInListeningMode(animation)
        case .processing:
//            innerCircle.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            innerCircle.bounds = containerLayer.bounds
            innerCircle.position = containerLayer.bounds.center
            animatePetals(animation: .processing)
            animateInnerCircle(animation: .processing)
        case .vocalising:
            animatePetals(animation: .vocalising)
        }
    }
    private func enterInListeningMode(_ listeningType: AnimationType){
        listeningData.inListeningMode = true // starting listening mode
        if case let AnimationType.listening(volume) = listeningType {
            if listeningData.audioLevels.count == 2 {
                listeningData.audioLevels.removeLast()
            }
            listeningData.audioLevels.append(volume)
        }
        
        launchListeningAnimation()
    }
    private func launchListeningAnimation(){
        let powerCoefficient: CGFloat = 1 / 1.5 / 0.55 // max should not be more than 1.4
        if listeningData.isListeningFinished{
            listeningData.isListeningFinished = false
            var circleListeningType = AnimationType.listening(volume: powerCoefficient)// default value
            var petalsListeningType = AnimationType.listening(volume: powerCoefficient)// default value
            
            if let volume = listeningData.audioLevels.first{
                let amplitudeForCircle: CGFloat = 1 + (volume * 0.3)

                let petalsCoef = AnimationType.awaiting.petalHeightCoefficient * CGFloat.petalRatio
         
                var amplitudeForPetals: CGFloat =  CGFloat(1 / (petalsCoef) * (volume * 2.0) )
                if amplitudeForPetals >= 1 / (petalsCoef) * 0.9{ // due to Alexander's remark
                    amplitudeForPetals = 1 / (petalsCoef) * 0.9
                } else if (amplitudeForPetals <= 1) {
                    amplitudeForPetals = 1.1
                }
                _ = listeningData.audioLevels.removeFirst()
                circleListeningType = AnimationType.listening(volume: amplitudeForCircle)
                petalsListeningType = AnimationType.listening(volume: amplitudeForPetals)
                animatePetals(animation: petalsListeningType)
                animateInnerCircle(animation: circleListeningType)
            } else {
                listeningData.isListeningFinished = true
            }
        }
    }
}
extension SVKPetalsAnimationView: CAAnimationDelegate{
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    
        // if in listening mode
        if let v = anim.value(forKey: "listening") as? String,
           v == "jumping"{
            listeningData.isListeningFinished = true
            if listeningData.inListeningMode{
                if !listeningData.audioLevels.isEmpty{
                    launchListeningAnimation()
                }
            }
        }
    }
}
