import UIKit
import XCTest
@testable import UIKitProject

@MainActor
final class WheelCollectionViewLayoutTests: XCTestCase {
    private final class DataSource: NSObject, UICollectionViewDataSource {
        let itemCount: Int

        init(itemCount: Int) {
            self.itemCount = itemCount
        }

        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            itemCount
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            )
        }
    }

    func testContentSizeExtendsAlongConfiguredAxis() {
        var verticalConfiguration = makeConfiguration()
        verticalConfiguration.scrollAxis = .vertical
        let vertical = makeCollectionView(configuration: verticalConfiguration)

        XCTAssertEqual(vertical.layout.collectionViewContentSize.width, 400, accuracy: 0.001)
        XCTAssertEqual(vertical.layout.collectionViewContentSize.height, 920, accuracy: 0.001)

        var horizontalConfiguration = makeConfiguration()
        horizontalConfiguration.scrollAxis = .horizontal
        let horizontal = makeCollectionView(configuration: horizontalConfiguration)

        XCTAssertEqual(horizontal.layout.collectionViewContentSize.width, 720, accuracy: 0.001)
        XCTAssertEqual(horizontal.layout.collectionViewContentSize.height, 600, accuracy: 0.001)
    }

    func testItemsFollowTheConfiguredWheelAxis() throws {
        var verticalConfiguration = makeConfiguration()
        verticalConfiguration.scrollAxis = .vertical
        let vertical = makeCollectionView(configuration: verticalConfiguration)
        try centerItem(at: 2, in: vertical.collectionView, using: vertical.layout)

        let verticalCenter = try XCTUnwrap(
            vertical.layout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))
        )
        let verticalNext = try XCTUnwrap(
            vertical.layout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
        )
        XCTAssertEqual(
            verticalCenter.center.x,
            vertical.collectionView.bounds.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            verticalCenter.center.y,
            vertical.collectionView.bounds.midY,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(verticalNext.center.x, verticalCenter.center.x)
        XCTAssertGreaterThan(verticalNext.center.y, verticalCenter.center.y)

        var horizontalConfiguration = makeConfiguration()
        horizontalConfiguration.scrollAxis = .horizontal
        let horizontal = makeCollectionView(configuration: horizontalConfiguration)
        try centerItem(at: 2, in: horizontal.collectionView, using: horizontal.layout)

        let horizontalCenter = try XCTUnwrap(
            horizontal.layout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))
        )
        let horizontalNext = try XCTUnwrap(
            horizontal.layout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
        )
        XCTAssertEqual(
            horizontalCenter.center.x,
            horizontal.collectionView.bounds.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            horizontalCenter.center.y,
            horizontal.collectionView.bounds.midY,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(horizontalNext.center.x, horizontalCenter.center.x)
        XCTAssertGreaterThan(horizontalNext.center.y, horizontalCenter.center.y)
    }

    func testMaximumCardAngleControlsRotation() throws {
        var configuration = makeConfiguration()
        configuration.anglePerItem = 0.5
        configuration.maximumVisibleAngle = 1
        configuration.maximumCardAngle = .pi / 3
        let testView = makeCollectionView(configuration: configuration)
        try centerItem(at: 2, in: testView.collectionView, using: testView.layout)

        let attributes = try XCTUnwrap(
            testView.layout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
        )
        let rotation = atan2(attributes.transform.b, attributes.transform.a)

        XCTAssertEqual(rotation, .pi / 6, accuracy: 0.001)
    }

    func testSmallerItemAngleCreatesMoreOverlap() throws {
        var overlappingConfiguration = makeConfiguration()
        overlappingConfiguration.anglePerItem = 0.2
        let overlapping = makeCollectionView(configuration: overlappingConfiguration)
        try centerItem(at: 2, in: overlapping.collectionView, using: overlapping.layout)
        let overlappingCenter = try XCTUnwrap(
            overlapping.layout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))
        )
        let overlappingNext = try XCTUnwrap(
            overlapping.layout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
        )

        var spacedConfiguration = makeConfiguration()
        spacedConfiguration.anglePerItem = 0.6
        let spaced = makeCollectionView(configuration: spacedConfiguration)
        try centerItem(at: 2, in: spaced.collectionView, using: spaced.layout)
        let spacedCenter = try XCTUnwrap(
            spaced.layout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))
        )
        let spacedNext = try XCTUnwrap(
            spaced.layout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
        )

        XCTAssertLessThan(
            distance(from: overlappingCenter.center, to: overlappingNext.center),
            distance(from: spacedCenter.center, to: spacedNext.center)
        )
    }

    private func makeConfiguration() -> WheelCollectionViewLayout.Configuration {
        var configuration = WheelCollectionViewLayout.Configuration()
        configuration.itemSize = CGSize(width: 120, height: 60)
        configuration.radius = 200
        configuration.anglePerItem = 0.4
        configuration.scrollStep = 80
        configuration.maximumVisibleAngle = 1.2
        configuration.minimumScale = 1
        configuration.minimumAlpha = 1
        configuration.curveSide = .trailing
        return configuration
    }

    private func makeCollectionView(
        configuration: WheelCollectionViewLayout.Configuration
    ) -> (
        layout: WheelCollectionViewLayout,
        collectionView: UICollectionView,
        dataSource: DataSource
    ) {
        let layout = WheelCollectionViewLayout(configuration: configuration)
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 400, height: 600),
            collectionViewLayout: layout
        )
        let dataSource = DataSource(itemCount: 5)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: "Cell"
        )
        collectionView.dataSource = dataSource
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        layout.prepare()

        return (layout, collectionView, dataSource)
    }

    private func centerItem(
        at item: Int,
        in collectionView: UICollectionView,
        using layout: WheelCollectionViewLayout
    ) throws {
        let indexPath = IndexPath(item: item, section: 0)
        let offset = try XCTUnwrap(layout.contentOffsetToCenterItem(at: indexPath))
        collectionView.setContentOffset(offset, animated: false)
        layout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(second.x - first.x, second.y - first.y)
    }
}
