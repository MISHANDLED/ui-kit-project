//
//  InitialController.swift
//  UIKitProject
//

import UIKit

// MARK: - Screen DataSource (file scope — rule 1)

protocol InitialViewDataSource: BaseViewModel {
    var onNavigate: ((AppRoute) -> Void)? { get set }
    var numberOfSections: Int { get }
    func numberOfRows(in section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> InitialCellViewModel
    func didSelect(at indexPath: IndexPath)
}

// MARK: - Screen View

// UITableViewDataSource + UITableViewDelegate are @objc — must be on the
// class definition line, not in extensions, for generic classes.
final class InitialView<VM: InitialViewDataSource>: UIView, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let floatingView = FloatingView()
    private var viewModel: VM?

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        floatingView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
        addSubview(floatingView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            floatingView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            floatingView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(BaseTableViewCell<InitialCellView<InitialCellViewModel>>.self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel?.numberOfSections ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.numberOfRows(in: section) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeue(BaseTableViewCell<InitialCellView<InitialCellViewModel>>.self),
            let cellVM = viewModel?.cellViewModel(for: indexPath)
        else { return UITableViewCell() }
        cell.configure(with: cellVM)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel?.didSelect(at: indexPath)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        floatingView.collapse()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { floatingView.expand() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        floatingView.expand()
    }
}

extension InitialView: BaseView {
    typealias ViewModel = VM

    func bind(to viewModel: VM) {
        self.viewModel = viewModel
        tableView.reloadData()
    }
}

// MARK: - View Controller

// Subclasses BaseViewController to add nav-bar show/hide lifecycle.
// Generic pin: BaseViewController<InitialView<InitialViewModel>>.
final class InitialViewController: BaseViewController<InitialView<InitialViewModel>> {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
