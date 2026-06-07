//
//  SearchTransitionAnimator.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/06/26.
//

import UIKit

// MARK: - Protocol
protocol TransitionViewProvider: AnyObject {
    var transitionViews: [UIView] { get }
}

// MARK: - Animator
final class SearchTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    private let duration: TimeInterval = 0.35
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval { duration }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        isPresenting ? present(context) : dismiss(context)
    }
}

// MARK: - Present / Dismiss
private extension SearchTransitionAnimator {
    
    func present(_ context: UIViewControllerContextTransitioning) {
        guard
            let fromVC = context.viewController(forKey: .from),
            let toVC = context.viewController(forKey: .to),
            let source = fromVC.resolveTransitionViewProvider(),
            let destination = toVC.resolveTransitionViewProvider()
        else { context.completeTransition(false); return }
        
        let container = context.containerView
        toVC.view.frame = context.finalFrame(for: toVC)
        toVC.view.alpha = 0
        container.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()
        
        // container covers VCA entirely (overFullScreen) — white background hides window behind
        container.backgroundColor = .white
        
        var zeroedSrcViews: [UIView] = []
        var zeroedDestViews: [UIView] = []
        var snapshots: [(view: UIView, destFrame: CGRect)] = []
        for pair in source.matchedPairs(with: destination) {
            let srcFrame = pair.srcView.convert(pair.srcView.bounds, to: container)
            let dstFrame = pair.dstView.convert(pair.dstView.bounds, to: container)
            let snap = pair.srcView.snapshotView(afterScreenUpdates: false) ?? UIView()
            snap.frame = srcFrame
            container.addSubview(snap)
            pair.srcView.alpha = 0
            pair.dstView.alpha = 0
            zeroedSrcViews.append(pair.srcView)
            zeroedDestViews.append(pair.dstView)
            snapshots.append((snap, dstFrame))
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            toVC.view.alpha = 1
            snapshots.forEach { $0.view.frame = $0.destFrame }
        } completion: { _ in
            zeroedSrcViews.forEach { $0.alpha = 1 }
            zeroedDestViews.forEach { $0.alpha = 1 }
            snapshots.forEach { $0.view.removeFromSuperview() }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
    
    func dismiss(_ context: UIViewControllerContextTransitioning) {
        guard
            let fromVC = context.viewController(forKey: .from),
            let toVC = context.viewController(forKey: .to),
            let source = fromVC.resolveTransitionViewProvider(),
            let destination = toVC.resolveTransitionViewProvider()
        else {
            context.completeTransition(false)
            return
        }
        
        let container = context.containerView
        
        var zeroedSrcViews: [UIView] = []
        var zeroedDestViews: [UIView] = []
        var snapshots: [(view: UIView, destFrame: CGRect)] = []
        for pair in source.matchedPairs(with: destination) {
            let srcFrame = pair.srcView.convert(pair.srcView.bounds, to: container)
            // toVC.view not in container with overFullScreen — convert via window to avoid .zero
            let dstFrame = container.convert(pair.dstView.convert(pair.dstView.bounds, to: nil), from: nil)
            let snap = pair.srcView.snapshotView(afterScreenUpdates: false) ?? UIView()
            snap.frame = srcFrame
            pair.srcView.alpha = 0
            pair.dstView.alpha = 0
            zeroedSrcViews.append(pair.srcView)
            zeroedDestViews.append(pair.dstView)
            container.addSubview(snap)
            snapshots.append((snap, dstFrame))
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            fromVC.view.alpha = 0
            snapshots.forEach { $0.view.frame = $0.destFrame }
        } completion: { _ in
            zeroedDestViews.forEach { $0.alpha = 1 }
            snapshots.forEach { $0.view.removeFromSuperview() }
            if context.transitionWasCancelled {
                fromVC.view.alpha = 1
                zeroedSrcViews.forEach { $0.alpha = 1 }
            }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
    
}

// MARK: - Transition Delegate
final class SearchTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    private(set) var interactiveTransition: UIPercentDrivenInteractiveTransition?
    
    func beginInteraction() {
        interactiveTransition = UIPercentDrivenInteractiveTransition()
        interactiveTransition?.completionCurve = .easeInOut
    }
    
    func updateInteraction(_ percent: CGFloat) { interactiveTransition?.update(percent) }
    func finishInteraction() { interactiveTransition?.finish(); interactiveTransition = nil }
    func cancelInteraction() { interactiveTransition?.cancel(); interactiveTransition = nil }
    
    func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        SearchTransitionAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SearchTransitionAnimator(isPresenting: false)
    }
    
    func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransition
    }
}

// MARK: - UIViewController + TransitionViewProvider
extension UIViewController {
    func resolveTransitionViewProvider() -> TransitionViewProvider? {
        if let nav = self as? UINavigationController {
            return nav.topViewController as? TransitionViewProvider
        }
        return self as? TransitionViewProvider
    }
}

// MARK: - TransitionViewProvider + Hero Pairs
extension TransitionViewProvider {
    func matchedPairs(with other: TransitionViewProvider) -> [(srcView: UIView, dstView: UIView)] {
        let sourceMap = Dictionary(
            transitionViews.map { ($0.tag, $0) },
            uniquingKeysWith: { _, last in last }
        )
        let destMap = Dictionary(
            other.transitionViews.map { ($0.tag, $0) },
            uniquingKeysWith: { _, last in last }
        )
        return Set(sourceMap.keys).intersection(destMap.keys).compactMap { tag in
            guard let src = sourceMap[tag], let dst = destMap[tag] else { return nil }
            return (src, dst)
        }
    }
}
