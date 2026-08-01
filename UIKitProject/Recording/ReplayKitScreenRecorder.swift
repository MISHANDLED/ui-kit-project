//
//  ReplayKitScreenRecorder.swift
//  UIKitProject
//

import Photos
import ReplayKit

@MainActor
final class ReplayKitScreenRecorder: NSObject, ScreenRecording {
    private enum State {
        case idle
        case starting
        case recording
        case stopping
        case saving
    }

    var onUnexpectedStop: ((ScreenRecordingError) -> Void)?

    private let recorder: RPScreenRecorder
    private let photoLibrary: PHPhotoLibrary
    private let fileManager: FileManager

    private var state: State = .idle
    private var outputURL: URL?
    private var startCompletion: ((Result<Void, ScreenRecordingError>) -> Void)?
    private var stopCompletion: ((Result<Void, ScreenRecordingError>) -> Void)?

    init(
        recorder: RPScreenRecorder = .shared(),
        photoLibrary: PHPhotoLibrary = .shared(),
        fileManager: FileManager = .default
    ) {
        self.recorder = recorder
        self.photoLibrary = photoLibrary
        self.fileManager = fileManager
        super.init()

        recorder.delegate = self
        recorder.isMicrophoneEnabled = false
    }

    func start(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void) {
        guard state == .idle else {
            completion(.failure(errorForCurrentState))
            return
        }

        guard recorder.isAvailable else {
            completion(.failure(.unavailable))
            return
        }

        guard !recorder.isRecording else {
            completion(.failure(.alreadyRecording))
            return
        }

        state = .starting
        startCompletion = completion
        recorder.isMicrophoneEnabled = false

        recorder.startRecording { [weak self] error in
            DispatchQueue.main.async {
                self?.handleStartCompletion(error: error)
            }
        }
    }

    func stopAndSave(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void) {
        guard state == .recording else {
            completion(.failure(errorForCurrentState))
            return
        }

        let url: URL
        do {
            url = try makeOutputURL()
        } catch {
            completion(.failure(.stopFailed(error.localizedDescription)))
            return
        }

        state = .stopping
        outputURL = url
        stopCompletion = completion

        recorder.stopRecording(withOutput: url) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleStopCompletion(error: error)
            }
        }
    }

    private var errorForCurrentState: ScreenRecordingError {
        switch state {
        case .idle:
            return .notRecording
        case .recording:
            return .alreadyRecording
        case .starting, .stopping, .saving:
            return .operationInProgress
        }
    }

    private func handleStartCompletion(error: Error?) {
        guard state == .starting else {
            return
        }

        if let error {
            state = .idle
            finishStart(with: .failure(.startFailed(error.localizedDescription)))
        } else {
            state = .recording
            finishStart(with: .success(()))
        }
    }

    private func handleStopCompletion(error: Error?) {
        guard state == .stopping, let outputURL else {
            return
        }

        if let error {
            finishStop(with: .failure(.stopFailed(error.localizedDescription)))
            return
        }

        guard
            fileManager.fileExists(atPath: outputURL.path),
            let attributes = try? fileManager.attributesOfItem(atPath: outputURL.path),
            let fileSize = attributes[.size] as? NSNumber,
            fileSize.int64Value > 0
        else {
            finishStop(with: .failure(.stopFailed("ReplayKit produced an empty movie.")))
            return
        }

        state = .saving
        requestPhotoAccessAndSave(outputURL)
    }

    private func requestPhotoAccessAndSave(_ url: URL) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            saveToPhotoLibrary(url)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if status == .authorized || status == .limited {
                        self.saveToPhotoLibrary(url)
                    } else {
                        self.finishStop(with: .failure(.photoLibraryPermissionDenied))
                    }
                }
            }

        case .denied, .restricted:
            finishStop(with: .failure(.photoLibraryPermissionDenied))

        @unknown default:
            finishStop(with: .failure(.photoLibraryPermissionDenied))
        }
    }

    private func saveToPhotoLibrary(_ url: URL) {
        photoLibrary.performChanges {
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = false

            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .video, fileURL: url, options: options)
        } completionHandler: { [weak self] saved, error in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                if saved {
                    self.finishStop(with: .success(()))
                } else {
                    let message = error?.localizedDescription ?? "Photos rejected the movie."
                    self.finishStop(with: .failure(.saveFailed(message)))
                }
            }
        }
    }

    private func makeOutputURL() throws -> URL {
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ScreenRecordings", isDirectory: true)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
            .appendingPathComponent("Recording-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
    }

    private func finishStart(with result: Result<Void, ScreenRecordingError>) {
        let completion = startCompletion
        startCompletion = nil
        completion?(result)
    }

    private func finishStop(with result: Result<Void, ScreenRecordingError>) {
        let completion = stopCompletion
        stopCompletion = nil

        if let outputURL {
            try? fileManager.removeItem(at: outputURL)
        }
        outputURL = nil
        state = .idle

        completion?(result)
    }

    private func handleUnexpectedStop(error: Error?) {
        let message = error?.localizedDescription ?? "ReplayKit ended the recording."
        let recordingError = ScreenRecordingError.interrupted(message)

        switch state {
        case .starting:
            state = .idle
            finishStart(with: .failure(recordingError))

        case .recording:
            state = .idle
            onUnexpectedStop?(recordingError)

        case .idle, .stopping, .saving:
            break
        }
    }
}

extension ReplayKitScreenRecorder: RPScreenRecorderDelegate {
    nonisolated func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.handleUnexpectedStop(error: error)
        }
    }
}
