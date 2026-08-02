//
//  AppNavigationAction.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
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
