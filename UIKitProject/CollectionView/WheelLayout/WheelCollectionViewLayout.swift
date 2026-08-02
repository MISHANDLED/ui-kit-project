import UIKit

final class WheelCollectionViewLayout: UICollectionViewLayout {
    enum ScrollAxis: Equatable {
        case vertical
        case horizontal
    }

    enum CurveSide: Equatable {
        case leading
        case trailing
    }

    struct Configuration: Equatable {
        var itemSize = CGSize(width: 236, height: 72)
        var radius: CGFloat = 280
        var anglePerItem: CGFloat = 0.31
        var scrollStep: CGFloat = 86
        var maximumVisibleAngle: CGFloat = 1.25
        var minimumScale: CGFloat = 0.72
        var minimumAlpha: CGFloat = 0.18
        var maximumCardAngle: CGFloat = 42 * .pi / 180
        var scrollAxis: ScrollAxis = .vertical
        var curveSide: CurveSide = .trailing
    }

    var configuration: Configuration {
        didSet {
            guard configuration != oldValue else {
                return
            }
            invalidateLayout()
        }
    }

    private var itemIndexPaths: [IndexPath] = []
    private var flattenedIndexByIndexPath: [IndexPath: Int] = [:]
    private var cachedSectionItemCounts: [Int] = []

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        super.init()
    }

    required init?(coder: NSCoder) {
        configuration = Configuration()
        super.init(coder: coder)
    }

    override func prepare() {
        super.prepare()
        rebuildIndexPathCacheIfNeeded()
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView else {
            return .zero
        }

        let insets = collectionView.adjustedContentInset
        let viewportWidth = max(collectionView.bounds.width - insets.left - insets.right, 1)
        let viewportHeight = max(collectionView.bounds.height - insets.top - insets.bottom, 1)
        let scrollingDistance = CGFloat(max(itemIndexPaths.count - 1, 0)) * resolvedScrollStep

        switch configuration.scrollAxis {
        case .vertical:
            return CGSize(
                width: viewportWidth,
                height: viewportHeight + scrollingDistance
            )
        case .horizontal:
            return CGSize(
                width: viewportWidth + scrollingDistance,
                height: viewportHeight
            )
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !itemIndexPaths.isEmpty else {
            return []
        }

        let progress = currentScrollProgress
        let itemRange = Int(ceil(resolvedMaximumVisibleAngle / resolvedAnglePerItem)) + 1
        let lowerBound = max(Int(floor(progress)) - itemRange, 0)
        let upperBound = min(Int(ceil(progress)) + itemRange, itemIndexPaths.count - 1)
        let expandedRect = rect.insetBy(
            dx: -resolvedItemSize.width,
            dy: -resolvedItemSize.height
        )

        guard lowerBound <= upperBound else {
            return []
        }

        return (lowerBound...upperBound).compactMap { flattenedIndex in
            let indexPath = itemIndexPaths[flattenedIndex]
            guard
                let attributes = makeLayoutAttributes(
                    for: indexPath,
                    flattenedIndex: flattenedIndex
                ),
                !attributes.isHidden,
                attributes.frame.intersects(expandedRect)
            else {
                return nil
            }
            return attributes
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let flattenedIndex = flattenedIndexByIndexPath[indexPath] else {
            return nil
        }
        return makeLayoutAttributes(for: indexPath, flattenedIndex: flattenedIndex)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let collectionView, !itemIndexPaths.isEmpty else {
            return proposedContentOffset
        }

        let proposedProgress = primaryScrollOffset(for: proposedContentOffset) / resolvedScrollStep
        let currentProgress = primaryScrollOffset(for: collectionView.contentOffset)
            / resolvedScrollStep
        let primaryVelocity = configuration.scrollAxis == .vertical ? velocity.y : velocity.x
        var targetIndex = proposedProgress.rounded()

        // A deliberate flick always advances at least one item, even when UIKit's
        // projected offset remains inside the currently centered item.
        if abs(primaryVelocity) > 0.3, targetIndex == currentProgress.rounded() {
            targetIndex += primaryVelocity > 0 ? 1 : -1
        }

        targetIndex = min(max(targetIndex, 0), CGFloat(itemIndexPaths.count - 1))

        let targetOffset = targetIndex * resolvedScrollStep
        let insets = collectionView.adjustedContentInset

        switch configuration.scrollAxis {
        case .vertical:
            return CGPoint(
                x: proposedContentOffset.x,
                y: targetOffset - insets.top
            )
        case .horizontal:
            return CGPoint(
                x: targetOffset - insets.left,
                y: proposedContentOffset.y
            )
        }
    }

    func contentOffsetToCenterItem(at indexPath: IndexPath) -> CGPoint? {
        guard
            let flattenedIndex = flattenedIndexByIndexPath[indexPath]
        else {
            return nil
        }

        return contentOffset(forScrollProgress: CGFloat(flattenedIndex))
    }

    var scrollProgress: CGFloat {
        currentScrollProgress
    }

    func contentOffset(forScrollProgress progress: CGFloat) -> CGPoint? {
        guard let collectionView, progress.isFinite else {
            return nil
        }

        let insets = collectionView.adjustedContentInset
        let targetOffset = progress * resolvedScrollStep

        switch configuration.scrollAxis {
        case .vertical:
            return CGPoint(x: -insets.left, y: targetOffset - insets.top)
        case .horizontal:
            return CGPoint(x: targetOffset - insets.left, y: -insets.top)
        }
    }

    func indexPathForCenteredItem() -> IndexPath? {
        guard !itemIndexPaths.isEmpty else {
            return nil
        }

        let index = Int(currentScrollProgress.rounded())
        return itemIndexPaths[min(max(index, 0), itemIndexPaths.count - 1)]
    }

    private func rebuildIndexPathCacheIfNeeded() {
        guard let collectionView else {
            itemIndexPaths = []
            flattenedIndexByIndexPath = [:]
            cachedSectionItemCounts = []
            return
        }

        let itemCounts = (0..<collectionView.numberOfSections).map {
            collectionView.numberOfItems(inSection: $0)
        }

        guard itemCounts != cachedSectionItemCounts else {
            return
        }

        cachedSectionItemCounts = itemCounts
        itemIndexPaths = itemCounts.enumerated().flatMap { section, itemCount in
            (0..<itemCount).map { IndexPath(item: $0, section: section) }
        }
        flattenedIndexByIndexPath = Dictionary(
            uniqueKeysWithValues: itemIndexPaths.enumerated().map { ($1, $0) }
        )
    }

    private func makeLayoutAttributes(
        for indexPath: IndexPath,
        flattenedIndex: Int
    ) -> UICollectionViewLayoutAttributes? {
        guard let collectionView else {
            return nil
        }

        let angle = (CGFloat(flattenedIndex) - currentScrollProgress) * resolvedAnglePerItem
        let absoluteAngle = abs(angle)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        guard absoluteAngle <= resolvedMaximumVisibleAngle else {
            attributes.isHidden = true
            attributes.alpha = 0
            return attributes
        }

        let insets = collectionView.adjustedContentInset
        let viewportWidth = max(collectionView.bounds.width - insets.left - insets.right, 0)
        let viewportHeight = max(collectionView.bounds.height - insets.top - insets.bottom, 0)
        let viewportCenter = CGPoint(
            x: collectionView.bounds.minX + insets.left + viewportWidth / 2,
            y: collectionView.bounds.minY + insets.top + viewportHeight / 2
        )
        let primaryDisplacement = resolvedRadius * sin(angle)
        let curvedDisplacement = resolvedRadius * (1 - cos(angle))
        let curveDirection: CGFloat = configuration.curveSide == .trailing ? 1 : -1

        attributes.size = resolvedItemSize

        switch configuration.scrollAxis {
        case .vertical:
            attributes.center = CGPoint(
                x: viewportCenter.x + curveDirection * curvedDisplacement,
                y: viewportCenter.y + primaryDisplacement
            )
        case .horizontal:
            attributes.center = CGPoint(
                x: viewportCenter.x + primaryDisplacement,
                y: viewportCenter.y + curveDirection * curvedDisplacement
            )
        }

        let distance = min(absoluteAngle / resolvedMaximumVisibleAngle, 1)
        let scale = 1 - (1 - resolvedMinimumScale) * distance
        let normalizedSignedDistance = angle / resolvedMaximumVisibleAngle
        attributes.transform = CGAffineTransform(
            rotationAngle: normalizedSignedDistance * resolvedMaximumCardAngle * curveDirection
        ).scaledBy(x: scale, y: scale)
        attributes.alpha = 1 - (1 - resolvedMinimumAlpha) * distance
        attributes.zIndex = Int((1 - distance) * 1_000)

        return attributes
    }

    private var currentScrollProgress: CGFloat {
        guard let collectionView else {
            return 0
        }
        return primaryScrollOffset(for: collectionView.contentOffset) / resolvedScrollStep
    }

    private func primaryScrollOffset(for contentOffset: CGPoint) -> CGFloat {
        guard let collectionView else {
            return 0
        }

        switch configuration.scrollAxis {
        case .vertical:
            return contentOffset.y + collectionView.adjustedContentInset.top
        case .horizontal:
            return contentOffset.x + collectionView.adjustedContentInset.left
        }
    }

    private var resolvedItemSize: CGSize {
        CGSize(
            width: max(configuration.itemSize.width, 1),
            height: max(configuration.itemSize.height, 1)
        )
    }

    private var resolvedRadius: CGFloat {
        max(abs(configuration.radius), 1)
    }

    private var resolvedAnglePerItem: CGFloat {
        max(abs(configuration.anglePerItem), 0.001)
    }

    private var resolvedScrollStep: CGFloat {
        max(abs(configuration.scrollStep), 1)
    }

    private var resolvedMaximumVisibleAngle: CGFloat {
        min(
            max(abs(configuration.maximumVisibleAngle), resolvedAnglePerItem),
            .pi * 0.95
        )
    }

    private var resolvedMinimumScale: CGFloat {
        min(max(configuration.minimumScale, 0), 1)
    }

    private var resolvedMinimumAlpha: CGFloat {
        min(max(configuration.minimumAlpha, 0), 1)
    }

    private var resolvedMaximumCardAngle: CGFloat {
        min(max(abs(configuration.maximumCardAngle), 0), .pi)
    }
}
