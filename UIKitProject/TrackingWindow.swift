//
//  TrackingWindow.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 17/12/25.
//

import UIKit

final class TouchOverlayWindow: UIWindow {
    
    private let overlayView = TouchOverlayView()
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        
        windowLevel = .statusBar + 1
        backgroundColor = .clear
        isHidden = false
        
        overlayView.frame = bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(overlayView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handle(touch: UITouch, in event: UIEvent?) {
        let point = touch.location(in: self)
        
        switch touch.phase {
        case .began:
            overlayView.begin(at: point)
        case .moved:
            overlayView.append(point)
        case .ended, .cancelled:
            overlayView.end()
        default:
            break
        }
    }
}

final class TouchOverlayView: UIView {

    // MARK: - Path (Gradient)

    private let path = UIBezierPath()
    private let pathMaskLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()

    // MARK: - Crosshair + Circle

    private let crosshairLayer = CAShapeLayer()
    private let circleLayer = CAShapeLayer()

    // MARK: - HUD

    private let infoLabel = UILabel()

    // MARK: - State

    private var startPoint: CGPoint?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        // ---- Gradient Path ----

        path.lineWidth = 4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        pathMaskLayer.fillColor = UIColor.clear.cgColor
        pathMaskLayer.strokeColor = UIColor.black.cgColor
        pathMaskLayer.lineWidth = path.lineWidth

        gradientLayer.colors = [
            UIColor.systemRed.cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradientLayer.mask = pathMaskLayer

        // ---- Crosshair ----

        crosshairLayer.strokeColor = UIColor.systemGreen.cgColor
        crosshairLayer.lineWidth = 1
        crosshairLayer.fillColor = UIColor.clear.cgColor

        // ---- Touch Circle ----

        circleLayer.strokeColor = UIColor.gray.withAlphaComponent(0.75).cgColor
        circleLayer.lineWidth = 2
        circleLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(gradientLayer)
        layer.addSublayer(crosshairLayer)
        layer.addSublayer(circleLayer)

        // ---- HUD ----

        infoLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        infoLabel.textColor = .white
        infoLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        infoLabel.layer.cornerRadius = 8
        infoLabel.layer.masksToBounds = true
        infoLabel.text = "x: –  y: –  dx: –  dy: –"

        addSubview(infoLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
        pathMaskLayer.frame = bounds
        crosshairLayer.frame = bounds
        circleLayer.frame = bounds

        let padding: CGFloat = 12
        infoLabel.sizeToFit()
        infoLabel.frame = CGRect(
            x: padding,
            y: safeAreaInsets.top + padding,
            width: infoLabel.bounds.width + 16,
            height: infoLabel.bounds.height + 10
        )
    }

    // MARK: - Touch Lifecycle

    func begin(at point: CGPoint) {
        path.removeAllPoints()
        path.move(to: point)
        pathMaskLayer.path = path.cgPath

        startPoint = point

        updateCrosshair(at: point)
        updateCircle(at: point)
        updateHUD(current: point)
    }

    func append(_ point: CGPoint) {
        path.addLine(to: point)
        pathMaskLayer.path = path.cgPath

        updateCrosshair(at: point)
        updateCircle(at: point)
        updateHUD(current: point)
    }

    func end() {
        startPoint = nil
        crosshairLayer.path = nil
        circleLayer.path = nil
    }

    // MARK: - Visual Updates

    private func updateCrosshair(at point: CGPoint) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: point.x, y: 0))
        path.addLine(to: CGPoint(x: point.x, y: bounds.height))
        path.move(to: CGPoint(x: 0, y: point.y))
        path.addLine(to: CGPoint(x: bounds.width, y: point.y))
        crosshairLayer.path = path.cgPath
    }

    private func updateCircle(at point: CGPoint) {
        let radius: CGFloat = 8
        let path = UIBezierPath(
            arcCenter: point,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        circleLayer.path = path.cgPath
    }

    private func updateHUD(current: CGPoint) {
        guard let start = startPoint else { return }

        let dx = current.x - start.x
        let dy = current.y - start.y

        infoLabel.text =
            "x: \(Int(current.x))  y: \(Int(current.y))  dx: \(Int(dx))  dy: \(Int(dy))"

        setNeedsLayout()
    }
}

final class TrackingWindow: UIWindow {
    
    var overlayWindow: TouchOverlayWindow?
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        guard let touches = event.allTouches else { return }
        
        for touch in touches where touch.type == .direct {
            overlayWindow?.handle(touch: touch, in: event)
        }
    }
}
