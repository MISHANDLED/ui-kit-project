//
//  UITableView.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 22/10/25.
//

import UIKit

extension UITableView {
    func register(_ cell: UITableViewCell.Type) {
        let reuseIdentifier = String(describing: cell)
        register(cell, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeue<T: UITableViewCell>(_ cell: T.Type) -> T? {
        let reuseIdentifier = String(describing: cell)
        return dequeueReusableCell(withIdentifier: reuseIdentifier) as? T
    }
    
    func dequeue<T: UITableViewCell>(_ cell: T.Type, indexPath: IndexPath) -> T? {
        let reuseIdentifier = String(describing: cell)
        return dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? T
    }
}
