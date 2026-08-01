//
//  AppCoordinatorTests.swift
//  UIKitProjectTests
//

import UIKit
import XCTest
@testable import UIKitProject

final class AppCoordinatorTests: XCTestCase {
    @MainActor
    func testStartInstallsHomeOnce() {
        let factory = ScreenFactorySpy()
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            screenFactory: factory,
            deepLinkHandler: DeepLinkHandlerStub(route: nil)
        )

        coordinator.start()
        coordinator.start()

        XCTAssertEqual(routes(in: navigationController), [.home])
        XCTAssertEqual(factory.createdRoutes, [.home])
    }

    @MainActor
    func testDeepLinkBeforeStartIsAppliedAfterStart() throws {
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            screenFactory: ScreenFactorySpy(),
            deepLinkHandler: DeepLinkHandlerStub(route: .datePicker)
        )
        let url = try XCTUnwrap(URL(string: "uikitproject://open/date-picker"))

        XCTAssertTrue(coordinator.handle(url: url))
        XCTAssertTrue(navigationController.viewControllers.isEmpty)

        coordinator.start()

        XCTAssertEqual(routes(in: navigationController), [.home, .datePicker])
    }

    @MainActor
    func testDeepLinkReplacesExistingPushStack() throws {
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            screenFactory: ScreenFactorySpy(),
            deepLinkHandler: DeepLinkHandlerStub(route: .miniPlayer)
        )
        coordinator.start()
        coordinator.navigate(to: .panGesture, source: .user)
        let url = try XCTUnwrap(URL(string: "uikitproject://open/mini-player"))

        XCTAssertTrue(coordinator.handle(url: url))

        XCTAssertEqual(routes(in: navigationController), [.home, .miniPlayer])
    }

    @MainActor
    func testUnsupportedDeepLinkDoesNotChangeStack() throws {
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            screenFactory: ScreenFactorySpy(),
            deepLinkHandler: DeepLinkHandlerStub(route: nil)
        )
        coordinator.start()
        let url = try XCTUnwrap(URL(string: "uikitproject://open/unknown"))

        XCTAssertFalse(coordinator.handle(url: url))
        XCTAssertEqual(routes(in: navigationController), [.home])
    }

    @MainActor
    private func routes(in navigationController: UINavigationController) -> [AppRoute] {
        navigationController.viewControllers.compactMap {
            ($0 as? RouteViewController)?.route
        }
    }
}

private struct DeepLinkHandlerStub: DeepLinkHandling {
    let route: AppRoute?

    func route(from url: URL) -> AppRoute? {
        route
    }
}

@MainActor
private final class ScreenFactorySpy: AppScreenBuilding {
    private(set) var createdRoutes: [AppRoute] = []

    func makeViewController(
        for route: AppRoute,
        onAction: @escaping (AppNavigationAction) -> Void
    ) -> UIViewController {
        createdRoutes.append(route)
        return RouteViewController(route: route)
    }
}

@MainActor
private final class RouteViewController: UIViewController {
    let route: AppRoute

    init(route: AppRoute) {
        self.route = route
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
