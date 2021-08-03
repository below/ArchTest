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

/**
 The bubble's pin style
 */
public enum SVKPinStyle: Equatable {
    public enum Direction {
        case left
        case right
    }
    case `default`
    case pinStyle1(Direction)

    var size: CGSize {
        switch self {
        case .pinStyle1(_):
            return CGSize(width: 8, height: 8)
        default:
            return CGSize.zero
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .pinStyle1(_):
            return 2
        default:
            return 0
        }
    }

    var insets: UIEdgeInsets {
        switch self {
        case .pinStyle1(let direction) where direction == .left:
           return UIEdgeInsets(top: 0, left: size.width, bottom: 0, right: 0)

        case .pinStyle1(let direction) where direction == .right:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: size.width)

        default:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}

/**
 The OBConer stye
 */
public enum SVKCornerStyle {
    case round
    case square
}

/**
 Represent the position of the corner and it's radius
 */
public enum SVKCornerPosition {
    case topLeft(CGFloat)
    case topRight(CGFloat)
    case bottomRight(CGFloat)
    case bottomLeft(CGFloat)

    public var radius: CGFloat {
        switch self {
        case .topLeft(let radius): return radius
        case .topRight(let radius): return radius
        case .bottomRight(let radius): return radius
        case .bottomLeft(let radius): return radius
        }
    }
}

extension SVKCornerPosition: RawRepresentable, Hashable {

    public typealias RawValue = Int

    public init?(rawValue: Int, radius: CGFloat) {
        switch rawValue {
        case 1: self = .topLeft(radius)
        case 2: self = .topRight(radius)
        case 3: self = .bottomRight(radius)
        case 4: self = .bottomLeft(radius)
        default: return nil
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 1: self = .topLeft(SVKCorner.defaultRadius)
        case 2: self = .topRight(SVKCorner.defaultRadius)
        case 3: self = .bottomRight(SVKCorner.defaultRadius)
        case 4: self = .bottomLeft(SVKCorner.defaultRadius)
        default: return nil
        }
    }

    /// Backing raw value
    public var rawValue: RawValue {
        switch self {
        case .topLeft: return 1
        case .topRight: return 2
        case .bottomRight: return 3
        case .bottomLeft: return 4
        }
    }

    public var hashValue: Int {
        return rawValue
    }
}

/**
 A corner of an SVKBubble
 */
public struct SVKCorner: Hashable, Equatable {
    
    /// The default radius
    public static let defaultRadius = CGFloat(18)

    /// The corner style
    public var style: SVKCornerStyle = .round

    /// The position of the corner
    public var position: SVKCornerPosition = .topLeft(SVKCorner.defaultRadius)

    init(_ position: SVKCornerPosition) {
        self.position = position
    }

    // MARK: Hashable conformance
    public func hash(into hasher: inout Int) {
        hasher = position.hashValue
    }
    
    public static func ==(lhs: SVKCorner, rhs: SVKCorner) -> Bool {
        return lhs.position == rhs.position
    }

    static func topLeft() -> SVKCorner {
        return SVKCorner(.topLeft(SVKCorner.defaultRadius))
    }

    static func topRight() -> SVKCorner {
        return SVKCorner(.topRight(SVKCorner.defaultRadius))
    }

    static func bottomRight() -> SVKCorner {
        return SVKCorner(.bottomRight(SVKCorner.defaultRadius))
    }

    static func bottomLeft() -> SVKCorner {
        return SVKCorner(.bottomLeft(SVKCorner.defaultRadius))
    }

    var radius: CGFloat {
        return position.radius
    }
}

/**
 The bubble alignment
 */
public enum SVKBubbleAlignement: String {
    case left, right
}

/**
 The bubble style
 */
public enum SVKBubbleStyle {
    case `default`(SVKBubbleAlignement)
    case top(SVKBubbleAlignement)
    case middle(SVKBubbleAlignement)
    case bottom(SVKBubbleAlignement)
}

public func ==(lhs: SVKBubbleStyle, rhs: SVKBubbleStyle) -> Bool {
    switch (lhs, rhs) {
    case let (.default(a),   .default(b)),
         let (.top(a), .top(b)),
         let (.middle(a), .middle(b)),
         let (.bottom(a), .bottom(b)):
        return a == b
    default:
        return false
    }
}

public func !=(lhs: SVKBubbleStyle, rhs: SVKBubbleStyle) -> Bool {
    return !(lhs==rhs)
}

/**
 A view that represents a bubble.
 Base an a UILabel, it is easy to integrate in a conversation app
 */
@IBDesignable
open class SVKBubble: UIView {

    /// the bubble layer
    internal var shapeLayer: CAShapeLayer {
        return self.layer as! CAShapeLayer
    }
    
    /// The default contentInset
    public var contentInset: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

    /// A closure called when a long press on the bull is recognize
    public var longPressAction: ((SVKBubble, Any) -> Void)?

    /// A closure called when a tap on the bull is recognize
    public var tapAction: ((SVKBubble, Any) -> Void)?

