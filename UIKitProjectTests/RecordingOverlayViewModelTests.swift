//
//  RecordingOverlayViewModelTests.swift
//  UIKitProjectTests
//

import XCTest
@testable import UIKitProject

final class RecordingOverlayViewModelTests: XCTestCase {
    @MainActor
    func testViewDidLoadPublishesIdleState() {
        let recorder = ScreenRecordingSpy()
        let viewModel = RecordingOverlayViewModel(recorder: recorder)
        var states: [RecordingOverlayViewState] = []
        viewModel.onStateChange = { states.append($0) }

        viewModel.viewDidLoad()

        XCTAssertEqual(states, [.idle])
    }

    @MainActor
    func testFirstTapStartsRecording() {
        let recorder = ScreenRecordingSpy()
        let viewModel = RecordingOverlayViewModel(recorder: recorder)
        var states: [RecordingOverlayViewState] = []
        viewModel.onStateChange = { states.append($0) }

        viewModel.toggleRecording()

        XCTAssertEqual(recorder.startCallCount, 1)
        XCTAssertEqual(states, [.starting, .recording])
        XCTAssertEqual(viewModel.state, .recording)
    }

    @MainActor
    func testSecondTapStopsSavesAndShowsConfirmation() {
        let recorder = ScreenRecordingSpy()
        let viewModel = RecordingOverlayViewModel(recorder: recorder)
        var states: [RecordingOverlayViewState] = []
        viewModel.onStateChange = { states.append($0) }

        viewModel.toggleRecording()
        viewModel.toggleRecording()

        XCTAssertEqual(recorder.stopCallCount, 1)
        XCTAssertEqual(states, [.starting, .recording, .saving, .saved])
        XCTAssertEqual(viewModel.state, .saved)
    }

    @MainActor
    func testStartFailureShowsRetryState() {
        let recorder = ScreenRecordingSpy()
        recorder.startResult = .failure(.unavailable)
        let viewModel = RecordingOverlayViewModel(recorder: recorder)

        viewModel.toggleRecording()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected a failed state")
            return
        }
        XCTAssertEqual(message, ScreenRecordingError.unavailable.errorDescription)
    }

    @MainActor
    func testUnexpectedStopShowsFailure() {
        let recorder = ScreenRecordingSpy()
        let viewModel = RecordingOverlayViewModel(recorder: recorder)
        viewModel.toggleRecording()

        recorder.sendUnexpectedStop(.interrupted("The app entered the background."))

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected a failed state")
            return
        }
        XCTAssertTrue(message.contains("The app entered the background."))
    }

    @MainActor
    func testTapIsIgnoredWhileStartIsPending() {
        let recorder = ScreenRecordingSpy()
        recorder.completesStartImmediately = false
        let viewModel = RecordingOverlayViewModel(recorder: recorder)

        viewModel.toggleRecording()
        viewModel.toggleRecording()

        XCTAssertEqual(recorder.startCallCount, 1)
        XCTAssertEqual(recorder.stopCallCount, 0)
        XCTAssertEqual(viewModel.state, .starting)
    }
}

@MainActor
private final class ScreenRecordingSpy: ScreenRecording {
    var onUnexpectedStop: ((ScreenRecordingError) -> Void)?
    var startResult: Result<Void, ScreenRecordingError> = .success(())
    var stopResult: Result<Void, ScreenRecordingError> = .success(())
    var completesStartImmediately = true
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    func start(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void) {
        startCallCount += 1
        if completesStartImmediately {
            completion(startResult)
        }
    }

    func stopAndSave(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void) {
        stopCallCount += 1
        completion(stopResult)
    }

    func sendUnexpectedStop(_ error: ScreenRecordingError) {
        onUnexpectedStop?(error)
    }
}
