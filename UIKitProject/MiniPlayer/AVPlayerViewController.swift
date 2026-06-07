//
//  AVPlayerViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 04/11/25.
//

import UIKit

final class AVPlayerViewController: UIViewController {
    private let playerZ = PlayerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(playerZ)
        view.backgroundColor = .yellow
        playerZ.frame = CGRect(x: 10, y: 100, width: 250, height: 250 * (992.0 / 558.0)) // ≈ 250 * 1.778
        playerZ.play()
        UIView.animate(withDuration: 1, delay: 2, options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            let width = view.bounds.width
            let height = width * (992.0 / 558.0)
            self.playerZ.frame = CGRect(x: 0, y: (view.bounds.height - height) / 2, width: width, height: height)
        }
    }
}
