//
//  BaseView.swift
//  UIKitProject
//

import UIKit

@MainActor
protocol BaseViewModel: AnyObject {
    func viewDidLoad()
}

extension BaseViewModel {
    func viewDidLoad() {}
}

@MainActor
protocol BaseView: UIView {
    associatedtype ViewModel: BaseViewModel
    init(frame: CGRect)
    func bind(to viewModel: ViewModel)
}
