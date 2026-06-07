//
//  MiniPlayer.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 04/11/25.
//

import UIKit
import AVFoundation

final class PlayerView: UIView {

    private let containerView = UIView()
    private let playerLayer = AVPlayerLayer()
    private let player: AVPlayer
    private var videoAspect: CGFloat?

    init() {
        guard let url = URL(string: "https://b.zmtcdn.com/data/file_assets/d5a8ea8325f99030eb6c30c41e72e86c1756198081.mp4") else {
            fatalError("Invalid video URL")
        }
        self.player = AVPlayer(url: url)
        super.init(frame: .zero)
        configure()
        loadVideoProperties()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure() {
        backgroundColor = .black
        clipsToBounds = false

        containerView.backgroundColor = .black
        addSubview(containerView)
        containerView.layer.addSublayer(playerLayer)

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }
    
    private func loadVideoProperties() {
        guard let asset = player.currentItem?.asset else { return }
        
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }
                
                let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
                let transformedSize = naturalSize.applying(preferredTransform)
                let aspect = abs(transformedSize.height / transformedSize.width)
                
                await MainActor.run {
                    self.videoAspect = aspect
                    self.setNeedsLayout()
                }
            } catch {
                print("Failed to load video properties: \(error)")
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let videoAspect = videoAspect else {
            containerView.frame = bounds
            playerLayer.frame = containerView.bounds
            return
        }

        let viewAspect = bounds.height / bounds.width

        // Fit containerView maintaining video aspect
        if videoAspect > viewAspect {
            // Video taller → pillarbox
            let height = bounds.height
            let width = height / videoAspect
            containerView.frame = CGRect(
                x: (bounds.width - width) / 2,
                y: 0,
                width: width,
                height: height
            )
        } else {
            // Video wider → letterbox
            let width = bounds.width
            let height = width * videoAspect
            containerView.frame = CGRect(
                x: 0,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        }

        playerLayer.frame = containerView.bounds
    }

    func play() { player.play() }
    func pause() { player.pause() }
}
