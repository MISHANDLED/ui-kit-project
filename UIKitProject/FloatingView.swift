//
//  FloatingView.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 23/10/25.
//

import AVFoundation
import UIKit

final class FloatingView: UIView {
    private let containerView = UIView()
    private let hStack = UIStackView()
    private let title = UILabel()
    private let icon = UIImageView()
    private let gradientView: GradientView = GradientView()
    
    private var isExpanded = true
    private var animator: UIViewPropertyAnimator?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let animator = animator, animator.state != .inactive {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }
    
    func collapse() {
        guard isExpanded else { return }
        
        isExpanded = false
        animator.take()?.stopAnimation(true)
        
        animator = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) { [weak self] in
            guard let self = self else { return }
            self.title.alpha = 0
            self.title.isHidden = true
            self.layoutIfNeeded()
        }
        
        animator?.startAnimation()
    }
    
    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        
        animator.take()?.stopAnimation(true)
        
        animator = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) { [weak self] in
            guard let self = self else { return }
            title.isHidden = false
            self.title.alpha = 1
            self.layoutIfNeeded()
        }
        
        animator?.startAnimation()
    }
}

private extension FloatingView {
    func createViews() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBlue
        
        containerView.addSubview(gradientView)
        containerView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.distribution = .fill
        
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        
        icon.image = UIImage(systemName: "person.circle")
        icon.tintColor = .red
        title.text = "Devansh Rocks"
        title.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        hStack.addArrangedSubview(icon)
        hStack.addArrangedSubview(title)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            gradientView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gradientView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gradientView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            hStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            hStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),
            hStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            icon.heightAnchor.constraint(equalToConstant: 24),
            icon.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        containerView.clipsToBounds = true
    }
}

final class GradientView: UIView {
    private var startColor: UIColor = .red { didSet { updateColors() } }
    private var endColor:   UIColor = .green { didSet { updateColors() } }
    
    override class var layerClass: AnyClass { return CAGradientLayer.self }
    
    override public init(frame: CGRect = .zero) {
        super.init(frame: frame)
        config()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func config() {
        updateColors()
    }
    
    private func updateColors() {
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}
