//
//  RecordingOverlayView.swift
//  UIKitProject
//

import UIKit

@MainActor
final class RecordingOverlayView: UIView, BaseView {
    typealias ViewModel = RecordingOverlayViewModel

    private enum Layout {
        static let buttonSize: CGFloat = 56
        static let edgeInset: CGFloat = 16
    }

    private let recordButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(to viewModel: RecordingOverlayViewModel) {
        recordButton.addAction(
            UIAction { [weak viewModel] _ in
                viewModel?.toggleRecording()
            },
            for: .touchUpInside
        )

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func configureView() {
        backgroundColor = .clear

        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.layer.cornerRadius = Layout.buttonSize / 2
        recordButton.layer.borderWidth = 1
        recordButton.layer.shadowColor = UIColor.black.cgColor
        recordButton.layer.shadowOpacity = 0.25
        recordButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        recordButton.layer.shadowRadius = 6
        recordButton.accessibilityTraits = .button
        recordButton.accessibilityHint = "Double-tap to start screen recording."
        recordButton.isPointerInteractionEnabled = true

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.isUserInteractionEnabled = false

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .label
        statusLabel.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.masksToBounds = true
        statusLabel.numberOfLines = 2
        statusLabel.isHidden = true
        statusLabel.isUserInteractionEnabled = false

        addSubview(recordButton)
        addSubview(statusLabel)
        recordButton.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            recordButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: Layout.edgeInset
            ),
            recordButton.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -Layout.edgeInset
            ),
            recordButton.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            recordButton.heightAnchor.constraint(equalTo: recordButton.widthAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            statusLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -Layout.edgeInset
            ),
            statusLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 240)
        ])

        render(.idle)
    }

    private func render(_ state: RecordingOverlayViewState) {
        recordButton.layer.removeAnimation(forKey: "recordingPulse")
        recordButton.isEnabled = true
        activityIndicator.stopAnimating()
        statusLabel.isHidden = true
        statusLabel.text = nil

        switch state {
        case .idle:
            applyButtonStyle(
                imageName: "record.circle.fill",
                foregroundColor: .systemRed,
                backgroundColor: .secondarySystemBackground
            )
            recordButton.accessibilityLabel = "Start screen recording"
            recordButton.accessibilityValue = "Not recording"
            recordButton.accessibilityHint = "Double-tap to start screen recording."

        case .starting:
            applyBusyStyle(label: "Starting screen recording")
            recordButton.accessibilityValue = "Starting"

        case .recording:
            applyButtonStyle(
                imageName: "stop.fill",
                foregroundColor: .white,
                backgroundColor: .systemRed
            )
            recordButton.accessibilityLabel = "Stop screen recording"
            recordButton.accessibilityValue = "Recording"
            recordButton.accessibilityHint = "Double-tap to stop and save the recording."
            addRecordingPulse()

        case .saving:
            applyBusyStyle(label: "Saving screen recording")
            recordButton.accessibilityValue = "Saving"

        case .saved:
            applyButtonStyle(
                imageName: "checkmark",
                foregroundColor: .white,
                backgroundColor: .systemGreen
            )
            showStatus("  Saved to Photos  ")
            recordButton.accessibilityLabel = "Screen recording saved"
            recordButton.accessibilityValue = "Saved"
            recordButton.accessibilityHint = "Double-tap to start another recording."

        case .failed(let message):
            applyButtonStyle(
                imageName: "exclamationmark",
                foregroundColor: .white,
                backgroundColor: .systemOrange
            )
            showStatus("  \(message)  ")
            recordButton.accessibilityLabel = "Screen recording failed"
            recordButton.accessibilityValue = message
            recordButton.accessibilityHint = "Double-tap to try again."
        }
    }

    private func applyBusyStyle(label: String) {
        applyButtonStyle(
            imageName: nil,
            foregroundColor: .white,
            backgroundColor: .systemGray
        )
        recordButton.isEnabled = false
        recordButton.accessibilityLabel = label
        recordButton.accessibilityHint = nil
        activityIndicator.startAnimating()
    }

    private func applyButtonStyle(
        imageName: String?,
        foregroundColor: UIColor,
        backgroundColor: UIColor
    ) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let image = imageName.flatMap {
            UIImage(systemName: $0, withConfiguration: configuration)
        }

        recordButton.setImage(image, for: .normal)
        recordButton.tintColor = foregroundColor
        recordButton.backgroundColor = backgroundColor
        recordButton.layer.borderColor = UIColor.separator.cgColor
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.isHidden = false
    }

    private func addRecordingPulse() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.08
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        recordButton.layer.add(animation, forKey: "recordingPulse")
    }
}
