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
class ShimmerCollectionViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var displayLink: CADisplayLink?
    
    // Layout configuration
    private let cellWidth: CGFloat = 100
    private let cellHeight: CGFloat = 50
    private let cellSpacing: CGFloat = 10
    private let numberOfCells = 5
    private let shimmerWidth: CGFloat = 20
    
    private var maskX: CGFloat = -20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startShimmerAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func startShimmerAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateMaskPosition))
        displayLink?.add(to: .main, forMode: .common)
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
}

// MARK: - UICollectionViewDataSource
extension ShimmerCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfCells
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShimmerCell.identifier, for: indexPath) as! ShimmerCell
        return cell
    }
}