    /// The corners
    private var corners: NSOrderedSet = NSOrderedSet() {
        didSet {
            shapeLayer.setNeedsDisplay()
        }
    }

    // IB customization
    @IBInspectable public var foregroundColor: UIColor = .defaultUserColor {
        didSet {
            shapeLayer.fillColor = foregroundColor.cgColor
        }
    }

    /// The bubble border color. Default to .borderColor
    @IBInspectable public var borderColor: UIColor = .defaultBorderColor {
        didSet {
            shapeLayer.strokeColor = borderColor.cgColor
        }
    }

    // IB customization
    @IBInspectable public var layerBorderWidth: CGFloat = SVKBubble.defaultborderWidth {
        didSet { shapeLayer.lineWidth = layerBorderWidth }
    }
    
    /// The default font
    static public var defaultborderWidth: CGFloat  {
        return CGFloat(1.5)
    }
    
    /// The bubble cornerRadius. Default to OBCorner.defaultRadius
    @IBInspectable public var cornerRadius: CGFloat = SVKCorner.defaultRadius {
        didSet {
            // Set the style with the new cornerRadius
            let s = style
            style = s
        }
    }

    /// The bubble pin style
    public var pinStyle: SVKPinStyle = .default {
        didSet {
            // Set the style with the new cornerRadius
            let s = style
            style = s
        }
    }
    
    /// The style
    public var style: SVKBubbleStyle = .default(.left) {
        didSet {
            switch style {

            case .top(let alignement) where alignement == .left:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(cornerRadius)), SVKCorner(.bottomLeft(2)), SVKCorner(.topLeft(cornerRadius)), SVKCorner(.topRight(cornerRadius)))
            case .top(let alignement) where alignement == .right:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(2)), SVKCorner(.bottomLeft(cornerRadius)), SVKCorner(.topLeft(cornerRadius)), SVKCorner(.topRight(cornerRadius)))

