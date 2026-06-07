//
//  ViewControllerB.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import UIKit

final class ViewControllerB: UIViewController {
    
    weak var searchTransitionDelegate: SearchTransitionDelegate?
    
    let blurView: UIVisualEffectView
    let containerView: UIView = UIView()
    private let searchBar: UISearchBar = UISearchBar()
    
    init() {
        self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        addPanGesture()
    }
}

// MARK: - Setup

private extension ViewControllerB {
    func createViews() {
        view.addSubview(blurView)
        view.addSubview(containerView)
        containerView.addSubview(searchBar)
        searchBar.tag = 1
        
        [blurView, containerView, searchBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            searchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            searchBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
    }
    
    func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(pan)
    }
}

// MARK: - Pan Dismiss

private extension ViewControllerB {
    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let percent = max(0, min(1, translation.y / view.bounds.height))
        
        switch gesture.state {
        case .began:
            searchTransitionDelegate?.beginInteraction()
            dismiss(animated: true)
            
        case .changed:
            searchTransitionDelegate?.updateInteraction(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view)
            if percent > 0.4 || velocity.y > 800 {
                searchTransitionDelegate?.finishInteraction()
            } else {
                searchTransitionDelegate?.cancelInteraction()
            }
            
        default:
            break
        }
    }
}

extension ViewControllerB: TransitionViewProvider {
    var transitionViews: [UIView] { [searchBar] }
}
