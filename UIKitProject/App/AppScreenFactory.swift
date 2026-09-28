//
//  AppScreenFactory.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

import UIKit

@MainActor
protocol AppScreenBuilding {
    func makeViewController(
        for route: AppRoute,
        onAction: @escaping (AppNavigationAction) -> Void
    ) -> UIViewController
}

@MainActor
struct AppScreenFactory: AppScreenBuilding {
    func makeViewController(
        for route: AppRoute,
        onAction: @escaping (AppNavigationAction) -> Void
    ) -> UIViewController {
        switch route {
        case .home:
            let viewModel = InitialViewModel()
            viewModel.onNavigate = { route in
                onAction(.navigate(to: route))
            }
            return InitialViewController(
                contentView: InitialView(),
                viewModel: viewModel
            )

        case .panGesture:
            return BaseViewController(
                contentView: PanView<PanViewModel>(),
                viewModel: PanViewModel()
            )

        case .page(let index):
            return PagingViewController.createSample(initialPage: index)

        case .propertyAnimator:
            return BaseViewController(
                contentView: UIPropertyAnimatorView<UIPropertyAnimatorViewModel>(),
                viewModel: UIPropertyAnimatorViewModel()
            )

        case .crashSimulator:
            return makeCrashViewController {
                onAction(.goBack)
            }

        case .miniPlayer:
            return BaseViewController(
                contentView: AVPlayerContainerView<AVPlayerContainerViewModel>(),
                viewModel: AVPlayerContainerViewModel()
            )

        case .htmlViewer:
            return makePDFRenderer()

        case .wheelCollectionLayout:
            return WheelCollectionViewController()

        case .searchTransition:
            return ViewControllerA {
                onAction(.navigate(to: .searchDestination))
            }

        case .searchDestination:
            return ViewControllerB { interaction in
                onAction(.searchDismissal(interaction))
            }
        }
    }
}
