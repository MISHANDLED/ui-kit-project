//
//  ShimmerCollectionViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 16/10/25.
//

import UIKit

// MARK: - Shimmer Cell
class ShimmerCell: UICollectionViewCell {
    static let identifier = "ShimmerCell"
    
    let shimmerLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.green.cgColor
        return layer
    }()
    
    private let maskLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .yellow
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.layer.addSublayer(shimmerLayer)
        shimmerLayer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = contentView.bounds
    }
    
    func updateMask(globalMaskX: CGFloat, collectionView: UICollectionView) {
        // Convert cell's frame to collection view coordinates
        guard let cellFrame = superview?.convert(frame, to: collectionView) else { return }
        
        // Calculate mask position in cell's local coordinates
        let maskXInCell = globalMaskX - cellFrame.minX
        
        maskLayer.frame = CGRect(x: maskXInCell, y: 0, width: 20, height: bounds.height)
    }
}

// MARK: - View Controller
protocol ShimmerCollectionViewDataSource: BaseViewModel {
    var numberOfCells: Int { get }
}

final class ShimmerCollectionViewModel: ShimmerCollectionViewDataSource {
    let numberOfCells: Int
    
    init(numberOfCells: Int = 5) {
        self.numberOfCells = numberOfCells
    }
}

final class ShimmerCollectionView<VM: ShimmerCollectionViewDataSource>: UIView, UICollectionViewDataSource {
    
    private var collectionView: UICollectionView!
    private var displayLink: CADisplayLink?
    
    // Layout configuration
    private let cellWidth: CGFloat = 100
    private let cellHeight: CGFloat = 50
    private let cellSpacing: CGFloat = 10
    private let shimmerWidth: CGFloat = 20
    
    private var maskX: CGFloat = -20
    private var viewModel: VM?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window == nil {
            stopShimmerAnimation()
        } else {
            startShimmerAnimation()
        }
    }
    
    func startShimmerAnimation() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(updateMaskPosition))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopShimmerAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.register(ShimmerCell.self, forCellWithReuseIdentifier: ShimmerCell.identifier)
        collectionView.isScrollEnabled = false
        
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    @objc private func updateMaskPosition() {
        // Move mask from left to right
        maskX += 2 // Adjust speed as needed
        
        // Reset when it goes off screen
        if maskX > collectionView.bounds.width {
            maskX = -shimmerWidth
        }
        
        // Update all visible cells with the new mask position
        for cell in collectionView.visibleCells {
            if let shimmerCell = cell as? ShimmerCell {
                shimmerCell.updateMask(globalMaskX: maskX, collectionView: collectionView)
            }
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfCells ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShimmerCell.identifier, for: indexPath) as! ShimmerCell
        return cell
    }
}

extension ShimmerCollectionView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {
        self.viewModel = viewModel
        collectionView.reloadData()
    }
}
