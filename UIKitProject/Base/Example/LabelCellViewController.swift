//
//  LabelCellViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

//  Example: BaseTableViewCell with a generic LabelCellView<VM>.
//

import UIKit

// MARK: - DataSource (file scope — protocols can't be nested in generic classes)

protocol LabelCellDataSource: BaseViewModel {
    var title: String { get }
    var detail: String { get }
}

// MARK: - Cell View

// @objc members in class body — same rule as any generic UIView subclass.
final class LabelCellView<VM: LabelCellDataSource>: UIView {

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}

extension LabelCellView: BaseView {
    typealias ViewModel = VM

    func bind(to viewModel: VM) {
        titleLabel.text = viewModel.title
        detailLabel.text = viewModel.detail
    }
}

// MARK: - ViewModel

final class LabelCellViewModel: LabelCellDataSource {
    let title: String
    let detail: String

    init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

// MARK: - List screen DataSource

protocol LabelListDataSource: BaseViewModel {
    var items: [LabelCellViewModel] { get }
}

// MARK: - List screen View

// UITableViewDataSource is @objc — must be on the class definition line,
// not in an extension, for generic classes.
final class LabelListView<VM: LabelListDataSource>: UIView, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var viewModel: VM?

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            BaseTableViewCell<LabelCellView<LabelCellViewModel>>.self,
            forCellReuseIdentifier: "LabelCell"
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LabelCell",
            for: indexPath
        ) as! BaseTableViewCell<LabelCellView<LabelCellViewModel>>

        if let item = viewModel?.items[indexPath.row] {
            cell.configure(with: item)
        }
        return cell
    }
}

extension LabelListView: BaseView {
    typealias ViewModel = VM

    func bind(to viewModel: VM) {
        self.viewModel = viewModel
        tableView.reloadData()
    }
}

// MARK: - List ViewModel

final class LabelListViewModel: LabelListDataSource {
    let items: [LabelCellViewModel]

    init(items: [LabelCellViewModel]) {
        self.items = items
    }
}

// MARK: - Usage

extension BaseViewController where ContentView == LabelListView<LabelListViewModel> {
    static func makeLabelList() -> BaseViewController<LabelListView<LabelListViewModel>> {
        let items = (1...10).map { LabelCellViewModel(title: "Item \($0)", detail: "Detail for item \($0)") }
        return BaseViewController(
            contentView: LabelListView(),
            viewModel: LabelListViewModel(items: items)
        )
    }
}
