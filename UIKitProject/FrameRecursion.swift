//
//  FrameRecursion.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 03/11/25.
//

import UIKit

protocol FrameRecursionViewDataSource: BaseViewModel {
    var depth: Int { get }
}

final class FrameRecursionViewModel: FrameRecursionViewDataSource {
    let depth: Int
    
    init(depth: Int = 5) {
        self.depth = depth
    }
}

final class FrameRecursionView<VM: FrameRecursionViewDataSource>: UIView {
    var actual: Int = 5
    private var hasRendered = false
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        render()
    }
}

extension FrameRecursionView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {
        actual = viewModel.depth
    }
}

extension FrameRecursionView {
    func render() {
        guard !hasRendered else { return }
        hasRendered = true
        helper(self, n: 0)
    }
    
    private func helper(_ parentView: UIView, n: Int) {
        guard n < actual else { return }
        
        let view1 = UIView()
        let view2 = UIView()
        
        parentView.addSubview(view1)
        parentView.addSubview(view2)
        
        view1.frame = .init(x: parentView.bounds.minX, y: parentView.bounds.minY, width: parentView.bounds.width / 2, height: parentView.bounds.height / 2)
        view2.frame = .init(x: parentView.bounds.midX, y: parentView.bounds.midY, width: parentView.bounds.width / 2, height: parentView.bounds.height / 2)
        
        helper(view1, n: n+1)
        helper(view2, n: n+1)
    }
}
