//
//  FrameRecursion.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 03/11/25.
//

import UIKit

final class FrameRecursion: UIViewController {
    var actual: Int = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func helper(_ parentView: UIView, n: Int) {
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

