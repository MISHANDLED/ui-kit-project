//
//  AppNavigationAction.swift
//  UIKitProject
//

import CoreGraphics

enum SearchDismissalInteraction: Equatable {
    case began
    case changed(progress: CGFloat)
    case finished
    case cancelled
}

enum AppNavigationAction: Equatable {
    case navigate(to: AppRoute)
    case goBack
    case searchDismissal(SearchDismissalInteraction)
}
