//
//  InitialViewModelTests.swift
//  UIKitProjectTests
//
//  Created by Devansh Mohata on 02/08/26.
//

import UIKit
import XCTest
@testable import UIKitProject

final class InitialViewModelTests: XCTestCase {
    @MainActor
    func testSelectionsEmitSemanticRoutes() {
        let expectedRoutes: [AppRoute] = [
            .panGesture,
            .page(index: nil),
            .propertyAnimator,
            .crashSimulator,
            .miniPlayer,
            .htmlViewer,
            .searchTransition
        ]
        let viewModel = InitialViewModel()
        var receivedRoutes: [AppRoute] = []
        viewModel.onNavigate = { route in
            receivedRoutes.append(route)
        }

        for row in expectedRoutes.indices {
            viewModel.didSelect(at: IndexPath(row: row, section: 0))
        }

        XCTAssertEqual(receivedRoutes, expectedRoutes)
    }
}
