//
//  ViewControllerA.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import UIKit

protocol SearchSourceViewDataSource: BaseViewModel {
    var onPresentRequested: (() -> Void)? { get set }
    func requestPresentation()
}

final class SearchSourceViewModel: SearchSourceViewDataSource {
    var onPresentRequested: (() -> Void)?
    
    func requestPresentation() {
        onPresentRequested?()
    }
}

// Search Bar Animation Screen 1
final class SearchSourceView<VM: SearchSourceViewDataSource>: UIView {
    private let searchBar: UISearchBar = UISearchBar()
    private let button: UIButton = UIButton(type: .system)
    private var viewModel: VM?
    
    var transitionViews: [UIView] { [searchBar] }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func didTapView() {
        viewModel?.requestPresentation()
    }
}

extension SearchSourceView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {
        self.viewModel = viewModel
    }
}

private extension SearchSourceView {
    func createViews() {
        backgroundColor = .white
        addSubview(searchBar)
        searchBar.tag = 1
        addSubview(button)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
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
    
}

final class ViewControllerA: BaseViewController<SearchSourceView<SearchSourceViewModel>> {
    init(onPresentRequested: @escaping () -> Void) {
        let viewModel = SearchSourceViewModel()
        super.init(contentView: SearchSourceView(), viewModel: viewModel)
        viewModel.onPresentRequested = onPresentRequested
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ViewControllerA: TransitionViewProvider {
    var transitionViews: [UIView] { contentView.transitionViews }
}
