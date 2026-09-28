//
//  UIPropertyAnimatorVC.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 23/10/25.
//

import UIKit

protocol UIPropertyAnimatorViewDataSource: BaseViewModel {}

final class UIPropertyAnimatorViewModel: UIPropertyAnimatorViewDataSource {}

final class UIPropertyAnimatorView<VM: UIPropertyAnimatorViewDataSource>: UIView {
    private let centerImage: UIImageView = UIImageView(image: .farmHouse)
    private let slider: UISlider = UISlider()
    
    private let propertyAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear)
    private lazy var centerYConstraint: NSLayoutConstraint = centerImage.centerYAnchor.constraint(equalTo: centerYAnchor)
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
        addAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func valueDidChanged(_ slider: UISlider) {
        propertyAnimator.fractionComplete = CGFloat(slider.value)
    }
}

extension UIPropertyAnimatorView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}

private extension UIPropertyAnimatorView {
    func createViews() {
        backgroundColor = .red.withAlphaComponent(0.5)
        
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(centerImage)
        centerImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            slider.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            slider.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            centerYConstraint,
            centerImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            centerImage.heightAnchor.constraint(equalTo: centerImage.widthAnchor, multiplier: 1)
        ])
        
        slider.addTarget(self, action: #selector(valueDidChanged), for: .valueChanged)
    }
    
    func addAnimation() {
        centerImage.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        centerImage.alpha = 0
        
        propertyAnimator.addAnimations { [weak self] in
            self?.centerImage.transform = .identity
            self?.centerImage.alpha = 1
        }
        
        propertyAnimator.addAnimations({ [weak self] in
            self?.centerYConstraint.constant = -100
            self?.layoutIfNeeded()
        }, delayFactor: 0.5)
    }
    
}
