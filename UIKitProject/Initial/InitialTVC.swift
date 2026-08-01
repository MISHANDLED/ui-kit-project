//
//  InitialTVC.swift
//  UIKitProject
//

import UIKit

// MARK: - DataSource (file scope — protocols can't be nested in generic classes)

protocol InitialCellDataSource: BaseViewModel {
    var title: String { get }
}

// MARK: - Cell View

final class InitialCellView<VM: InitialCellDataSource>: UIView {

    private let titleLabel = UILabel()

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])

        backgroundColor = .random
    }
}

extension InitialCellView: BaseView {
    typealias ViewModel = VM

    func bind(to viewModel: VM) {
        titleLabel.text = viewModel.title
    }
}
