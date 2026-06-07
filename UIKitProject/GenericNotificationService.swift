//
//  GenericNotificationService.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 06/06/26.
//

import Foundation
import Combine

// MARK: - Generic NotificationCenter
class GenericNotificationCenter {
    
    static let shared = GenericNotificationCenter()
    
    private var subjects: [String: PassthroughSubject<Any?, Never>] = [:]
    private let lock = NSLock()
    private var associatedObjectKey: UInt8 = 0
    
    private init() {}
    
    // MARK: - Get or Create Subject
    private func subject(for name: String) -> PassthroughSubject<Any?, Never> {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = subjects[name] {
            return existing
        }
        
        let newSubject = PassthroughSubject<Any?, Never>()
        subjects[name] = newSubject
        return newSubject
    }
    
    // MARK: - Post
    func post(_ name: String, payload: Any? = nil) {
        subject(for: name).send(payload)
    }
    
    // MARK: - Subscribe with Selector
    func addObserver(_ observer: AnyObject, selector: Selector, name: String) {
        let cancellable = subject(for: name)
            .receive(on: DispatchQueue.main)
            .sink { [weak observer] payload in
                guard let observer else { return }
                _ = (observer as AnyObject).perform(selector, with: payload)
            }
        
        storeCancellable(cancellable, for: observer)
    }
    
    // MARK: - Subscribe with Closure
    func addObserver(_ observer: AnyObject, name: String, handler: @escaping (Any?) -> Void) {
        let cancellable = subject(for: name)
            .receive(on: DispatchQueue.main)
            .sink { [weak observer] payload in
                guard observer != nil else { return }
                handler(payload)
            }
        
        storeCancellable(cancellable, for: observer)
    }
    
    // MARK: - Remove Observer
    func removeObserver(_ observer: AnyObject) {
        objc_setAssociatedObject(
            observer,
            &associatedObjectKey,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    // MARK: - Helper
    private func storeCancellable(_ cancellable: AnyCancellable, for observer: AnyObject) {
        var cancellables: [AnyCancellable] = objc_getAssociatedObject(
            observer,
            &associatedObjectKey
        ) as? [AnyCancellable] ?? []
        
        cancellables.append(cancellable)
        
        objc_setAssociatedObject(
            observer,
            &associatedObjectKey,
            cancellables,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
