//
//  PanViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 22/10/25.
//

import UIKit

protocol PanViewDataSource: BaseViewModel {}

final class PanViewModel: PanViewDataSource {}

final class PanView<VM: PanViewDataSource>: UIView {
    private let containerView: UIView = UIView()
    private let squareView: UIView = UIView()
    
    private var isCenterSet: Bool = false
    private let width: CGFloat = 100
    private let height: CGFloat = 100
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !isCenterSet else { return }
        isCenterSet = true
        squareView.center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
    }
    
    @objc
    private func panGestured(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            squareView.center = gesture.location(in: containerView)
        case .ended:
            setViewFrame(gesture.location(in: containerView))
        default:
            break
        }
    }
}

extension PanView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}

private extension PanView {
    func createViews() {
        backgroundColor = .green
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        containerView.backgroundColor = .red
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        squareView.backgroundColor = .systemBlue
        containerView.addSubview(squareView)
        squareView.frame = CGRect(x: .zero, y: .zero, width: width, height: height)
        addGesture()
    }
    
    func addGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestured))
        squareView.addGestureRecognizer(panGesture)
    }
    
    func setViewFrame(_ point: CGPoint) {
        let maxX = containerView.bounds.maxX - (width / 2)
        let minX = containerView.bounds.minX + (width / 2)
        let minXDiff = abs(point.x - minX)
        let maxXDiff = abs(point.x - maxX)
        
        let maxY = containerView.bounds.maxY - (height / 2)
        let minY = containerView.bounds.minY + (height / 2)
        let minYDiff = abs(point.y - minY)
        let maxYDiff = abs(point.y - maxY)
        
        let newPoint: CGPoint = {
            let x: CGFloat
            let y: CGFloat
            
            if minXDiff < maxXDiff {
                x = minX
            } else {
                x = maxX
            }
            
            if minYDiff < maxYDiff {
                y = minY
            } else {
                y = maxY
            }
            
            return CGPoint(x: x, y: y)
        }()
        
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.squareView.center = newPoint
        }
    }
}
