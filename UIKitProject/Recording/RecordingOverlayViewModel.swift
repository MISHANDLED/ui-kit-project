//
//  RecordingOverlayViewModel.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

import Foundation

enum RecordingOverlayViewState: Equatable {
    case idle
    case starting
    case recording
    case saving
    case saved
    case failed(message: String)
}

@MainActor
final class RecordingOverlayViewModel: BaseViewModel {
    var onStateChange: ((RecordingOverlayViewState) -> Void)?

    private(set) var state: RecordingOverlayViewState = .idle

    private let recorder: any ScreenRecording
    private var savedResetWorkItem: DispatchWorkItem?

    init(recorder: any ScreenRecording) {
        self.recorder = recorder
        recorder.onUnexpectedStop = { [weak self] error in
            self?.show(error)
        }
    }

    func viewDidLoad() {
        onStateChange?(state)
    }

    func toggleRecording() {
        switch state {
        case .idle, .saved, .failed:
            startRecording()

        case .recording:
            stopRecording()

        case .starting, .saving:
            break
        }
    }

    private func startRecording() {
        savedResetWorkItem?.cancel()
        transition(to: .starting)

        recorder.start { [weak self] result in
            switch result {
            case .success:
                self?.transition(to: .recording)
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    private func stopRecording() {
        transition(to: .saving)

        recorder.stopAndSave { [weak self] result in
            switch result {
            case .success:
                self?.showSavedConfirmation()
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    private func showSavedConfirmation() {
        transition(to: .saved)

        let workItem = DispatchWorkItem { [weak self] in
            guard self?.state == .saved else {
                return
            }
            self?.transition(to: .idle)
        }
        savedResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }

    private func show(_ error: ScreenRecordingError) {
        savedResetWorkItem?.cancel()
        let message = error.errorDescription ?? "Screen recording failed."
        transition(to: .failed(message: message))
    }

    private func transition(to newState: RecordingOverlayViewState) {
        state = newState
        onStateChange?(newState)
    }
}
