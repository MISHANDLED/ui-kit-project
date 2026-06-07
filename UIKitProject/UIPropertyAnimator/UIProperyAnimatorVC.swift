//
//  UIProperyAnimatorVC.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 23/10/25.
//

import UIKit

final class UIProperyAnimatorVC: UIViewController {
    private let centerImage: UIImageView = UIImageView(image: .farmHouse)
    private let slider: UISlider = UISlider()
    
    private let propertyAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear)
    private lazy var centerYConstraint: NSLayoutConstraint = centerImage.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        addAnimation()
    }
    
    deinit {
        if propertyAnimator.state != .inactive {
            propertyAnimator.stopAnimation(false)
            propertyAnimator.finishAnimation(at: .current)
        }
    }
}

private extension UIProperyAnimatorVC {
    func createViews() {
        view.backgroundColor = .red.withAlphaComponent(0.5)
        
        view.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(centerImage)
        centerImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            slider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            slider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            centerYConstraint,
            centerImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
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
            self?.view.layoutIfNeeded()
        }, delayFactor: 0.5)
    }
    
    @objc
    func valueDidChanged(_ slider: UISlider) {
        propertyAnimator.fractionComplete = CGFloat(slider.value)
    }
}
