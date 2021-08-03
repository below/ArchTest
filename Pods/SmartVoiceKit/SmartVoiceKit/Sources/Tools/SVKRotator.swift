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
private extension UIBezierPath{
    static func openCircle(in rect: CGRect) -> UIBezierPath{
        let ovalPath = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        let startAngle = 0 * CGFloat.pi/180
        let endAngle = -65 * CGFloat.pi/180
        ovalPath.addArc(withCenter: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: true)

        ovalPath.lineCapStyle = .round
        return ovalPath
    }
}
infix operator ---: AdditionPrecedence
private extension CGRect{
        static func --- (left: CGRect, right: UInt8) -> CGRect{
            let dlt = CGFloat(right)
            return CGRect(x: left.origin.x + dlt / 2,
                          y: left.origin.y + dlt / 2,
                          width: left.width - dlt,
                          height: left.height - dlt)
        }
    
}

// create idicator
final class SVKRotator: UIView{
    public enum TerminationStyle{
        case erase, fadeOut, none
    }
    
    public enum AnimationSpeed{
        case slow, medium, high
        var speed: CFTimeInterval{
            switch self{
            case .slow:
                return 1.7
            case .medium:
                return 1.0
            case .high:
                return 0.7
            }
        }
    }
    
    var indicatorWidth: UInt8 = 0b10{
        didSet{
            adjustCircle()
        }
    }
    var indicatorColor: CGColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1).cgColor{
        didSet{
            spinnerShape.strokeColor = indicatorColor
        }
    }
    var rotationSpeed: AnimationSpeed = .slow

    private(set) var animating: Bool = false
    private lazy var spinnerShape: CAShapeLayer = {
        let shape = CAShapeLayer()
        /// Oval Drawing ○ -> ◠

        let ovalPath = UIBezierPath.openCircle(in: self.layer.bounds --- indicatorWidth).cgPath
        shape.path = ovalPath
        
        shape.lineWidth = CGFloat(indicatorWidth)
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1).cgColor
        shape.lineCap = .round

        return shape
    }()
    
    private lazy var spinAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: RotatorAnimationType.spin.rawValue)
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.duration = rotationSpeed.speed // speed
        animation.repeatCount = .greatestFiniteMagnitude
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        return animation
    }()
    
    private lazy var eraseAnimation: CABasicAnimation = {
        let animation = CABasicAnimation()

        animation.duration = 0.5
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.keyPath = RotatorAnimationType.erase.rawValue
        animation.toValue = 1
        animation.fromValue = 0
        animation.delegate = self
        return animation

    }()
    
    private lazy var fadeOutAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: RotatorAnimationType.wane.rawValue)
        animation.toValue = CATransform3DMakeScale(0.1, 0.1, 1)
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        return animation
    }()
    
    private lazy var shrinkAnimation: CABasicAnimation = {
            let animation = CABasicAnimation()

            animation.duration = 1.0
            animation.fillMode = .both
            animation.isRemovedOnCompletion = false
            animation.autoreverses = true
            animation.beginTime = CACurrentMediaTime() + 0.25
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.keyPath = "strokeEnd"
        animation.toValue = 0.2
            animation.fromValue = 0.7
            animation.repeatCount = .greatestFiniteMagnitude
            return animation

        }()
    private func adjustCircle(){
        spinnerShape.lineWidth = CGFloat(indicatorWidth)
        let ovalPath = UIBezierPath.openCircle(in: self.layer.bounds --- indicatorWidth).cgPath
        spinnerShape.path = ovalPath
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLayers()
    }
    
    private func configureLayers(){
        placeLayer()
        layer.addSublayer(spinnerShape)
    }
    
    private func placeLayer(){
        spinnerShape.bounds = layer.bounds
        spinnerShape.position = layer.bounds.center
        spinnerShape.isHidden = false
    }
    
    func start(){
        placeLayer()
        animating = true
        spinnerShape.add(spinAnimation, forKey: "spin")
        spinnerShape.add(shrinkAnimation, forKey: "shrink")
    }
    
    func stop(animation: TerminationStyle = .none){

        switch animation{
        case .erase:
            spinnerShape.add(eraseAnimation, forKey: "erase")
        case .fadeOut:
            spinnerShape.add(fadeOutAnimation, forKey: "fadeOut")

        case .none:
            spinnerShape.isHidden = true
            spinnerShape.removeAnimation(forKey: "spin")
        }
        
        animating = false
    }
}

extension SVKRotator: CAAnimationDelegate{
    enum RotatorAnimationType: String{
        case spin = "transform.rotation.z"
        case erase = "strokeStart"
        case wane = "transform.scale"
    }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let key = anim.value(forKey:#keyPath(CABasicAnimation.keyPath)) as? String else { return }
        if key == RotatorAnimationType.spin.rawValue{
            spinnerShape.removeAllAnimations()
            spinnerShape.isHidden = true
        }
        if key == RotatorAnimationType.erase.rawValue{
            spinnerShape.removeAllAnimations()
            spinnerShape.isHidden = true
        }
        if key == RotatorAnimationType.wane.rawValue{
            spinnerShape.removeAllAnimations()
            spinnerShape.isHidden = true
            
        }
    }
}
extension SVKRotator{
    func lurkSpinner(_ lurked: Bool){
            spinnerShape.isHidden = lurked
    }
}
