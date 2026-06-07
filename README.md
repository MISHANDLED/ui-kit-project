# UIKitProject

Personal iOS sandbox for experimenting with UIKit APIs and patterns. Programmatic UI only — no Storyboards (except LaunchScreen).

## Features

| Screen | Description |
|---|---|
| **Pan Gesture** | Draggable square that snaps to nearest corner on release |
| **Page View Controller** | 100-page `UIPageViewController` with LRU cache (±5 pages) |
| **Property Animator** | Slider-scrubbed `UIViewPropertyAnimator` — scale + position |
| **Simulate Crash** | Educational `[unowned self]` crash demo inside an async `Task` |
| **Mini Player** | `AVPlayer` with aspect-correct layout, animates small → fullscreen |
| **HTML Viewer** | `WKWebView` + HTML → PDF generation via `UIPrintPageRenderer` |
| **Date Picker** | Toggle-visible `UIDatePicker` (wheels style) |

## Utilities

- **FloatingView** — pill FAB that collapses/expands on scroll using `UIViewPropertyAnimator`
- **TrackingWindow / TouchOverlayWindow** — touch path visualizer with gradient trail, crosshair, and coordinate HUD
- **GenericNotificationCenter** — Combine-based `NotificationCenter` replacement using `PassthroughSubject` + associated objects
- **Shimmer effects** — three progressively refined shimmer implementations (horizontal strip → diagonal sweep)

## Requirements

- iOS 16+
- Xcode 15+
- Swift 5.9+

No external dependencies.