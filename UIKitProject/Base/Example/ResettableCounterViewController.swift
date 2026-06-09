//
//  ResettableCounterViewController.swift
//  UIKitProject
//
//  Subclassing example: pins CounterView's generic to a narrower DataSource.
//  Protocol at file scope (rule 1). @objc in class body (rule 2).
//

import UIKit

// MARK: - DataSource

protocol ResettableCounterDataSource: CounterDataSource {
    func reset()
}

// MARK: - View

final class ResettableCounterView<VM: ResettableCounterDataSource>: CounterView<VM> {

    private let resetButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupResetButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapReset() {
        dataSource?.reset()
        updateLabel()
    }

    private func setupResetButton() {
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            resetButton.topAnchor.constraint(equalTo: centerYAnchor, constant: 60)
        ])
    }
}

// MARK: - ViewModel

final class ResettableCounterViewModel: ResettableCounterDataSource {
    private(set) var count: Int = 0
    func viewDidLoad() {}
    func increment() { count += 1 }
    func decrement() { count -= 1 }
    func reset() { count = 0 }
}

// MARK: - Usage

extension BaseViewController where ContentView == ResettableCounterView<ResettableCounterViewModel> {
    static func makeResettable() -> BaseViewController<ResettableCounterView<ResettableCounterViewModel>> {
        BaseViewController(contentView: ResettableCounterView(), viewModel: ResettableCounterViewModel())
    }
}
