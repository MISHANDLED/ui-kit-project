//
//  RecordingOverlayController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

import UIKit

@MainActor
final class RecordingOverlayController {
    private let recorder: any ScreenRecording
    private var overlayWindow: RecordingOverlayWindow?

    init() {
        recorder = ReplayKitScreenRecorder()
    }

    init(recorder: any ScreenRecording) {
        self.recorder = recorder
    }

    func install(in windowScene: UIWindowScene) {
        guard overlayWindow == nil else {
            return
        }

        let viewModel = RecordingOverlayViewModel(recorder: recorder)
        let viewController = BaseViewController(
            contentView: RecordingOverlayView(frame: .zero),
            viewModel: viewModel
        )

        let overlayWindow = RecordingOverlayWindow(windowScene: windowScene)
        overlayWindow.rootViewController = viewController
        overlayWindow.isHidden = false
        self.overlayWindow = overlayWindow
    }
}

private final class RecordingOverlayWindow: UIWindow {
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        accessibilityViewIsModal = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }

        if hitView === self || hitView === rootViewController?.view {
            return nil
        }

        return hitView
    }
}
