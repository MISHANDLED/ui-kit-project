//
//  BaseViewController.swift
//  UIKitProject
//

import UIKit

class BaseViewController<ContentView: BaseView>: UIViewController {
    
    let contentView: ContentView
    let viewModel: ContentView.ViewModel
    
    init(contentView: ContentView, viewModel: ContentView.ViewModel) {
        self.contentView = contentView
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.bind(to: viewModel)
        viewModel.viewDidLoad()
    }
}
