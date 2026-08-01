//
//  ViewControllerB.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import UIKit

protocol SearchDestinationViewDataSource: BaseViewModel {
    var onDismissBegan: (() -> Void)? { get set }
    var onDismissChanged: ((CGFloat) -> Void)? { get set }
    var onDismissFinished: (() -> Void)? { get set }
    var onDismissCancelled: (() -> Void)? { get set }
}

final class SearchDestinationViewModel: SearchDestinationViewDataSource {
    var onDismissBegan: (() -> Void)?
    var onDismissChanged: ((CGFloat) -> Void)?
    var onDismissFinished: (() -> Void)?
    var onDismissCancelled: (() -> Void)?
}

final class SearchDestinationView<VM: SearchDestinationViewDataSource>: UIView {
    
    let blurView: UIVisualEffectView
    let containerView: UIView = UIView()
    private let searchBar: UISearchBar = UISearchBar()
    private var viewModel: VM?
    
    var transitionViews: [UIView] { [searchBar] }
    
    required override init(frame: CGRect) {
        self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        super.init(frame: frame)
        createViews()
        addPanGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let percent = max(0, min(1, translation.y / bounds.height))
        
        switch gesture.state {
        case .began:
            viewModel?.onDismissBegan?()
            
        case .changed:
            viewModel?.onDismissChanged?(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: self)
            if percent > 0.4 || velocity.y > 800 {
                viewModel?.onDismissFinished?()
            } else {
                viewModel?.onDismissCancelled?()
            }
            
        default:
            break
        }
    }
}

extension SearchDestinationView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {
        self.viewModel = viewModel
    }
}

// MARK: - Setup

private extension SearchDestinationView {
    func createViews() {
        addSubview(blurView)
        addSubview(containerView)
        containerView.addSubview(searchBar)
        searchBar.tag = 1
        
        [blurView, containerView, searchBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
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

final class ViewControllerB: BaseViewController<SearchDestinationView<SearchDestinationViewModel>> {
    init(onDismissInteraction: @escaping (SearchDismissalInteraction) -> Void) {
        let viewModel = SearchDestinationViewModel()
        super.init(contentView: SearchDestinationView(), viewModel: viewModel)
        viewModel.onDismissBegan = {
            onDismissInteraction(.began)
        }
        viewModel.onDismissChanged = { progress in
            onDismissInteraction(.changed(progress: progress))
        }
        viewModel.onDismissFinished = {
            onDismissInteraction(.finished)
        }
        viewModel.onDismissCancelled = {
            onDismissInteraction(.cancelled)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ViewControllerB: TransitionViewProvider {
    var transitionViews: [UIView] { contentView.transitionViews }
}
