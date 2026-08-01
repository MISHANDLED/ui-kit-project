//
//  AVPlayerViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 04/11/25.
//

import UIKit

protocol AVPlayerContainerViewDataSource: BaseViewModel {}

final class AVPlayerContainerViewModel: AVPlayerContainerViewDataSource {}

final class AVPlayerContainerView<VM: AVPlayerContainerViewDataSource>: UIView {
    private let playerZ = PlayerView()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(playerZ)
        backgroundColor = .yellow
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        playerZ.frame = CGRect(x: 10, y: 100, width: 250, height: 250 * (992.0 / 558.0)) // ≈ 250 * 1.778
        playerZ.play()
        UIView.animate(withDuration: 1, delay: 2, options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            let width = bounds.width
            let height = width * (992.0 / 558.0)
            self.playerZ.frame = CGRect(x: 0, y: (bounds.height - height) / 2, width: width, height: height)
        }
    }
}

extension AVPlayerContainerView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}
