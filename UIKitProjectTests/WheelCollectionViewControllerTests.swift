import UIKit
import XCTest
@testable import UIKitProject

@MainActor
final class WheelCollectionViewControllerTests: XCTestCase {
    func testSettingsPanelStartsCollapsedAndTogglesVisibility() throws {
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        let viewController = WheelCollectionViewController()
        viewController.loadViewIfNeeded()

        let disclosureButton: UIButton = try XCTUnwrap(
            descendant(
                withAccessibilityIdentifier: "wheel.settings.disclosure",
                in: viewController.view
            )
        )
        let settingsContent: UIStackView = try XCTUnwrap(
            descendant(
                withAccessibilityIdentifier: "wheel.settings.content",
                in: viewController.view
            )
        )

        XCTAssertTrue(settingsContent.isHidden)
        XCTAssertTrue(disclosureButton.accessibilityValue?.contains("Collapsed") == true)

        disclosureButton.sendActions(for: .touchUpInside)
        XCTAssertFalse(settingsContent.isHidden)
        XCTAssertTrue(disclosureButton.accessibilityValue?.contains("Expanded") == true)

        disclosureButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(settingsContent.isHidden)
        XCTAssertTrue(disclosureButton.accessibilityValue?.contains("Collapsed") == true)
    }

    private func descendant<View: UIView>(
        withAccessibilityIdentifier identifier: String,
        in view: UIView
    ) -> View? {
        if view.accessibilityIdentifier == identifier, let match = view as? View {
            return match
        }

        for subview in view.subviews {
            if let match: View = descendant(
                withAccessibilityIdentifier: identifier,
                in: subview
            ) {
                return match
            }
        }

        return nil
    }
}
