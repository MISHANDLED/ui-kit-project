//
//  BaseView.swift
//  UIKitProject
//

import UIKit

protocol BaseViewModel: AnyObject {
    func viewDidLoad()
}

protocol BaseView: UIView {
    associatedtype ViewModel: BaseViewModel
    func bind(to viewModel: ViewModel)
}