            case .middle(let alignement) where alignement == .left:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(cornerRadius)), SVKCorner(.bottomLeft(2)), SVKCorner(.topLeft(2)), SVKCorner(.topRight(cornerRadius)))
            case .middle(let alignement) where alignement == .right:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(2)), SVKCorner(.bottomLeft(cornerRadius)), SVKCorner(.topLeft(cornerRadius)), SVKCorner(.topRight(2)))

            case .bottom(let alignement) where alignement == .left:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(cornerRadius)), SVKCorner(.bottomLeft(cornerRadius)), SVKCorner(.topLeft(2)), SVKCorner(.topRight(cornerRadius)))
            case .bottom(let alignement) where alignement == .right:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(cornerRadius)), SVKCorner(.bottomLeft(cornerRadius)), SVKCorner(.topLeft(cornerRadius)), SVKCorner(.topRight(2)))
            default:
                self.corners = NSOrderedSet(arrayLiteral: SVKCorner(.bottomRight(cornerRadius)), SVKCorner(.bottomLeft(cornerRadius)), SVKCorner(.topLeft(cornerRadius)), SVKCorner(.topRight(cornerRadius)))
                break
            }
        }
    }

    open override var translatesAutoresizingMaskIntoConstraints: Bool {
        didSet {
            if translatesAutoresizingMaskIntoConstraints == false {
                self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height, multiplier: 1, constant: 36))
            }
        }
    }

    open func setup() {

        isOpaque = true
        backgroundColor = .clear
        
        self.corners = NSOrderedSet(arrayLiteral: SVKCorner.bottomRight(), SVKCorner.bottomLeft(), SVKCorner.topLeft(), SVKCorner.topRight())

        isUserInteractionEnabled = true
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    /**
     Convenience method to initialise a type of bubble
     */
    public convenience init(style: SVKBubbleStyle = .default(.left)) {
        self.init(frame: .zero)
        self.style = style
    }

    /**
     Update the layer path.
     The path is determine by the configured corners
     */
    private func updateShapeLayerPath() {

        let path = UIBezierPath()

        switch pinStyle {
        case .pinStyle1(let direction) where direction == .left:
            
            // 1st rounded corner - placed at bottom right
            var radius = (self.corners[0] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: bounds.maxY - radius), radius: radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            
            // 2nd rounded corner - placed at bottom left
            radius = (self.corners[1] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: 0, y: bounds.maxY), radius: 0, startAngle: 2 * CGFloat.pi / 4, endAngle: CGFloat.pi, clockwise: true)
            
            // 3rd rounded corner - placed at top left
            radius = (self.corners[2] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            
            // 4rd rounded corner - placed at top right
            radius = (self.corners[3] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: radius), radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
            //Old code with pointed corner for magenta skin
//            // 1st rounded corner - placed at bottom right
//            var radius = (self.corners[0] as! SVKCorner).radius
//            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: bounds.maxY - radius), radius: radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
//
//            // 2nd rounded corner - placed at bottom left
//            let pinRadius = pinStyle.radius
//            let pinSize = pinStyle.size
//            path.addArc(withCenter: CGPoint(x: pinRadius, y: bounds.maxY - pinRadius), radius: pinRadius, startAngle: 2 * CGFloat.pi / 4, endAngle: CGFloat.pi, clockwise: true)
//
//            // 3rd the pin line
//            path.addLine(to: CGPoint(x: bounds.minX + pinSize.width, y: bounds.maxY - pinSize.height))
//
//            // 4rd rounded corner - placed at top left
//            radius = (self.corners[2] as! SVKCorner).radius
//            path.addLine(to: CGPoint(x: bounds.minX + pinSize.width, y: bounds.minY + radius))
//            path.addArc(withCenter: CGPoint(x: bounds.minX + pinSize.width + radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
//
//            // 5th rounded corner - placed at top right
//            radius = (self.corners[3] as! SVKCorner).radius
//            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: radius), radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        case .pinStyle1(let direction) where direction == .right:
            
            // 1st rounded corner - placed at bottom right
            var radius = (self.corners[0] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX, y: bounds.maxY), radius: 0, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            
            // 2nd rounded corner - placed at bottom left
            radius = (self.corners[1] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: radius, y: bounds.maxY - radius), radius: radius, startAngle: 2 * CGFloat.pi / 4, endAngle: CGFloat.pi, clockwise: true)
            
            // 3rd rounded corner - placed at top left
            radius = (self.corners[2] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            
            // 4rd rounded corner - placed at top right
            radius = (self.corners[3] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: radius), radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        //Old code with pointed corner for magenta skin
//            // 1st pin line
//            let pinRadius = pinStyle.radius
//            let pinSize = pinStyle.size
//            var radius = (self.corners[0] as! SVKCorner).radius
//            path.move(to: CGPoint(x: bounds.maxX - pinSize.width, y: bounds.maxY - pinSize.height))
//            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
//
//            // 1st rounded corner - placed at bottom right
//            path.addArc(withCenter: CGPoint(x: bounds.maxX - pinRadius, y: bounds.maxY - pinRadius), radius: pinRadius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
//
//            // 2nd rounded corner - placed at bottom left
//            radius = (self.corners[1] as! SVKCorner).radius
//            path.addArc(withCenter: CGPoint(x: radius, y: bounds.maxY - radius), radius: radius, startAngle: 2 * CGFloat.pi / 4, endAngle: CGFloat.pi, clockwise: true)
//
//            // 3rd rounded corner - placed at top left
//            radius = (self.corners[2] as! SVKCorner).radius
//            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
//
//            // 4rd rounded corner - placed at top right
//            radius = (self.corners[3] as! SVKCorner).radius
//            path.addArc(withCenter: CGPoint(x: bounds.maxX - (radius + pinSize.width), y: radius), radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)

        default:
            // 1st rounded corner - placed at bottom right
            var radius = (self.corners[0] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: bounds.maxY - radius), radius: radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            
            // 2nd rounded corner - placed at bottom left
            radius = (self.corners[1] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: radius, y: bounds.maxY - radius), radius: radius, startAngle: 2 * CGFloat.pi / 4, endAngle: CGFloat.pi, clockwise: true)
            
            // 3rd rounded corner - placed at top left
            radius = (self.corners[2] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            
            // 4rd rounded corner - placed at top right
            radius = (self.corners[3] as! SVKCorner).radius
            path.addArc(withCenter: CGPoint(x: bounds.maxX - radius, y: radius), radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        }
        
        path.close()
        shapeLayer.path = path.cgPath
    }

    override open func draw(_ rect: CGRect) {
        updateShapeLayerPath()
    }
    
    override open func draw(_ layer: CALayer, in ctx: CGContext) {
        updateShapeLayerPath()
    }
    
    override open class var layerClass : AnyClass {
        return SVKBubbleShapeLayer.self
    }
}

// MARK: The layer class
final class SVKBubbleShapeLayer: CAShapeLayer {
    
    internal let maskLayer = CAShapeLayer()
    
    internal var borderLayer: CAShapeLayer? = nil
    override var path: CGPath? {
        didSet {
            maskLayer.path = path
            updateBorder()
        }
    }
    
    internal func updateBorder() {
        if let borderLayer = self.borderLayer {
            borderLayer.removeFromSuperlayer()
        }
        if self.strokeColor != UIColor.clear.cgColor {
            self.borderLayer = CAShapeLayer()
            self.borderLayer?.path = maskLayer.path
            self.borderLayer?.fillColor = UIColor.clear.cgColor
            self.borderLayer?.strokeColor = self.strokeColor
            self.borderLayer?.lineWidth = 1.5
            self.borderLayer?.frame = self.bounds
            self.addSublayer(self.borderLayer!)
        }
    }
    override var strokeColor: CGColor? {
        didSet {
            updateBorder()
        }
    }
    
    override init() {
        super.init()
        self.lineWidth = 1.5
        self.mask = maskLayer
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
}
