# TransitionViewProvider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `SearchBarProvider` (single-view) with `TransitionViewProvider` (array of views matched by `tag`) so the hero transition animator is generic.

**Architecture:** Protocol `TransitionViewProvider` exposes `[UIView]`; animator builds `[Int: UIView]` dicts keyed by `tag`, intersects keys, animates matched pairs simultaneously. VCA and VCB each set a shared tag constant on their search bar and return it in the array.

**Tech Stack:** Swift, UIKit, `UIViewControllerAnimatedTransitioning`, `UIPercentDrivenInteractiveTransition`

---

## File Map

| File | Action |
|---|---|
| `UIKitProject/Transition/SearchTransitionAnimator.swift` | Rename protocol + property; rewrite `present()` and `dismiss()` for tag-matched array; update `resolveProvider` return type |
| `UIKitProject/Transition/ViewControllerA.swift` | Set `searchBar.tag`; change conformance to `TransitionViewProvider`; return `[searchBar]` |
| `UIKitProject/Transition/ViewControllerB.swift` | Set `searchBar.tag`; change conformance to `TransitionViewProvider`; return `[searchBar]` |

---

### Task 1: Update `SearchTransitionAnimator.swift`

**Files:**
- Modify: `UIKitProject/Transition/SearchTransitionAnimator.swift`

- [ ] **Step 1: Replace the protocol declaration**

Replace:
```swift
protocol SearchBarProvider: AnyObject {
    var searchBarView: UIView { get }
}
```
With:
```swift
protocol TransitionViewProvider: AnyObject {
    var transitionViews: [UIView] { get }
}
```

- [ ] **Step 2: Rewrite `present(_:)`**

Replace the entire `present(_ context:)` function body:
```swift
func present(_ context: UIViewControllerContextTransitioning) {
    guard
        let fromVC = context.viewController(forKey: .from),
        let toVC = context.viewController(forKey: .to),
        let source = resolveProvider(fromVC),
        let destination = resolveProvider(toVC)
    else { context.completeTransition(false); return }

    let container = context.containerView
    toVC.view.frame = context.finalFrame(for: toVC)
    toVC.view.alpha = 0
    container.addSubview(toVC.view)
    toVC.view.layoutIfNeeded()

    let sourceMap = Dictionary(
        source.transitionViews.map { ($0.tag, $0) },
        uniquingKeysWith: { _, last in last }
    )
    let destMap = Dictionary(
        destination.transitionViews.map { ($0.tag, $0) },
        uniquingKeysWith: { _, last in last }
    )
    let matchedTags = Set(sourceMap.keys).intersection(destMap.keys)

    // Full snapshot of fromVC fades out
    let bgSnapshot = fromVC.view.snapshotView(afterScreenUpdates: false) ?? UIView()
    bgSnapshot.frame = fromVC.view.frame
    container.addSubview(bgSnapshot)

    // Hero snapshots for each matched pair
    var snapshots: [(view: UIView, destFrame: CGRect)] = []
    for tag in matchedTags {
        guard let srcView = sourceMap[tag], let dstView = destMap[tag] else { continue }
        let srcFrame = srcView.convert(srcView.bounds, to: container)
        let dstFrame = dstView.convert(dstView.bounds, to: container)
        let snap = srcView.snapshotView(afterScreenUpdates: false) ?? UIView()
        snap.frame = srcFrame
        container.addSubview(snap)
        dstView.alpha = 0
        snapshots.append((snap, dstFrame))
    }

    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
        bgSnapshot.alpha = 0
        toVC.view.alpha = 1
        snapshots.forEach { $0.view.frame = $0.destFrame }
    } completion: { _ in
        destination.transitionViews.forEach { $0.alpha = 1 }
        bgSnapshot.removeFromSuperview()
        snapshots.forEach { $0.view.removeFromSuperview() }
        context.completeTransition(!context.transitionWasCancelled)
    }
}
```

- [ ] **Step 3: Rewrite `dismiss(_:)`**

