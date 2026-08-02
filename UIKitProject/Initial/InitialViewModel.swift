//
//  InitialViewModel.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import Foundation

// MARK: - Destination

enum InitialCellType: CustomStringConvertible {
    case panGesture
    case pageViewController
    case properyAnimator
    case crashSimulator
    case miniPlayer
    case htmlViewer
    case wheelCollectionLayout
    case transition

    var description: String {
        switch self {
        case .panGesture: "Pan Gesture"
        case .pageViewController: "Page View Controller"
        case .properyAnimator: "Property Animator"
        case .crashSimulator: "Simulate Crash"
        case .miniPlayer: "Mini Player"
        case .htmlViewer: "HTML Viewer"
        case .wheelCollectionLayout: "Wheel Collection Layout"
        case .transition: "Search Transition"
        }
    }

    var route: AppRoute {
        switch self {
        case .panGesture: .panGesture
        case .pageViewController: .page(index: nil)
        case .properyAnimator: .propertyAnimator
        case .crashSimulator: .crashSimulator
        case .miniPlayer: .miniPlayer
        case .htmlViewer: .htmlViewer
        case .wheelCollectionLayout: .wheelCollectionLayout
        case .transition: .searchTransition
        }
    }
}

// MARK: - Cell ViewModel

final class InitialCellViewModel: InitialCellDataSource {
    let title: String
    let route: AppRoute

    init(type: InitialCellType) {
        self.title = type.description
        self.route = type.route
    }
}

// MARK: - Screen ViewModel

final class InitialViewModel: InitialViewDataSource {
    var onNavigate: ((AppRoute) -> Void)?

    private let cellViewModels: [InitialCellViewModel] = [
        .panGesture,
        .pageViewController,
        .properyAnimator,
        .crashSimulator,
        .miniPlayer,
        .htmlViewer,
        .wheelCollectionLayout,
        .transition
    ].map { InitialCellViewModel(type: $0) }

    var numberOfSections: Int { 1 }

    func numberOfRows(in section: Int) -> Int {
        cellViewModels.count
    }

    func cellViewModel(for indexPath: IndexPath) -> InitialCellViewModel {
        cellViewModels[indexPath.row]
    }

    func didSelect(at indexPath: IndexPath) {
        onNavigate?(cellViewModels[indexPath.row].route)
    }
}
