//
//  CrashViewController.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/11/25.
//

import UIKit

final class CrashViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .random
        
        // CRASH: [unowned self] + async work after screen dismissal
        // Self is captured as unowned at Task creation, but deallocated when popped.
        // Accessing unowned reference after deallocation = crash
        Task { [unowned self] in
            print("In Task")
            navigationController?.popViewController(animated: true)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
            print("Accessing self: \(self)")  // Crash here - self is deallocated
        }
        
        // SAFE but MEMORY LEAK: [weak self] with strong reference via guard let
        // Guard let creates strong reference to self, keeping VC in memory until Task completes.
        // VC is popped but not deallocated - remains in memory for 1 second unnecessarily
//        Task { [weak self] in
//            guard let self else { return }
//            print("In Task")
//            navigationController?.popViewController(animated: true)
//            try? await Task.sleep(nanoseconds: 1_000_000_000)
//            print("Accessing self: \(self)")
//        }
    }
}
