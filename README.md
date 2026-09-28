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

## Utilities

- **App recording overlay** — app-level pass-through window with a floating record/stop button; ReplayKit writes the movie and Photos saves it
- **FloatingView** — pill FAB that collapses/expands on scroll using `UIViewPropertyAnimator`
- **TrackingWindow / TouchOverlayWindow** — touch path visualizer with gradient trail, crosshair, and coordinate HUD
- **GenericNotificationCenter** — Combine-based `NotificationCenter` replacement using `PassthroughSubject` + associated objects
- **Shimmer effects** — three progressively refined shimmer implementations (horizontal strip → diagonal sweep)

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Swift 6 language mode

No external dependencies.

## Architecture

- `AppCoordinator` is the only owner of app-level push, pop, present, and dismiss operations.
- View models emit typed `AppRoute` or `AppNavigationAction` values and never construct view controllers.
- `AppScreenFactory` is the composition boundary that pins generic view/view-model types and returns `UIViewController`.
- `DeepLinkHandler` validates external URLs and converts them into the same routes used by in-app navigation.
- `SceneDelegate` retains one coordinator for its `UIWindowScene` and forwards cold-start and warm-start URLs.
- The same coordinator installs the recording overlay window; touches outside its button pass through to the current screen.

## Deep links

The registered custom scheme can be exercised in Simulator:

```sh
xcrun simctl openurl booted 'uikitproject://open/pan'
xcrun simctl openurl booted 'uikitproject://open/pages?index=12'
xcrun simctl openurl booted 'uikitproject://open/mini-player'
```

Universal-link parsing is supported for hosts listed in the `UniversalLinkHosts` array in `Info.plist`. Delivering those links from iOS also requires the Associated Domains capability and a matching `apple-app-site-association` file for the chosen domain.
