//
//  AppRoute.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

enum AppRoute: Hashable {
    case home
    case panGesture
    case page(index: Int?)
    case propertyAnimator
    case crashSimulator
    case miniPlayer
    case htmlViewer
    case wheelCollectionLayout
    case searchTransition
    case searchDestination
}

enum NavigationSource {
    case user
    case deepLink
}
