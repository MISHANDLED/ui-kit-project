# Base Layer Architecture

Generic protocol-driven MVVM for UIKit screens. Each screen is a `BaseViewController` generic over a concrete `View` type; the view is generic over a concrete `ViewModel` type. The compiler resolves all three types at the call site — no casting, no runtime surprises.

---

## Layer Diagram

```
BaseViewModel (protocol)           ← lifecycle contract for all ViewModels
    └── ScreenDataSource (protocol) ← screen-specific VM contract
            └── ConcreteViewModel  ← real or mock implementation

BaseView (protocol)                ← binding contract for all Views
    └── ScreenView<VM: ScreenDataSource>  ← generic UIView subclass

BaseViewController<ContentView: BaseView>
    └── pinned at call site:
        BaseViewController<ScreenView<ConcreteViewModel>>
```

---

## Why the Naive Generic Syntax Fails

Before reaching for `associatedtype`, you'd naturally try to express the view↔VM relationship inline:

```swift
// ❌ Swift doesn't allow nested generic constraints
class BaseViewController<T: BaseView<V: ViewModel>> { }

// ❌ Can't parameterize a protocol like a generic class
class BaseViewController<T: BaseView<SomeVM>> { }
```

Swift generic constraints only go one level deep in a declaration. The fix: declare the VM type via `associatedtype` on the view protocol so the compiler infers it from the view type — one generic parameter carries both.

---

## Why Views Must Also Be Generic

A view with a fixed ViewModel alias is permanently coupled:

```swift
// ❌ Concrete alias — CounterView can NEVER be used with any other VM
final class CounterView: UIView, BaseView {
    typealias ViewModel = CounterViewModel
}
```

If two screens share the same layout but have different behavior (e.g. bounded vs unbounded counter), you're forced to either subclass the view or duplicate it. Making the view generic over its VM breaks that coupling:

```swift
// ✅ Generic — VM is a parameter, not a fixed type
class CounterView<VM: CounterDataSource>: UIView { }
```

Same view class, different behavior, chosen at the call site by the VM type.

---

## Why Not Simple Inheritance

### The inheritance trap

```swift
// ❌ Inheritance — looks clean, breaks fast
class CounterViewController: UIViewController {
    let view = CounterView()
    let viewModel = CounterViewModel()
}
```

Problems:

| Problem | What happens |
|---------|-------------|
| **Hardcoded types** | `CounterView` and `CounterViewModel` are baked in. Testing requires subclassing or swizzling. |
| **Shared base bloat** | Every screen that inherits a base VC gets its full API surface — layout helpers, nav helpers, analytics hooks — whether it needs them or not. |
| **Fragile overrides** | `override viewDidLoad()` must call `super` at the right point. Miss it once, bug is silent. |
| **No compiler enforcement** | Nothing stops `LoginViewController` from holding a `CounterViewModel`. |
| **Mock injection requires subclassing** | To test with a mock VM you must subclass the VC and override a factory method. |

### What generics give you instead

```swift
// ✅ Generic — types enforced at compile time
let vc = BaseViewController(contentView: CounterView(), viewModel: BasicCounterViewModel())
// ❌ This won't compile — LoginViewModel doesn't conform to CounterDataSource
let bad = BaseViewController(contentView: CounterView(), viewModel: LoginViewModel())
```

- Swap the VM → different behavior, zero view changes.
- Inject a mock VM → test without a single subclass.
- The base VC has no screen-specific API. No bloat, no fragile overrides.

---

## Core Protocols

### `BaseViewModel`
```swift
protocol BaseViewModel: AnyObject {
    func viewDidLoad()
}
```
All ViewModels conform to this. `BaseViewController` calls `viewModel.viewDidLoad()` after binding — no casting, guaranteed by the constraint.

### `BaseView`
```swift
protocol BaseView: UIView {
    associatedtype ViewModel: BaseViewModel
    func bind(to viewModel: ViewModel)
}
```
Views declare what they need via `associatedtype ViewModel`. The constraint `ViewModel: BaseViewModel` lets `BaseViewController` call the lifecycle method directly — no `as?` cast, no optionality.

### `BaseViewController`
```swift
class BaseViewController<ContentView: BaseView>: UIViewController {
    let contentView: ContentView
    let viewModel: ContentView.ViewModel

    override func loadView() { view = contentView }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.bind(to: viewModel) // view wires itself to VM
        viewModel.viewDidLoad()         // VM loads data / sets up state
    }
}
```

`ContentView.ViewModel` resolves to the concrete type — fully typed, no existential.

---

## Making a Screen Generic

### Step 1 — DataSource protocol at file scope

```swift
// CounterViewController.swift — TOP LEVEL, not nested inside CounterView
protocol CounterDataSource: BaseViewModel {
    var count: Int { get }
    func increment()
    func decrement()
}
```