Replace the entire `dismiss(_ context:)` function body:
```swift
func dismiss(_ context: UIViewControllerContextTransitioning) {
    guard
        let fromVC = context.viewController(forKey: .from),
        let toVC = context.viewController(forKey: .to),
        let source = resolveProvider(fromVC),
        let destination = resolveProvider(toVC)
    else { context.completeTransition(false); return }

    let container = context.containerView

    let sourceMap = Dictionary(
        source.transitionViews.map { ($0.tag, $0) },
        uniquingKeysWith: { _, last in last }
    )
    let destMap = Dictionary(
        destination.transitionViews.map { ($0.tag, $0) },
        uniquingKeysWith: { _, last in last }
    )
    let matchedTags = Set(sourceMap.keys).intersection(destMap.keys)

    var snapshots: [(view: UIView, destFrame: CGRect)] = []
    for tag in matchedTags {
        guard let srcView = sourceMap[tag], let dstView = destMap[tag] else { continue }
        let srcFrame = srcView.convert(srcView.bounds, to: container)
        // toVC.view not in container with overFullScreen — convert via window to avoid .zero
        let dstFrame = container.convert(dstView.convert(dstView.bounds, to: nil), from: nil)
        let snap = srcView.snapshotView(afterScreenUpdates: false) ?? UIView()
        snap.frame = srcFrame
        srcView.alpha = 0
        container.addSubview(snap)
        snapshots.append((snap, dstFrame))
    }

    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
        fromVC.view.alpha = 0
        snapshots.forEach { $0.view.frame = $0.destFrame }
    } completion: { _ in
        snapshots.forEach { $0.view.removeFromSuperview() }
        if context.transitionWasCancelled {
            fromVC.view.alpha = 1
            source.transitionViews.forEach { $0.alpha = 1 }
        }
        context.completeTransition(!context.transitionWasCancelled)
    }
}
```

- [ ] **Step 4: Update `resolveProvider` return type**

Replace:
```swift
func resolveProvider(_ vc: UIViewController) -> SearchBarProvider? {
    if let nav = vc as? UINavigationController {
        return nav.topViewController as? SearchBarProvider
    }
    return vc as? SearchBarProvider
}
```
With:
```swift
func resolveProvider(_ vc: UIViewController) -> TransitionViewProvider? {
    if let nav = vc as? UINavigationController {
        return nav.topViewController as? TransitionViewProvider
    }
    return vc as? TransitionViewProvider
}
```

- [ ] **Step 5: Verify file builds**

Open `SearchTransitionAnimator.swift` in Xcode and confirm no compiler errors. The file should compile cleanly — `SearchBarProvider` must have zero remaining references.

---

### Task 2: Update `ViewControllerA.swift`

**Files:**
- Modify: `UIKitProject/Transition/ViewControllerA.swift`

- [ ] **Step 1: Add tag constant and set tag during view setup**

Add a private tag enum at the top of the file (before the class declaration):
```swift
private enum HeroTag {
    static let searchBar = 1
}
```

In `createViews()`, after `view.addSubview(searchBar)`, add:
```swift
searchBar.tag = HeroTag.searchBar
```

- [ ] **Step 2: Replace protocol conformance**

Replace:
```swift
extension ViewControllerA: SearchBarProvider {
    var searchBarView: UIView { searchBar }
}
```
With:
```swift
extension ViewControllerA: TransitionViewProvider {
    var transitionViews: [UIView] { [searchBar] }
}
```

- [ ] **Step 3: Verify no remaining `SearchBarProvider` references**

Check the file has zero occurrences of `SearchBarProvider` or `searchBarView`.

---

### Task 3: Update `ViewControllerB.swift`

**Files:**
- Modify: `UIKitProject/Transition/ViewControllerB.swift`

- [ ] **Step 1: Add tag constant and set tag during view setup**

Add the same private tag enum at the top of the file (before the class declaration) — same value so animator matches them:
```swift
private enum HeroTag {
    static let searchBar = 1
}
```

In `createViews()`, after `containerView.addSubview(searchBar)`, add:
```swift
searchBar.tag = HeroTag.searchBar
```

- [ ] **Step 2: Replace protocol conformance**

Replace:
```swift
extension ViewControllerB: SearchBarProvider {
    var searchBarView: UIView { searchBar }
}
```
With:
```swift
extension ViewControllerB: TransitionViewProvider {
    var transitionViews: [UIView] { [searchBar] }
}
```

- [ ] **Step 3: Verify no remaining `SearchBarProvider` references**

Check the file has zero occurrences of `SearchBarProvider` or `searchBarView`.

---

### Task 4: Build and verify

- [ ] **Step 1: Full build**

Build the project (`Cmd+B`). Expected: zero errors, zero warnings related to this change.

- [ ] **Step 2: Manual test — present**

Run the app, tap "Search Transition". Confirm search bar animates from VCA position to VCB position smoothly.

- [ ] **Step 3: Manual test — dismiss (interactive)**

Pan down on VCB's container view. Confirm search bar tracks the gesture and animates back to VCA on release.

- [ ] **Step 4: Manual test — dismiss (cancelled)**

Pan down slightly (< 40% height, slow velocity), release. Confirm transition cancels and VCB stays on screen with search bar restored.
