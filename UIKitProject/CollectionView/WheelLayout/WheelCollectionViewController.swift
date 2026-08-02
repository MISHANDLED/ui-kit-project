import UIKit

private struct WheelDemoItem: Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let symbolName: String
}

private struct WheelDemoOccurrence: Hashable {
    let virtualIndex: Int
    let item: WheelDemoItem
}

private final class WheelCollectionViewCell: UICollectionViewCell {
    private var item: WheelDemoItem?

    func configure(with item: WheelDemoItem) {
        self.item = item
        accessibilityLabel = "\(item.title), \(item.subtitle)"
        setNeedsUpdateConfiguration()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let item else {
            return
        }

        var content = UIListContentConfiguration.subtitleCell()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.image = UIImage(systemName: item.symbolName)
        content.imageProperties.tintColor = tintColor(for: item.id)
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .caption1)
        content = content.updated(for: state)
        contentConfiguration = content

        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = state.isHighlighted || state.isSelected
            ? UIColor.systemIndigo.withAlphaComponent(0.22)
            : UIColor.secondarySystemBackground.withAlphaComponent(0.94)
        background.cornerRadius = 18
        background.strokeColor = UIColor.separator.withAlphaComponent(0.45)
        background.strokeWidth = 1
        backgroundConfiguration = background.updated(for: state)
    }

    private func tintColor(for identifier: Int) -> UIColor {
        let colors: [UIColor] = [
            .systemIndigo,
            .systemPink,
            .systemTeal,
            .systemOrange,
            .systemPurple
        ]
        return colors[identifier % colors.count]
    }
}

final class WheelCollectionViewController: UIViewController {
    private enum Section {
        case main
    }

