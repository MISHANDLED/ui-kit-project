//
//  PagingViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 22/10/25.
//

import UIKit

protocol PagingViewDataSource: BaseViewModel {
    var numberOfPages: Int { get }
    func viewModel(for index: Int) -> PagingViewController.PageViewModel?
    func index(for id: String) -> Int?
}

final class PagingViewModel: PagingViewDataSource {
    private let viewModels: [PagingViewController.PageViewModel]
    
    init(viewModels: [PagingViewController.PageViewModel]) {
        self.viewModels = viewModels
    }
    
    var numberOfPages: Int { viewModels.count }
    
    func viewModel(for index: Int) -> PagingViewController.PageViewModel? {
        guard index >= 0 && index < viewModels.count else { return nil }
        return viewModels[index]
    }
    
    func index(for id: String) -> Int? {
        viewModels.firstIndex { $0.id == id }
    }
}

final class PagingView<VM: PagingViewDataSource>: UIView {
    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PagingView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}

final class PagingViewController: BaseViewController<PagingView<PagingViewModel>> {
    
    private let pagingVC: UIPageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )
    
    private var viewControllerCache: [String: UIViewController] = [:]
    private var currentIndex: Int = 0
    private let initialIndex: Int
    private let maxCacheSize = 10
    
    // Initialize with ViewModels
    init(viewModels: [PageViewModel], initialPage: Int = 0) {
        initialIndex = viewModels.isEmpty
            ? 0
            : min(max(initialPage, 0), viewModels.count - 1)
        super.init(contentView: PagingView(), viewModel: PagingViewModel(viewModels: viewModels))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        setupInitialPage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // Lazy creation: only create VC when needed
    private func viewController(for index: Int) -> UIViewController? {
        guard let pageViewModel = self.viewModel.viewModel(for: index) else { return nil }
        
        // Check cache first
        if let cachedVC = viewControllerCache[pageViewModel.id] {
            return cachedVC
        }
        
        // Evict old VCs if cache is too large
        if viewControllerCache.count >= maxCacheSize {
            evictDistantViewControllers(keepingIndex: index)
        }
        
        // Create new VC only if not in cache - THIS IS WHERE WE CREATE ON-DEMAND
        let vc = createColorViewController(for: pageViewModel)
        viewControllerCache[pageViewModel.id] = vc
        return vc
    }
    
    // Remove VCs that are far from current position
    private func evictDistantViewControllers(keepingIndex: Int) {
        let keepRange = 5 // Keep VCs within ±5 pages
        
        let idsToRemove = viewControllerCache.keys.filter { id in
            guard let index = viewModel.index(for: id) else {
                return true // Remove if not found
            }
            // Remove if outside the keep range
            return abs(index - keepingIndex) > keepRange
        }
        
        idsToRemove.forEach { id in
            viewControllerCache.removeValue(forKey: id)
        }
    }
    
    private func createColorViewController(for viewModel: PageViewModel) -> UIViewController {
        InternalClass(viewModel: viewModel)
    }
    
    // Helper to get index from view controller
    private func index(of viewController: UIViewController) -> Int? {
        for index in 0..<viewModel.numberOfPages {
            guard let pageViewModel = viewModel.viewModel(for: index) else { continue }
            if viewControllerCache[pageViewModel.id] === viewController {
                return index
            }
        }
        return nil
    }
}

// MARK: - DataSource
extension PagingViewController {
    protocol PageViewModel {
        var id: String { get }
        var title: String { get }
        var color: UIColor { get }
    }
}

// MARK: - private methods
private extension PagingViewController {
    
    func createViews() {
        pagingVC.dataSource = self
        pagingVC.delegate = self
        addChild(pagingVC)
        contentView.addSubview(pagingVC.view)
        pagingVC.didMove(toParent: self)
        
        pagingVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pagingVC.view.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            pagingVC.view.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            pagingVC.view.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            pagingVC.view.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupInitialPage() {
        guard
            viewModel.numberOfPages > 0,
            let firstVC = viewController(for: initialIndex)
        else {
            return
        }
        
        pagingVC.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false,
            completion: nil
        )
        currentIndex = initialIndex
    }
}

// MARK: - Paging View
extension PagingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = index(of: viewController) else { return nil }
        return self.viewController(for: currentIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = index(of: viewController) else { return nil }
        return self.viewController(for: currentIndex + 1)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return viewModel.numberOfPages
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first,
           let index = index(of: currentVC) {
            currentIndex = index
            
            evictDistantViewControllers(keepingIndex: index)
        }
    }
    
    func clearCache() {
        viewControllerCache.removeAll()
    }
    
    func clearCacheExceptCurrent() {
        guard let currentVC = pagingVC.viewControllers?.first,
              let currentIdx = index(of: currentVC) else {
            return
        }
        guard let currentViewModel = viewModel.viewModel(for: currentIdx) else { return }
        let currentId = currentViewModel.id
        
        viewControllerCache = viewControllerCache.filter { $0.key == currentId }
    }
}

// MARK: - Internal Dummy Class
extension PagingViewController {
    final class InternalClass: UIViewController {
        private let viewModel: PageViewModel
        private let titleLabel: UILabel = UILabel()
        
        init(viewModel: PageViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
            print("\(#function) called for page ID:\(viewModel.id)")
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            print("\(#function) called for page ID:\(viewModel.id)")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = viewModel.color
            
            titleLabel.text = "\(viewModel.title)\nID: \(viewModel.id)"
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = .center
            titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
            titleLabel.textColor = .white
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }
}

// MARK: - Sample View Model
extension PagingViewController {
    private struct SamplePageViewModel: PagingViewController.PageViewModel {
        let id: String
        let title: String
        let color: UIColor
    }
    
    static func createSample(initialPage: Int? = nil) -> PagingViewController {
        let viewModels: [PageViewModel] = (0..<100).map { index in
            SamplePageViewModel(
                id: "page_\(index + 1)",
                title: "Page \(index + 1)",
                color: [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple][index % 5]
            )
        }
        return PagingViewController(
            viewModels: viewModels,
            initialPage: initialPage ?? 0
        )
    }
}
