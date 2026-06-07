//
//  ViewControllerA.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import UIKit

// Search Bar Animation Screen 1
final class ViewControllerA: UIViewController {
    private let searchBar: UISearchBar = UISearchBar()
    private let button: UIButton = UIButton(type: .system)
    private let transitionDelegate = SearchTransitionDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
    }
}

private extension ViewControllerA {
    func createViews() {
        view.backgroundColor = .white
        view.addSubview(searchBar)
        searchBar.tag = 1
        view.addSubview(button)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        setupButton()
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
    }
    
    func setupButton() {
        button.setTitle("Tap me for transition", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }
    
    @objc
    func didTapView() {
        let vcB = ViewControllerB()
        vcB.searchTransitionDelegate = transitionDelegate
        vcB.transitioningDelegate = transitionDelegate
        vcB.modalPresentationStyle = .overFullScreen
        present(vcB, animated: true)
    }
}

extension ViewControllerA: TransitionViewProvider {
    var transitionViews: [UIView] { [searchBar] }
}
