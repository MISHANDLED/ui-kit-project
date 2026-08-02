//
//  AppCoordinator.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

import UIKit

@MainActor
final class AppCoordinator {
    let navigationController: UINavigationController

    private let screenFactory: any AppScreenBuilding
    private let deepLinkHandler: any DeepLinkHandling

    private var homeViewController: UIViewController?
    private var pendingNavigation: (route: AppRoute, source: NavigationSource)?
    private var searchTransitionDelegate: SearchTransitionDelegate?
    private var recordingOverlayController: RecordingOverlayController?
    private(set) var isStarted = false

    init(
        navigationController: UINavigationController,
        screenFactory: any AppScreenBuilding,
        deepLinkHandler: any DeepLinkHandling
    ) {
        self.navigationController = navigationController
        self.screenFactory = screenFactory
        self.deepLinkHandler = deepLinkHandler
    }

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        navigationController.setViewControllers(
            [makeHomeViewController()],
            animated: false
        )

        if let pendingNavigation {
            self.pendingNavigation = nil
            navigate(to: pendingNavigation.route, source: pendingNavigation.source)
        }
    }

    func installRecordingOverlay(in windowScene: UIWindowScene) {
        guard recordingOverlayController == nil else {
            return
        }

        let controller = RecordingOverlayController()
        controller.install(in: windowScene)
        recordingOverlayController = controller
    }

    func navigate(to route: AppRoute, source: NavigationSource) {
        guard isStarted else {
            pendingNavigation = (route, source)
            return
        }

        switch route {
        case .home:
            showHome(source: source)
        case .searchDestination:
            presentSearchDestination()
        default:
            showPushDestination(route, source: source)
        }
    }

    func handle(_ action: AppNavigationAction) {
        switch action {
        case .navigate(let route):
            navigate(to: route, source: .user)

        case .goBack:
            navigationController.popViewController(animated: true)

        case .searchDismissal(let interaction):
            handleSearchDismissal(interaction)
        }
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        guard let route = deepLinkHandler.route(from: url) else {
            return false
        }

        navigate(to: route, source: .deepLink)
        return true
    }

    private func showHome(source: NavigationSource) {
        performAfterDismissingPresented { [weak self] in
            guard let self else {
                return
            }

            switch source {
            case .user:
                navigationController.popToRootViewController(animated: true)
            case .deepLink:
                navigationController.setViewControllers(
                    [makeHomeViewController()],
                    animated: false
                )
            }
        }
    }

    private func showPushDestination(_ route: AppRoute, source: NavigationSource) {
        performAfterDismissingPresented { [weak self] in
            guard let self else {
                return
            }

            let destination = makeViewController(for: route)

            switch source {
            case .user:
                navigationController.pushViewController(destination, animated: true)
            case .deepLink:
                navigationController.setViewControllers(
                    [makeHomeViewController(), destination],
                    animated: false
                )
            }
        }
    }

    private func presentSearchDestination() {
        guard navigationController.presentedViewController == nil else {
            return
        }

        let transitionDelegate = SearchTransitionDelegate()
        searchTransitionDelegate = transitionDelegate

        let destination = makeViewController(for: .searchDestination)
        destination.transitioningDelegate = transitionDelegate
        destination.modalPresentationStyle = .overFullScreen
        navigationController.present(destination, animated: true)
    }

    private func handleSearchDismissal(_ interaction: SearchDismissalInteraction) {
        switch interaction {
        case .began:
            guard let presentedViewController = navigationController.presentedViewController else {
                return
            }
            searchTransitionDelegate?.beginInteraction()
            presentedViewController.dismiss(animated: true)

        case .changed(let progress):
            searchTransitionDelegate?.updateInteraction(progress)

        case .finished:
            searchTransitionDelegate?.finishInteraction()

        case .cancelled:
            searchTransitionDelegate?.cancelInteraction()
        }
    }

    private func makeHomeViewController() -> UIViewController {
        if let homeViewController {
            return homeViewController
        }

        let viewController = makeViewController(for: .home)
        homeViewController = viewController
        return viewController
    }

    private func makeViewController(for route: AppRoute) -> UIViewController {
        screenFactory.makeViewController(for: route) { [weak self] action in
            self?.handle(action)
        }
    }

    private func performAfterDismissingPresented(_ action: @escaping () -> Void) {
        guard navigationController.presentedViewController != nil else {
            action()
            return
        }

        navigationController.dismiss(animated: false, completion: action)
    }
}
