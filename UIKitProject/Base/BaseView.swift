//
//  BaseView.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 09/06/26.
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
