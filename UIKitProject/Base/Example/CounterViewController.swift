//
//  CounterViewController.swift
//  UIKitProject
//
//  Example: protocol at file scope, CounterView generic over VM — no existentials.
//

import UIKit

// MARK: - DataSource (file scope — protocols can't be nested in generic classes)

protocol CounterDataSource: BaseViewModel {
    var count: Int { get }
    func increment()
    func decrement()
}

// MARK: - View

// @objc selector methods must live in the class body, not extensions — Swift
// disallows @objc in extensions of generic classes.
class CounterView<VM: CounterDataSource>: UIView {

    private let label = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let decrementButton = UIButton(type: .system)

    var dataSource: VM?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapIncrement() {
        dataSource?.increment()
        updateLabel()
    }

    @objc private func didTapDecrement() {
        dataSource?.decrement()
        updateLabel()
    }

    func updateLabel() {
        label.text = "\(dataSource?.count ?? 0)"
    }

    private func setupViews() {
        backgroundColor = .systemBackground

        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        incrementButton.setTitle("+", for: .normal)
        incrementButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .medium)
        incrementButton.addTarget(self, action: #selector(didTapIncrement), for: .touchUpInside)

        decrementButton.setTitle("-", for: .normal)
        decrementButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .medium)
        decrementButton.addTarget(self, action: #selector(didTapDecrement), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [decrementButton, label, incrementButton])
        stack.axis = .horizontal
        stack.spacing = 32
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension CounterView: BaseView {
    typealias ViewModel = VM

    func bind(to viewModel: VM) {
        self.dataSource = viewModel
        updateLabel()
    }
}

// MARK: - ViewModels

final class BasicCounterViewModel: CounterDataSource {
    private(set) var count: Int = 0
    func viewDidLoad() {}
    func increment() { count += 1 }
    func decrement() { count -= 1 }
}

final class BoundedCounterViewModel: CounterDataSource {
    private let range: ClosedRange<Int>
    private(set) var count: Int

    init(initial: Int = 0, range: ClosedRange<Int> = 0...10) {
        self.range = range
        self.count = initial
    }

    func viewDidLoad() {}
    func increment() { count = min(count + 1, range.upperBound) }
    func decrement() { count = max(count - 1, range.lowerBound) }
}

// MARK: - Usage

extension BaseViewController where ContentView == CounterView<BasicCounterViewModel> {
    static func makeBasic() -> BaseViewController<CounterView<BasicCounterViewModel>> {
        BaseViewController(contentView: CounterView(), viewModel: BasicCounterViewModel())
    }
}

extension BaseViewController where ContentView == CounterView<BoundedCounterViewModel> {
    static func makeBounded(range: ClosedRange<Int> = 0...10) -> BaseViewController<CounterView<BoundedCounterViewModel>> {
        BaseViewController(contentView: CounterView(), viewModel: BoundedCounterViewModel(range: range))
    }
}
