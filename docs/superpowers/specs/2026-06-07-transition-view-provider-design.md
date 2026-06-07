# TransitionViewProvider Design

**Date:** 2026-06-07  
**Scope:** Rename `SearchBarProvider` → `TransitionViewProvider`, change single-view property to tag-matched array

---

## Goal

Decouple the hero transition animator from search-bar-specific knowledge. Any VC can participate in multi-view hero transitions by conforming to `TransitionViewProvider` and tagging its views.

---

## Protocol

```swift
protocol TransitionViewProvider: AnyObject {
    var transitionViews: [UIView] { get }
}
```

Replaces `SearchBarProvider` and its `searchBarView: UIView` property.

---

## Tag Contract

- Each view in `transitionViews` must have a unique non-zero `tag`.
- Source and destination VCs use the same tag constants so the animator can pair them.
- Views with no matching tag on the other side are skipped silently.
- Both VCs are responsible for setting tags before returning views.

Tag constants live as file-private `enum` in each VC file (no shared file needed — both VCs are in the same `Transition/` group and the values just need to agree).

---

## Animator — Tag Matching

**Present:**
1. Call `toVC.view.layoutIfNeeded()` (existing fix — unchanged).
2. Build `[Int: UIView]` from `source.transitionViews`, keyed by `view.tag`.
3. Build `[Int: UIView]` from `destination.transitionViews`, keyed by `view.tag`.
4. Intersect keys to get matched pairs.
5. For each pair:
   - Capture source frame (convert bounds to container).
   - Capture dest frame (convert bounds to container).
   - Snapshot source view, place at source frame, add to container.
   - Hide dest view (`alpha = 0`).
6. Animate all snapshots to their dest frames simultaneously (single `UIView.animate` block).
7. Completion: restore dest view alphas, remove snapshots.

**Dismiss:**
Same logic reversed. Dest frame for `toVC` views resolved via window coordinates (existing fix — unchanged):
```swift
container.convert(destBar.convert(destBar.bounds, to: nil), from: nil)
```

**Unmatched views:** silently ignored in both directions.

---

## Files Changed

| File | Change |
|---|---|
| `SearchTransitionAnimator.swift` | Rename protocol, update property, rewrite present/dismiss to handle matched pairs |
| `ViewControllerA.swift` | Conform to `TransitionViewProvider`, set tag on `searchBar`, return `[searchBar]` |
| `ViewControllerB.swift` | Conform to `TransitionViewProvider`, set tag on `searchBar`, return `[searchBar]` |

No other files change.

---

## Error Handling

- Empty `transitionViews` on either side → no hero animation, transition still completes.
- Tag collision within one VC's array → last view with that tag wins (dict overwrite). Caller's responsibility to use unique tags.
- `snapshotView` returns `nil` → fallback to empty `UIView()` (existing behavior unchanged).
