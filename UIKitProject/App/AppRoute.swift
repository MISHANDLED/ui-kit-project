//
//  AppRoute.swift
//  UIKitProject
//

enum AppRoute: Hashable {
    case home
    case panGesture
    case page(index: Int?)
    case propertyAnimator
    case crashSimulator
    case miniPlayer
    case htmlViewer
    case searchTransition
    case searchDestination
}

enum NavigationSource {
    case user
    case deepLink
}
