//
//  ScreenRecording.swift
//  UIKitProject
//

import Foundation

enum ScreenRecordingError: LocalizedError {
    case unavailable
    case alreadyRecording
    case notRecording
    case operationInProgress
    case startFailed(String)
    case stopFailed(String)
    case photoLibraryPermissionDenied
    case saveFailed(String)
    case interrupted(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Screen recording is unavailable on this device."
        case .alreadyRecording:
            return "A screen recording is already in progress."
        case .notRecording:
            return "There is no screen recording to stop."
        case .operationInProgress:
            return "A recording operation is already in progress."
        case .startFailed(let message):
            return "Could not start recording: \(message)"
        case .stopFailed(let message):
            return "Could not finish recording: \(message)"
        case .photoLibraryPermissionDenied:
            return "Allow photo access in Settings to save recordings."
        case .saveFailed(let message):
            return "Could not save the recording: \(message)"
        case .interrupted(let message):
            return "Recording stopped unexpectedly: \(message)"
        }
    }
}

@MainActor
protocol ScreenRecording: AnyObject {
    var onUnexpectedStop: ((ScreenRecordingError) -> Void)? { get set }

    func start(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void)
    func stopAndSave(completion: @escaping (Result<Void, ScreenRecordingError>) -> Void)
}
