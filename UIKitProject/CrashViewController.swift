//
//  CrashViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/11/25.
//

import UIKit

protocol CrashViewDataSource: BaseViewModel {
    var onPopRequested: (() -> Void)? { get set }
    var onSelfAccessRequested: (() -> AnyObject?)? { get set }
}

final class CrashViewModel: CrashViewDataSource {
    var onPopRequested: (() -> Void)?
    var onSelfAccessRequested: (() -> AnyObject?)?
    
    func viewDidLoad() {
        
        // CRASH: [unowned self] + async work after screen dismissal
        // Self is captured as unowned at Task creation, but deallocated when popped.
        // Accessing unowned reference after deallocation = crash
        Task { [unowned self] in
            print("In Task")
            onPopRequested?()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
            print("Accessing self: \(String(describing: onSelfAccessRequested?()))")  // Crash here - owner can be deallocated
        }
        
        // SAFE but MEMORY LEAK: [weak self] with strong reference via guard let
        // Guard let creates strong reference to self, keeping VC in memory until Task completes.
        // VC is popped but not deallocated - remains in memory for 1 second unnecessarily
//        Task { [weak self] in
//            guard let self else { return }
//            print("In Task")
//            navigationController?.popViewController(animated: true)
//            try? await Task.sleep(nanoseconds: 1_000_000_000)
//            print("Accessing self: \(self)")
//        }
    }
}

final class CrashView<VM: CrashViewDataSource>: UIView {
    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .random
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CrashView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}

@MainActor
func makeCrashViewController(onPopRequested: @escaping () -> Void) -> UIViewController {
    let viewModel = CrashViewModel()
    let viewController = BaseViewController(contentView: CrashView(), viewModel: viewModel)
    
    viewModel.onPopRequested = onPopRequested
    viewModel.onSelfAccessRequested = { [unowned viewController] in viewController }
    
    return viewController
}