> **Rule:** Protocols must be at file scope, not nested inside the view class.
> Generic classes can't have nested types referenced from outside — the compiler rejects it.

### Step 2 — Generic View

```swift
class CounterView<VM: CounterDataSource>: UIView {
    var dataSource: VM?

    // @objc selectors go in the class body — NOT in extensions.
    // Swift forbids @objc in extensions of generic classes.
    @objc private func didTapIncrement() {
        dataSource?.increment()
        updateLabel()
    }
}

extension CounterView: BaseView {
    typealias ViewModel = VM          // concrete, not existential

    func bind(to viewModel: VM) {
        self.dataSource = viewModel
        updateLabel()
    }
}
```

`typealias ViewModel = VM` is satisfied because `VM: CounterDataSource: BaseViewModel` — the chain resolves the constraint.

### Step 3 — Concrete ViewModel

```swift
final class BasicCounterViewModel: CounterDataSource {
    private(set) var count = 0
    func viewDidLoad() {}             // called by BaseViewController automatically
    func increment() { count += 1 }
    func decrement() { count -= 1 }
}
```

### Step 4 — Instantiate

```swift
// Type is fully resolved: BaseViewController<CounterView<BasicCounterViewModel>>
let vc = BaseViewController(contentView: CounterView(), viewModel: BasicCounterViewModel())
```

No subclassing. No casting. The compiler knows the full type.

---

## Swapping ViewModels (Testing / Variants)

```swift
// Different behavior — same view, zero view changes
final class BoundedCounterViewModel: CounterDataSource {
    private let range: ClosedRange<Int>
    private(set) var count: Int
    init(range: ClosedRange<Int> = 0...10) { self.range = range; count = 0 }
    func viewDidLoad() {}
    func increment() { count = min(count + 1, range.upperBound) }
    func decrement() { count = max(count - 1, range.lowerBound) }
}

let boundedVC = BaseViewController(contentView: CounterView(), viewModel: BoundedCounterViewModel(range: 0...5))

// Mock for tests — no XCTest subclassing ceremony
final class MockCounterViewModel: CounterDataSource {
    var count = 0
    var didCallViewDidLoad = false
    func viewDidLoad() { didCallViewDidLoad = true }
    func increment() { count += 1 }
    func decrement() { count -= 1 }
}
```

---

## Subclassing a View

When a screen needs everything the parent view has, plus more, subclass the generic view and narrow the protocol.

```swift
// Narrower protocol — extends parent's contract
protocol ResettableCounterDataSource: CounterDataSource {
    func reset()
}

// Subclass pins the generic to the narrower protocol
final class ResettableCounterView<VM: ResettableCounterDataSource>: CounterView<VM> {

    // @objc in class body — same rule applies to subclasses of generic classes
    @objc private func didTapReset() {
        dataSource?.reset()
        updateLabel()
    }
}
```

The call site is concrete all the way down:

```
BaseViewController<ResettableCounterView<ResettableCounterViewModel>>
```

No casting anywhere in the chain.

---

## Rules Reference

| Rule | Why |
|------|-----|
| Protocols at file scope | Generic classes can't have usable nested types. |
| `@objc` in class body, not extension | Swift forbids `@objc` in extensions of generic classes. |
| One `typealias ViewModel` per class | Duplicate typealiases are a compile error. |
| Generic parameter = swap mechanism | Don't subclass to change behavior — change the VM type. |
| `viewDidLoad()` on VM | Keeps data loading out of the view; BaseViewController calls it automatically after bind. |

---

## What the Compiler Resolves

```
BaseViewController<CounterView<BasicCounterViewModel>>
        │
        ContentView = CounterView<BasicCounterViewModel>
        ContentView.ViewModel = BasicCounterViewModel
        │
        contentView: CounterView<BasicCounterViewModel>   ← concrete UIView
        viewModel:   BasicCounterViewModel                ← concrete class, full API
```

Compared to inheritance where `viewModel` is typed as the base class or protocol, here it is the exact concrete type — every method, every property, no casting.

---

## Extending to Other Containers

The same pattern works for any UIKit container — swap `UIViewController` for the container type:

```swift
// Cells
class BaseTableViewCell<ContentView: BaseView>: UITableViewCell {
    let contentView: ContentView
    let viewModel: ContentView.ViewModel

    func configure() {
        contentView.bind(to: viewModel)
        viewModel.viewDidLoad()
    }
}

// Collection cells, annotation views, etc. — identical concept, different container
```

One pattern, every container. If you understand `BaseViewController`, you already understand `BaseTableViewCell`.

---

## File Structure

```
Base/
├── BaseView.swift                      ← BaseViewModel + BaseView protocols
├── BaseViewController.swift            ← generic base VC
└── Example/
    ├── CounterViewController.swift     ← CounterDataSource + CounterView<VM> + VMs
    └── ResettableCounterViewController.swift  ← subclass example
```
