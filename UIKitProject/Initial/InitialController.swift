//
//  InitialController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 22/10/25.
//

import UIKit

final class InitialController: UIViewController {
    private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let floatingView: FloatingView = FloatingView()
    private let dataSource: DataSource
    
    init(dataSource: DataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

private extension InitialController {
    func createViews() {
        view.addSubview(tableView)
        view.addSubview(floatingView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        floatingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            floatingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            floatingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        setupTableView()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(InitialTVC.self)
    }
}

extension InitialController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        dataSource.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = dataSource.dataSource(for: indexPath)
        
        guard let cell = tableView.dequeue(InitialTVC.self) else { return UITableViewCell() }
        cell.setData(cellData.description)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let vc = dataSource.dataSource(for: indexPath).builder()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        floatingView.collapse()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            floatingView.expand()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        floatingView.expand()
    }
}

extension InitialController {
    enum CellType: CustomStringConvertible {
        case panGesture
        case pageViewController
        case properyAnimator
        case crashSimulator
        case miniPlayer
        case htmlViewer
        case datePicker
        case transition
        
        var description: String {
            switch self {
            case .panGesture:
                "Pan Gesture"
            case .pageViewController:
                "Page View Controller"
            case .properyAnimator:
                "Property Animator"
            case .crashSimulator:
                "Simulate Crash"
            case .miniPlayer:
                "Mini Player"
            case .htmlViewer:
                "HTML Viewer"
            case .datePicker:
                "Date Picker"
            case .transition:
                "Search Transition"
            }
        }
        
        var builder: () -> UIViewController {
            switch self {
            case .panGesture:
                { PanViewController() }
            case .pageViewController:
                { PagingViewController.createSample() }
            case .properyAnimator:
                { UIProperyAnimatorVC() }
            case .crashSimulator:
                { CrashViewController() }
            case .miniPlayer:
                { AVPlayerViewController() }
            case .htmlViewer:
                { PDFRenderer() }
            case .datePicker:
                { DatePickerVC() }
            case .transition:
                { ViewControllerA() }
            }
        }
    }
    
    protocol DataSource {
        var numberOfSections: Int { get }
        
        func numberOfRows(in section: Int) -> Int
        func dataSource(for tableView: IndexPath) -> CellType
    }
}
