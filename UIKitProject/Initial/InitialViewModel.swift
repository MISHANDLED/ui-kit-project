//
//  InitialViewModel.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 22/10/25.
//

import Foundation

final class InitialViewModel: InitialController.DataSource {
    let cells: [InitialController.CellType] = [
        .panGesture,
        .pageViewController,
        .properyAnimator,
        .crashSimulator,
        .miniPlayer,
        .htmlViewer,
        .datePicker,
        .transition
    ]
    
    var numberOfSections: Int { 1 }
    
    func numberOfRows(in section: Int) -> Int {
        cells.count
    }
    
    func dataSource(for indexPath: IndexPath) -> InitialController.CellType {
        cells[indexPath.row]
    }
}