    private let wheelLayout = WheelCollectionViewLayout()
    private let selectionIndicatorView = UIView()
    private let controlsContainerView = UIView()
    private let controlsDisclosureButton = UIButton(type: .system)
    private let controlsContentStack = UIStackView()
    private let axisControl = UISegmentedControl(items: ["Vertical", "Horizontal"])
    private let angleTitleLabel = UILabel()
    private let angleValueLabel = UILabel()
    private let angleSlider = UISlider()
    private let overlapTitleLabel = UILabel()
    private let overlapValueLabel = UILabel()
    private let overlapSlider = UISlider()
    private let infiniteScrollingLabel = UILabel()
    private let infiniteScrollingSwitch = UISwitch()
    private let baseItems: [WheelDemoItem] = {
        let symbols = [
            "circle.grid.2x2.fill",
            "square.stack.3d.up.fill",
            "arrow.up.and.down",
            "scope",
            "slider.horizontal.3"
        ]
        return (1...24).map { number in
            WheelDemoItem(
                id: number,
                title: String(format: "Item %02d", number),
                subtitle: "Wheel position \(number)",
                symbolName: symbols[(number - 1) % symbols.count]
            )
        }
    }()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: wheelLayout
    )
    private var dataSource: UICollectionViewDiffableDataSource<Section, WheelDemoOccurrence>?
    private var didSetInitialPosition = false
    private var isInfiniteScrolling = false
    private var isApplyingSnapshot = false
    private var isRecentering = false
    private var areControlsExpanded = false
    private var selectionIndicatorWidthConstraint: NSLayoutConstraint?
    private var selectionIndicatorHeightConstraint: NSLayoutConstraint?

    private var loopingMapper: WheelLoopingMapper {
        WheelLoopingMapper(itemsPerCycle: baseItems.count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureDataSource()
        applyInitialSnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !didSetInitialPosition else {
            return
        }

        collectionView.layoutIfNeeded()
        let initialIndexPath = IndexPath(item: 5, section: 0)
        guard let offset = wheelLayout.contentOffsetToCenterItem(at: initialIndexPath) else {
            return
        }

        didSetInitialPosition = true
        collectionView.setContentOffset(offset, animated: false)
        updateTitleForCenteredItem()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Wheel Layout"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Flip",
            style: .plain,
            target: self,
            action: #selector(flipWheel)
        )

        selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicatorView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.08)
        selectionIndicatorView.layer.borderColor = UIColor.systemIndigo.withAlphaComponent(0.55).cgColor
        selectionIndicatorView.layer.borderWidth = 1.5
        selectionIndicatorView.layer.cornerRadius = 22
        selectionIndicatorView.isAccessibilityElement = false

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self

        configureControls()

        view.addSubview(selectionIndicatorView)
        view.addSubview(collectionView)
        view.addSubview(controlsContainerView)

        let safeArea = view.safeAreaLayoutGuide
        let itemSize = wheelLayout.configuration.itemSize
        let indicatorWidthConstraint = selectionIndicatorView.widthAnchor.constraint(
            equalToConstant: itemSize.width + 16
        )
        let indicatorHeightConstraint = selectionIndicatorView.heightAnchor.constraint(
            equalToConstant: itemSize.height + 12
        )
        selectionIndicatorWidthConstraint = indicatorWidthConstraint
        selectionIndicatorHeightConstraint = indicatorHeightConstraint

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.topAnchor.constraint(
                equalTo: controlsContainerView.bottomAnchor,
                constant: 12
            ),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            controlsContainerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            controlsContainerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            controlsContainerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 12),
            selectionIndicatorView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            selectionIndicatorView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            indicatorWidthConstraint,
            indicatorHeightConstraint
        ])
    }

    private func configureControls() {
        controlsContainerView.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.backgroundColor = .secondarySystemBackground
        controlsContainerView.layer.cornerRadius = 20
        controlsContainerView.layer.cornerCurve = .continuous

        controlsDisclosureButton.contentHorizontalAlignment = .fill
        controlsDisclosureButton.accessibilityIdentifier = "wheel.settings.disclosure"
        controlsDisclosureButton.addTarget(
            self,
            action: #selector(toggleControlsVisibility),
            for: .touchUpInside
        )

        axisControl.selectedSegmentIndex = 0
        axisControl.accessibilityLabel = "Wheel scrolling direction"
        axisControl.addTarget(self, action: #selector(scrollAxisChanged), for: .valueChanged)

        angleTitleLabel.text = "Maximum card angle"
        angleTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        angleTitleLabel.adjustsFontForContentSizeCategory = true

        angleValueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        angleValueLabel.textAlignment = .right
        angleValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        angleSlider.minimumValue = 0
        angleSlider.maximumValue = 75
        angleSlider.value = Float(wheelLayout.configuration.maximumCardAngle * 180 / .pi)
        angleSlider.isContinuous = true
        angleSlider.accessibilityLabel = "Maximum card angle"
        angleSlider.addTarget(self, action: #selector(cardAngleChanged), for: .valueChanged)
        updateAngleValueLabel()

        overlapTitleLabel.text = "Overlap angle"
        overlapTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        overlapTitleLabel.adjustsFontForContentSizeCategory = true

        overlapValueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        overlapValueLabel.textAlignment = .right
        overlapValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        overlapSlider.minimumValue = 8
        overlapSlider.maximumValue = 32
        overlapSlider.value = Float(wheelLayout.configuration.anglePerItem * 180 / .pi)
        overlapSlider.isContinuous = true
        overlapSlider.accessibilityLabel = "Overlap angle"
        overlapSlider.accessibilityHint = "Smaller angles make adjacent cards overlap more"
        overlapSlider.addTarget(self, action: #selector(overlapAngleChanged), for: .valueChanged)
        updateOverlapValueLabel()

        infiniteScrollingLabel.text = "Infinite scrolling"
        infiniteScrollingLabel.font = .preferredFont(forTextStyle: .subheadline)
        infiniteScrollingLabel.adjustsFontForContentSizeCategory = true

        infiniteScrollingSwitch.isOn = false
        infiniteScrollingSwitch.accessibilityLabel = "Infinite scrolling"
        infiniteScrollingSwitch.addTarget(
            self,
            action: #selector(infiniteScrollingChanged),
            for: .valueChanged
        )

        let angleHeader = UIStackView(arrangedSubviews: [angleTitleLabel, angleValueLabel])
        angleHeader.axis = .horizontal
        angleHeader.alignment = .center
        angleHeader.spacing = 8

        let overlapHeader = UIStackView(arrangedSubviews: [overlapTitleLabel, overlapValueLabel])
        overlapHeader.axis = .horizontal
        overlapHeader.alignment = .center
        overlapHeader.spacing = 8

        let infiniteScrollingRow = UIStackView(
            arrangedSubviews: [infiniteScrollingLabel, infiniteScrollingSwitch]
        )
        infiniteScrollingRow.axis = .horizontal
        infiniteScrollingRow.alignment = .center
        infiniteScrollingRow.spacing = 8

        [
            axisControl,
            angleHeader,
            angleSlider,
            overlapHeader,
            overlapSlider,
            infiniteScrollingRow
        ].forEach(controlsContentStack.addArrangedSubview)
        controlsContentStack.axis = .vertical
        controlsContentStack.spacing = 10
        controlsContentStack.isHidden = !areControlsExpanded
        controlsContentStack.alpha = areControlsExpanded ? 1 : 0
        controlsContentStack.accessibilityIdentifier = "wheel.settings.content"

        let panelStack = UIStackView(
            arrangedSubviews: [controlsDisclosureButton, controlsContentStack]
        )
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        panelStack.axis = .vertical
        panelStack.spacing = 10
        controlsContainerView.addSubview(panelStack)
        updateControlsDisclosureConfiguration()

        NSLayoutConstraint.activate([
            panelStack.leadingAnchor.constraint(
                equalTo: controlsContainerView.leadingAnchor,
                constant: 16
            ),
            panelStack.topAnchor.constraint(
                equalTo: controlsContainerView.topAnchor,
                constant: 12
            ),
            panelStack.trailingAnchor.constraint(
                equalTo: controlsContainerView.trailingAnchor,
                constant: -16
            ),
            panelStack.bottomAnchor.constraint(
                equalTo: controlsContainerView.bottomAnchor,
                constant: -12
            )
        ])
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<
            WheelCollectionViewCell,
            WheelDemoOccurrence
        > { cell, _, occurrence in
            cell.configure(with: occurrence.item)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, WheelDemoOccurrence>(
            collectionView: collectionView
        ) { collectionView, indexPath, occurrence in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: occurrence
            )
        }
    }

    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, WheelDemoOccurrence>()
        snapshot.appendSections([.main])
        snapshot.appendItems(makeOccurrences(infinite: false))
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    @objc
    private func toggleControlsVisibility() {
        areControlsExpanded.toggle()
        let areExpanding = areControlsExpanded
        updateControlsDisclosureConfiguration()
        controlsDisclosureButton.isUserInteractionEnabled = false

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        ) {
            self.controlsContentStack.isHidden = !areExpanding
            self.controlsContentStack.alpha = areExpanding ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self else {
                return
            }

            controlsDisclosureButton.isUserInteractionEnabled = true
            UIAccessibility.post(
                notification: .layoutChanged,
                argument: areExpanding ? axisControl : controlsDisclosureButton
            )
        }
    }

    @objc
    private func flipWheel() {
        var configuration = wheelLayout.configuration
        configuration.curveSide = configuration.curveSide == .trailing
            ? .leading
            : .trailing

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.wheelLayout.configuration = configuration
            self.collectionView.layoutIfNeeded()
        }
    }

    @objc
    private func scrollAxisChanged(_ sender: UISegmentedControl) {
        let scrollAxis: WheelCollectionViewLayout.ScrollAxis = sender.selectedSegmentIndex == 0
            ? .vertical
            : .horizontal

        guard scrollAxis != wheelLayout.configuration.scrollAxis else {
            return
        }

        let centeredIndexPath = wheelLayout.indexPathForCenteredItem()
        var configuration = wheelLayout.configuration
        configuration.scrollAxis = scrollAxis

        switch scrollAxis {
        case .vertical:
            configuration.itemSize = CGSize(width: 236, height: 72)
            configuration.radius = 280
            configuration.scrollStep = 86
            configuration.maximumVisibleAngle = 1.25
        case .horizontal:
            configuration.itemSize = CGSize(width: 164, height: 92)
            configuration.radius = 220
            configuration.scrollStep = 86
            configuration.maximumVisibleAngle = 1.05
        }

        wheelLayout.configuration = configuration
        collectionView.alwaysBounceVertical = scrollAxis == .vertical
        collectionView.alwaysBounceHorizontal = scrollAxis == .horizontal
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.layoutIfNeeded()

        if
            let centeredIndexPath,
            let offset = wheelLayout.contentOffsetToCenterItem(at: centeredIndexPath)
        {
            collectionView.setContentOffset(offset, animated: false)
        }

        updateSelectionIndicatorSize(for: configuration.itemSize)
        collectionView.layoutIfNeeded()
        updateTitleForCenteredItem()
        updateControlsDisclosureConfiguration()
    }

    @objc
    private func cardAngleChanged(_ sender: UISlider) {
        var configuration = wheelLayout.configuration
        configuration.maximumCardAngle = CGFloat(sender.value) * .pi / 180
        wheelLayout.configuration = configuration
        collectionView.layoutIfNeeded()
        updateAngleValueLabel()
        updateControlsDisclosureConfiguration()
    }

    @objc
    private func overlapAngleChanged(_ sender: UISlider) {
        var configuration = wheelLayout.configuration
        configuration.anglePerItem = CGFloat(sender.value) * .pi / 180
        wheelLayout.configuration = configuration
        collectionView.layoutIfNeeded()
        updateOverlapValueLabel()
        updateControlsDisclosureConfiguration()
    }

    @objc
    private func infiniteScrollingChanged(_ sender: UISwitch) {
        let baseItemIndex = currentBaseItemIndex() ?? 5
        applyScrollingMode(
            infinite: sender.isOn,
            preservingBaseItemIndex: baseItemIndex
        )
    }

    private func updateSelectionIndicatorSize(for itemSize: CGSize) {
        selectionIndicatorWidthConstraint?.constant = itemSize.width + 16
        selectionIndicatorHeightConstraint?.constant = itemSize.height + 12

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateAngleValueLabel() {
        let degrees = Int(angleSlider.value.rounded())
        angleValueLabel.text = "\(degrees)°"
        angleSlider.accessibilityValue = "\(degrees) degrees"
    }

    private func updateOverlapValueLabel() {
        let degrees = Int(overlapSlider.value.rounded())
        overlapValueLabel.text = "\(degrees)°"
        overlapSlider.accessibilityValue = "\(degrees) degrees"
    }

    private func updateControlsDisclosureConfiguration() {
        let axis = wheelLayout.configuration.scrollAxis == .vertical
            ? "Vertical"
            : "Horizontal"
        let maximumAngle = Int(angleSlider.value.rounded())
        let overlapAngle = Int(overlapSlider.value.rounded())
        let scrollingMode = isInfiniteScrolling ? "Infinite" : "Finite"
        let summary = "\(axis) · \(maximumAngle)° · \(overlapAngle)° overlap · \(scrollingMode)"

        var configuration = UIButton.Configuration.plain()
        configuration.title = "Wheel settings"
        configuration.subtitle = areControlsExpanded ? nil : summary
        configuration.image = UIImage(
            systemName: areControlsExpanded ? "chevron.up" : "chevron.down"
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 12
        configuration.titleAlignment = .leading
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = .label
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .headline)
            return attributes
        }
        configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .caption1)
            attributes.foregroundColor = .secondaryLabel
            return attributes
        }

        controlsDisclosureButton.configuration = configuration
        controlsDisclosureButton.accessibilityLabel = "Wheel settings"
        controlsDisclosureButton.accessibilityValue = [
            areControlsExpanded ? "Expanded" : "Collapsed",
            summary
        ].joined(separator: ", ")
        controlsDisclosureButton.accessibilityHint = areControlsExpanded
            ? "Double-tap to collapse settings"
            : "Double-tap to expand settings"
    }

    private func makeOccurrences(infinite: Bool) -> [WheelDemoOccurrence] {
        guard !baseItems.isEmpty else {
            return []
        }

        let itemCount = infinite ? loopingMapper.totalItemCount : baseItems.count
        return (0..<itemCount).map { virtualIndex in
            WheelDemoOccurrence(
                virtualIndex: virtualIndex,
                item: baseItems[virtualIndex % baseItems.count]
            )
        }
    }

    private func applyScrollingMode(
        infinite: Bool,
        preservingBaseItemIndex baseItemIndex: Int
    ) {
        guard let dataSource else {
            infiniteScrollingSwitch.setOn(isInfiniteScrolling, animated: true)
            updateControlsDisclosureConfiguration()
            return
        }

        isInfiniteScrolling = infinite
        updateControlsDisclosureConfiguration()
        isApplyingSnapshot = true
        infiniteScrollingSwitch.isEnabled = false

        var snapshot = NSDiffableDataSourceSnapshot<Section, WheelDemoOccurrence>()
        snapshot.appendSections([.main])
        snapshot.appendItems(makeOccurrences(infinite: infinite))

        dataSource.applySnapshotUsingReloadData(snapshot) { [weak self] in
            guard let self else {
                return
            }

            collectionView.layoutIfNeeded()
            let normalizedBaseIndex = (
                (baseItemIndex % baseItems.count) + baseItems.count
            ) % baseItems.count
            let targetIndex = infinite
                ? loopingMapper.virtualIndex(forBaseIndex: normalizedBaseIndex)
                : normalizedBaseIndex
            let targetIndexPath = IndexPath(item: targetIndex, section: 0)

            if let offset = wheelLayout.contentOffsetToCenterItem(at: targetIndexPath) {
                collectionView.setContentOffset(offset, animated: false)
            }

            collectionView.layoutIfNeeded()
            isApplyingSnapshot = false
            infiniteScrollingSwitch.isEnabled = true
            updateTitleForCenteredItem()
        }
    }

    private func currentBaseItemIndex() -> Int? {
        guard
            let indexPath = wheelLayout.indexPathForCenteredItem(),
            let occurrence = dataSource?.itemIdentifier(for: indexPath),
            !baseItems.isEmpty
        else {
            return nil
        }
        return occurrence.virtualIndex % baseItems.count
    }

    private func recenterInfiniteWheelIfNeeded() {
        guard
            isInfiniteScrolling,
            !isApplyingSnapshot,
            !isRecentering,
            let targetProgress = loopingMapper.recenteredProgressIfNeeded(
                wheelLayout.scrollProgress
            ),
            let targetOffset = wheelLayout.contentOffset(forScrollProgress: targetProgress)
        else {
            return
        }

        isRecentering = true
        collectionView.contentOffset = targetOffset
        isRecentering = false
    }

    private func centerItem(at indexPath: IndexPath, animated: Bool) {
        guard let offset = wheelLayout.contentOffsetToCenterItem(at: indexPath) else {
            return
        }
        collectionView.setContentOffset(offset, animated: animated)
    }

    private func updateTitleForCenteredItem() {
        guard
            let indexPath = wheelLayout.indexPathForCenteredItem(),
            let occurrence = dataSource?.itemIdentifier(for: indexPath)
        else {
            navigationItem.title = "Wheel Layout"
            return
        }
        navigationItem.title = "Wheel • \(occurrence.item.title)"
    }
}

extension WheelCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        recenterInfiniteWheelIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        centerItem(at: indexPath, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateTitleForCenteredItem()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateTitleForCenteredItem()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateTitleForCenteredItem()
    }
}
