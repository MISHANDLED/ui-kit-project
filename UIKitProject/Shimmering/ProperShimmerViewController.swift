//
//  ProperShimmerViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 16/10/25.
//

import UIKit

// MARK: - Shimmer Tag Cell
class ProperShimmerTagCell: UICollectionViewCell {
    static let identifier = "ProperShimmerTagCell"
    
    // Gradient shimmer layer
    private let shimmerGradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.locations = [0, 0.5, 1]
        return gradient
    }()
    
    private let maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.white.cgColor
        return layer
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Add shimmer on top of label
        contentView.layer.addSublayer(shimmerGradient)
        shimmerGradient.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerGradient.frame = contentView.bounds
        maskLayer.frame = contentView.bounds
    }
    
    func configure(with text: String) {
        label.text = text
    }
    
    func updateMask(diagonalProgress: CGFloat, shimmerWidth: CGFloat, collectionView: UICollectionView) {
        guard let cellFrame = superview?.convert(frame, to: collectionView) else { return }
        
        let localDiagonalValue = diagonalProgress - cellFrame.minX - cellFrame.minY
        
        var points: [CGPoint] = []
        
        let yAtLeft = localDiagonalValue
        if yAtLeft >= 0 && yAtLeft <= bounds.height {
            points.append(CGPoint(x: 0, y: yAtLeft))
        }
        
        let yAtRight = localDiagonalValue - bounds.width
        if yAtRight >= 0 && yAtRight <= bounds.height {
            points.append(CGPoint(x: bounds.width, y: yAtRight))
        }
        
        let xAtTop = localDiagonalValue
        if xAtTop >= 0 && xAtTop <= bounds.width {
            points.append(CGPoint(x: xAtTop, y: 0))
        }
        
        let xAtBottom = localDiagonalValue - bounds.height
        if xAtBottom >= 0 && xAtBottom <= bounds.width {
            points.append(CGPoint(x: xAtBottom, y: bounds.height))
        }
        
        points = Array(Set(points.map { CGPoint(x: round($0.x * 100) / 100, y: round($0.y * 100) / 100) }))
        
        if points.count >= 2 {
            let path = UIBezierPath()
            let p1 = points[0]
            let p2 = points[1]
            
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let length = sqrt(dx * dx + dy * dy)
            
            if length > 0 {
                let perpX = -dy / length * shimmerWidth / 2
                let perpY = dx / length * shimmerWidth / 2
                
                path.move(to: CGPoint(x: p1.x + perpX, y: p1.y + perpY))
                path.addLine(to: CGPoint(x: p2.x + perpX, y: p2.y + perpY))
                path.addLine(to: CGPoint(x: p2.x - perpX, y: p2.y - perpY))
                path.addLine(to: CGPoint(x: p1.x - perpX, y: p1.y - perpY))
                path.close()
                
                maskLayer.path = path.cgPath
            } else {
                maskLayer.path = nil
            }
        } else {
            maskLayer.path = nil
        }
    }
}

// MARK: - Tag Flow Layout
class ProperShimmerTagFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        minimumInteritemSpacing = 8
        minimumLineSpacing = 8
        sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Controller
class ProperShimmerViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var displayLink: CADisplayLink?
    
    private let shimmerWidth: CGFloat = 40
    private var diagonalProgress: CGFloat = -100
    
    private let tags = [
        "Swift",
        "iOS Development",
        "UIKit",
        "SwiftUI",
        "Xcode",
        "CocoaPods",
        "Shimmer Effect",
        "Animation",
        "CALayer",
        "Collection View",
        "Auto Layout",
        "Storyboard",
        "Interface Builder",
        "Core Data",
        "Combine Framework",
        "RxSwift",
        "Alamofire",
        "Networking",
        "JSON Parsing",
        "REST API",
        "Grand Central Dispatch",
        "URLSession",
        "Codable Protocol",
        "Property Wrappers",
        "Async/Await"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        view.backgroundColor = .white
        title = "Diagonal Shimmer"
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
        let layout = ProperShimmerTagFlowLayout()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.register(ProperShimmerTagCell.self, forCellWithReuseIdentifier: ProperShimmerTagCell.identifier)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func startShimmerAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateMaskPosition))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateMaskPosition() {
        diagonalProgress += 4
        
        let maxDistance = collectionView.bounds.width + collectionView.bounds.height
        if diagonalProgress > maxDistance + 200 {
            diagonalProgress = -100
        }
        
        for cell in collectionView.visibleCells {
            if let shimmerCell = cell as? ProperShimmerTagCell {
                shimmerCell.updateMask(diagonalProgress: diagonalProgress, shimmerWidth: shimmerWidth, collectionView: collectionView)
            }
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - UICollectionViewDataSource
extension ProperShimmerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProperShimmerTagCell.identifier, for: indexPath) as! ProperShimmerTagCell
        cell.configure(with: tags[indexPath.item])
        return cell
    }
}
