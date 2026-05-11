# BoneToast

A modern, protocol-based toast notification system for SwiftUI with support for iOS 26 liquid glass effects, dynamic SF Symbol animations, phase-based state management, and flexible presentation options.

## Features

- **Protocol-based architecture** - Extensible system allowing custom toast types
- **iOS 26 liquid glass effect** - Beautiful translucent material with graceful fallback
- **Phase-based completable toasts** - Pending → Active → Success/Failure lifecycle
- **SF Symbol transitions** - Smooth `.replace` animations between phases
- **Multiple toast types** - Standard, Progress, and Activity toasts (with multiple indicator styles)
- **Per-phase styling** - Configure background, text, and symbols for each phase
- **Action buttons** - Optional trailing buttons with per-phase configuration
- **Toast pinning** - Keep important toasts visible while others come and go
- **Configurable animations** - Preset configs (bounce, slide, scale, fade, pop, snappy) or custom
- **Global & scoped toasts** - Window-based or overlay-based presentation
- **Interactive dismissal** - Tap/swipe to dismiss with configurable behavior
- **Pause-on-press** - Auto-dismiss timer pauses while the user holds a toast
- **Background interaction control** - Optionally turn a toast into a lightweight modal that blocks taps outside it, with transparent or dimmed scrim
- **Awaitable dismiss** - `async` dismiss APIs that wait for the exit animation, so follow-up modal presentations don't clobber the transition
- **Subtitle support** - Optional subtitles with independent styling

## Quick Start

### Global Toasts (Recommended)

Show toasts from anywhere - SwiftUI views, UIKit, AppDelegate, background tasks.

```swift
// Simple notifications
BoneToastManager.show(StandardToast.success("Item saved!"))
BoneToastManager.show(StandardToast.error("Something went wrong"))

// Progress tracking
let progress = BoneToastManager.show(ProgressToast("Downloading..."))
progress.progress = 0.5
progress.progress = 1.0  // Auto-completes

// Indeterminate activity (pulsing dots)
let activity = BoneToastManager.show(ActivityToast("Processing..."))
// Later...
activity.complete(message: "Done!")

// Network activity (rotating circle)
let network = BoneToastManager.show(ActivityToast("Connecting...", style: .network))
network.complete(message: "Connected!")
```

### Scoped Toasts (For Modals/Sheets)

This toast presentation style is more niche, but included for anyone who may find it useful. This scopes toasts to the view/window that they are presented from. Hence they will appear from the top of that window, however it is positioned. Their lifecycle is also determined by the life of the window, so if the window is dismissed, the toast will also be dismissed.

```swift
struct ModalView: View {
    @State private var manager = BoneToastManager()

    var body: some View {
        VStack {
            Button("Show Toast") {
                manager.show(StandardToast.success("Saved!"))
            }
        }
        .scopedToastContainer(manager: manager)
    }
}
```

---

## Toast Types

### StandardToast

A simple, fire-and-forget toast for notifications.

```swift
// Static factories
BoneToastManager.show(StandardToast.success("Saved!"))
BoneToastManager.show(StandardToast.error("Failed"))
BoneToastManager.show(StandardToast.warning("Check connection"))
BoneToastManager.show(StandardToast.info("Update available"))

// Custom configuration
BoneToastManager.show(StandardToast(
    "Custom message",
    systemImage: "star.fill",
    backgroundStyle: .glass(tintColor: .purple),
    position: .bottom
))

// With subtitle
BoneToastManager.show(StandardToast(
    text: BoneToast.TextConfig(
        title: "Download Complete",
        subtitle: "report.pdf saved to Downloads"
    ),
    systemImage: "arrow.down.circle.fill",
    backgroundStyle: .glass(tintColor: .blue)
))

// With action button
BoneToastManager.show(StandardToast(
    "Message deleted",
    systemImage: "trash",
    actionButton: BoneToast.ActionButton("Undo") {
        // Handle undo
    }
))
```

### ProgressToast

Displays progress (0.0 to 1.0) with a filling circle symbol. Auto-completes when progress reaches 1.0.

```swift
// Basic usage
let toast = BoneToastManager.show(ProgressToast("Downloading..."))
toast.progress = 0.25
toast.progress = 0.5
toast.progress = 1.0  // Auto-completes with success

// With pending phase (waits for start())
let toast = ProgressToast(
    "Downloading...",
    pendingConfig: ToastPhaseConfig(title: "Connecting to server...")
)
BoneToastManager.show(toast)
// Toast shows "Connecting to server..." with pulse animation
// Later...
toast.start()  // Transitions to active phase
toast.progress = 0.5

// Without pending phase
let toast = ProgressToast("Uploading...", pendingConfig: nil)

// Manual completion
toast.complete(message: "Complete!")

// Handle failure
toast.fail(message: "Download failed")

// Full configuration
let toast = ProgressToast(
    "Uploading...",
    backgroundStyle: .glass(tintColor: .blue),
    font: .system(size: 16, weight: .semibold),
    fontColor: .white,
    position: .top,
    pendingConfig: ToastPhaseConfig(title: "Preparing..."),
    successConfig: ToastPhaseConfig(
        title: "Upload complete!",
        backgroundStyle: .glass(tintColor: .green)
    ),
    failureConfig: ToastPhaseConfig(
        title: "Upload failed",
        backgroundStyle: .glass(tintColor: .red)
    ),
    dismissDelayAfterCompletion: 2.0,
    cornerStyle: .capsule
)
```

**ProgressToast Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `progress` | `Double` | Progress value (0.0-1.0). Setting > 0 auto-starts, reaching 1.0 auto-completes |
| `message` | `String` | Current display message |
| `isSuccess` | `Bool` | Whether completed successfully |
| `isFailed` | `Bool` | Whether failed |
| `phase` | `BoneToast.Phase` | Current phase (pending/active/success/failure) |
| `interactive` | `Bool` | Whether tap/swipe dismissal is enabled (default: false) |

### ActivityToast

Indeterminate activity indicator with configurable indicator styles.

**Indicator Styles:**

| Style | Description |
|-------|-------------|
| `.standard` | Pulsing dots using `progress.indicator` with variableColor animation (default) |
| `.network(variableValue:rotateSpeed:)` | Rotating partial-fill circle, ideal for network operations. Both parameters are optional and default to internal sensible values |
| `.custom(...)` | Custom symbol with configurable effect (variableColor, rotate, pulse, breathe, bounce, scale, wiggle, none) |

```swift
// Standard pulsing indicator (default)
let toast = BoneToastManager.show(ActivityToast("Processing..."))
toast.complete(message: "Done!")

// Network-style rotating indicator (uses default fill / speed)
let toast = BoneToastManager.show(ActivityToast("Connecting...", style: .network()))
toast.complete(message: "Connected!")

// Network-style with custom fill and rotation speed
let toast = ActivityToast(
    "Syncing…",
    style: .network(variableValue: 0.5, rotateSpeed: 2.0)
)

// Custom indicator
let toast = ActivityToast(
    "Syncing...",
    style: .custom(symbol: "arrow.triangle.2.clockwise", effect: .rotate(speed: 1.5))
)

// With pending phase
let toast = ActivityToast(
    "Processing...",
    pendingConfig: ToastPhaseConfig(title: "Preparing request...")
)
BoneToastManager.show(toast)
toast.start()  // Transitions to spinning indicator
toast.complete(message: "Finished!")

// Without pending phase
let toast = ActivityToast("Loading...", pendingConfig: nil)

// Handle failure
toast.fail(message: "Error occurred")

// Full configuration
let toast = ActivityToast(
    "Syncing...",
    style: .standard,
    backgroundStyle: .glass(tintColor: .orange),
    pendingConfig: ToastPhaseConfig(title: "Connecting..."),
    successConfig: ToastPhaseConfig(
        title: "Sync complete!",
        symbol: .symbol("checkmark.icloud.fill")
    ),
    failureConfig: ToastPhaseConfig(
        title: "Sync failed",
        symbol: .symbol("xmark.icloud.fill")
    )
)

// Convenience factory for network style
let toast = ActivityToast.network("Fetching data...")

// Convenience factory with custom network parameters
let toast = ActivityToast.network("Fetching data...", variableValue: 0.5, rotateSpeed: 2.0)
```

**ActivityIndicatorStyle.custom options:**

```swift
.custom(
    symbol: "arrow.clockwise",                    // SF Symbol name
    variableValue: 0.8,                           // Optional variable fill (0.0-1.0)
    font: .system(size: 16, weight: .semibold),  // Symbol font (default shown)
    effect: .rotate(speed: 2.0)                   // Animation effect
)

// Available effects:
.variableColor  // Pulsing color animation
.rotate(speed:) // Continuous rotation (speed multiplier)
.pulse          // Pulsing animation
.breathe        // Breathing animation
.bounce         // Bouncing animation
.scale          // Scaling animation
.wiggle         // Wiggle animation
.none           // No animation (static)
```

> **Note:** the `.custom` indicator's symbol styling parameter changed from `weight: SwiftUI.Font.Weight` to `font: SwiftUI.Font?`. Pass any `Font` (or `nil` to use the system default).

### CompletableToast (Base Class)

The base class for all completable toasts. Use directly for fully custom configurations.

```swift
// Using the convenience initializer
let toast = CompletableToast(
    "Processing...",
    activeSymbol: "gear",
    backgroundStyle: .glass(tintColor: .blue),
    pending: .message("Initializing..."),
    success: .config(message: "Done!", symbol: "checkmark.circle.fill"),
    failure: .config(message: "Failed", backgroundStyle: .glass(tintColor: .red))
)

// Using the primary initializer for full control
let toast = CompletableToast(
    text: BoneToast.TextConfig("Uploading..."),
    activeConfig: ToastPhaseConfig(
        title: "Uploading...",
        symbol: .symbol("icloud.and.arrow.up")
    ),
    pendingConfig: ToastPhaseConfig(
        title: "Preparing upload...",
        symbol: .symbol("doc.badge.clock")
    ),
    successConfig: ToastPhaseConfig(
        title: "Uploaded!",
        symbol: .symbol("icloud.and.arrow.up.fill"),
        backgroundStyle: .glass(tintColor: .green)
    ),
    failureConfig: ToastPhaseConfig(
        title: "Upload failed",
        symbol: .symbol("icloud.slash.fill"),
        backgroundStyle: .glass(tintColor: .red)
    ),
    backgroundStyle: .glass(tintColor: .blue)
)

// With custom unified symbol styling for smooth transitions
let symbols = ToastSymbols(
    active: "arrow.triangle.2.circlepath",
    success: "checkmark.circle.fill",
    failure: "xmark.circle.fill",
    hasEffects: true,
    replaceFallback: .downUp
)

let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
    image
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)
        .symbolEffect(
            .variableColor.iterative,
            options: .repeat(.continuous),
            isActive: phase == .active && effectEnabled
        )
}

let toast = CompletableToast(
    text: BoneToast.TextConfig("Syncing..."),
    activeConfig: ToastPhaseConfig(title: "Syncing..."),
    successConfig: ToastPhaseConfig(title: "Synced!"),
    unifiedSymbolStyle: unifiedStyle,
    backgroundStyle: .glass
)
```

---

## Phase System

Completable toasts use a phase-based lifecycle:

```swift
public enum BoneToast.Phase: Sendable {
    case pending   // Waiting to start (optional)
    case active    // In progress
    case success   // Completed successfully
    case failure   // Failed
}
```

### Phase Transitions

```
┌─────────┐     start()     ┌────────┐
│ pending │ ───────────────▶│ active │
└─────────┘                 └────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
              ┌─────────┐               ┌─────────┐
              │ success │               │ failure │
              └─────────┘               └─────────┘
              complete()                  fail()
```

### ToastPhaseConfig

Configure each phase independently:

```swift
ToastPhaseConfig(
    title: "Processing...",           // Message for this phase
    subtitle: "Please wait",          // Optional subtitle
    symbol: .symbol("gear"),          // Symbol configuration
    backgroundStyle: .glass(tintColor: .blue),
    fontColor: .white,
    titleFont: .headline,
    subtitleFont: .subheadline,
    actionButton: .hidden             // Hide button for this phase
)
```

**Pending Phase Configuration:**

The `pendingConfig` parameter controls whether a toast has a pending phase:

```swift
// With pending phase (default for ProgressToast/ActivityToast)
pendingConfig: .inheritMessage           // Same message as active phase
pendingConfig: ToastPhaseConfig(title: "Connecting...")  // Custom message

// Without pending phase
pendingConfig: nil
```

`ToastPhaseConfig.inheritMessage` is a convenience for pending phases that should use the same message as the active phase.

**Symbol Configuration Options:**

```swift
// No symbol
.none

// Use same symbol as active phase
.useActive

// SF Symbol with optional replace fallback
.symbol("checkmark.circle.fill")
.symbol("gear", replaceFallback: .downUp)

// Custom styling closure
.custom("star.fill", replaceFallback: .offUp) { image, effectEnabled in
    image
        .foregroundStyle(.yellow)
        .symbolEffect(.bounce, value: effectEnabled)
}
```

### SimplePhaseConfig (Convenience)

For simpler configuration in convenience initializers:

```swift
// Phase disabled
.disabled

// Phase enabled with defaults
.enabled

// Custom message
.message("Loading...")

// Custom symbol
.symbol("star.fill")

// Full configuration
.config(
    message: "Complete!",
    symbol: "checkmark.circle.fill",
    backgroundStyle: .glass(tintColor: .green)
)
```

---

## SF Symbol Transitions

BoneToast uses smooth `.replace` transitions between SF Symbols. The `replaceFallback` parameter controls the animation style:

| Fallback | Best For | Description |
|----------|----------|-------------|
| `.offUp` | Color changes between phases | Symbol fades out up, new one fades in |
| `.downUp` | Continuous animations (rotate, variableColor) | Old animates down, new animates up |
| `.upUp` | Similar to downUp | Both animate upward |

```swift
// When colors change between phases, use .offUp
let symbols = ToastSymbols(
    active: "circle",
    success: "checkmark.circle.fill",
    failure: "xmark.circle.fill",
    replaceFallback: .offUp  // Prevents color flash during transition
)

// When using continuous animations, use .downUp
let symbols = ToastSymbols(
    active: "progress.indicator",
    success: "checkmark.circle.fill",
    hasEffects: true,
    replaceFallback: .downUp  // Smoother transition from spinning
)
```

### ToastUnifiedSymbolStyle

For complete control over symbol transitions:

```swift
let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
    // image: The SF Symbol Image (same identity, different systemName)
    // phase: Current toast phase
    // effectEnabled: Whether effects should be active (false during transitions)

    let styledImage = image
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)

    switch phase {
        case .active, .pending:
            AnyView(styledImage
                .symbolEffect(.rotate, options: .repeat(.continuous), isActive: effectEnabled))
        case .success:
            AnyView(styledImage
                .symbolEffect(.bounce, value: effectEnabled))
        case .failure:
            AnyView(styledImage)
    }
}
```

---

## Action Buttons

### StandardToast Action Buttons

```swift
// Text button
StandardToast(
    "Item deleted",
    systemImage: "trash",
    actionButton: BoneToast.ActionButton("Undo") {
        // Handle undo
    }
)

// SF Symbol button (circle shape)
StandardToast(
    "Notification",
    systemImage: "bell.fill",
    actionButton: BoneToast.ActionButton(systemImage: "xmark") {
        // Dismiss action
    }
)

// Custom content
StandardToast(
    "Rate this app",
    actionButton: BoneToast.ActionButton(action: { /* action */ }) {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
            Text("Rate")
        }
        .foregroundColor(.white)
    }
)
```

### Completable Toast Action Buttons

Completable toasts support per-phase action button configuration:

```swift
// Base action button (shown in all phases by default)
let toast = CompletableToast(
    text: BoneToast.TextConfig("Processing..."),
    activeConfig: ToastPhaseConfig(title: "Processing..."),
    successConfig: ToastPhaseConfig(
        title: "Done!",
        actionButton: .hidden  // Hide button on success
    ),
    failureConfig: ToastPhaseConfig(
        title: "Failed",
        actionButton: .button(BoneToast.ActionButton("Retry") {
            // Retry action
        })
    ),
    actionButton: BoneToast.ActionButton("Cancel") {
        // Cancel action
    }
)
```

**ToastActionButtonOverride Options:**

| Option | Description |
|--------|-------------|
| `.inherit` | Use the base toast's action button |
| `.hidden` | Hide the action button for this phase |
| `.button(...)` | Show a custom button for this phase |

### Action Button Dismiss Behavior

When an action button is tapped:
1. The button's action closure is executed
2. `actionButtonTapped` is set to `true`
3. Toast dismisses according to its `dismissBehavior`

```swift
// Enable interactive dismissal to allow button to trigger dismiss
toast.interactive = true
```

---

## Background Styles

```swift
// Glass effect (iOS 26+, graceful fallback)
.glass                              // Default glass
.glass(tintColor: .blue)           // Tinted glass
.glass(style: .clear, tintColor: .blue)

// Solid backgrounds
.solid()                           // System background with border
.solid(.blue)                      // Colored with border
.solidNoBorder()                   // No border
.solidNoBorder(.blue)             // Colored, no border

// Create variant with different tint
let baseStyle = BoneToast.BackgroundStyle.glass
let blueStyle = baseStyle.withTint(.blue)
```

---

## Background Interaction

Toasts pass-through background touches by default — the rest of the app stays interactive while a toast is visible. Set `backgroundInteraction:` to turn a specific toast into a lightweight modal that blocks taps outside its frame, optionally with a dimmed scrim and/or tap-to-dismiss behavior.

```swift
// Block taps; invisible scrim; outside taps absorbed silently
ActivityToast("Verifying access…", backgroundInteraction: .blocking)

// Dimmed scrim, outside taps absorbed
StandardToast("Saving…", dismiss: .manual, backgroundInteraction: .dimmed)

// Transparent scrim; outside tap dismisses the toast
StandardToast.warning("Discard changes?", backgroundInteraction: .dismissOnTap)

// Dimmed scrim; outside tap dismisses the toast
ActivityToast("Connecting…", backgroundInteraction: .dimmedDismissOnTap)

// Button-only — tap/swipe and auto-dismiss disabled; only the action button can dismiss
StandardToast(
    "Sign out of all devices?",
    actionButton: BoneToast.ActionButton("Confirm") { signOut() },
    backgroundInteraction: .buttonOnly
)

// Custom — pick your own scrim and outside-tap behavior
StandardToast(
    "Custom modal toast",
    backgroundInteraction: BoneToast.BackgroundInteraction(
        scrim: .dimmed(opacity: 0.6),
        outsideTap: .dismiss
    )
)
```

**`BoneToast.BackgroundInteraction` options:**

| Property | Values | Default |
|---|---|---|
| `scrim` | `.transparent`, `.dimmed(opacity:)` | `.transparent` |
| `outsideTap` | `.absorb`, `.dismiss` | `.absorb` |
| `requiresAcknowledgment` | `Bool` — when `true`, suppresses tap/swipe dismissal and the auto-dismiss timer | `false` |

**Presets:**

| Preset | Scrim | Outside tap | Toast tap/swipe | Auto-dismiss |
|---|---|---|---|---|
| `.blocking` | transparent | absorb | enabled | per `dismiss:` |
| `.dimmed` | dimmed (0.35) | absorb | enabled | per `dismiss:` |
| `.dismissOnTap` | transparent | dismiss | enabled | per `dismiss:` |
| `.dimmedDismissOnTap` | dimmed (0.35) | dismiss | enabled | per `dismiss:` |
| `.buttonOnly` | transparent | absorb | **disabled** | **disabled** |
| `.dimmedButtonOnly` | dimmed (0.35) | absorb | **disabled** | **disabled** |

### Behavior notes

- Background interaction is honored by **global presentation only** (`BoneToastManager` / `.globalToast`). Scoped toasts (`.scopedToastContainer`) don't have their own window and can't block touches outside their hosting view.
- When several blocking toasts are visible at once, only the **most recently presented** one owns the scrim and outside-tap behavior. Dismissing it promotes the next blocker in the stack — scrims do *not* compound (two `.dimmed` blockers do not double the dimming).
- Non-blocking toasts presented alongside a blocker remain individually tappable / dismissable on top of the scrim.
- `.buttonOnly` / `.dimmedButtonOnly` (or any custom config with `requiresAcknowledgment: true`) **must be paired with an action button** — otherwise the toast has no user-facing dismiss path and can only be removed via `BoneToastManager.dismiss(id:)`.

---

## Uniqueness

Toasts allow duplicates by default — calling `show(_:)` twice with the same content stacks two toasts. Set `uniqueness:` on a toast to opt into de-duplication. When a duplicate is detected, the configured strategy decides whether to drop the new toast (`.ignore`) or swap out the existing one (`.replace`).

```swift
// Drop duplicates: if "Saved" is already on screen, the second call is a no-op.
BoneToastManager.show(StandardToast("Saved", uniqueness: .ignore))

// Replace duplicates: the new toast dismisses the older one and takes its place.
BoneToastManager.show(StandardToast("Uploading…", uniqueness: .replace))

// Explicit match mode + strategy.
BoneToastManager.show(StandardToast(
    text: BoneToast.TextConfig(title: "Sync error", subtitle: "Retrying in 5s"),
    uniqueness: BoneToast.Uniqueness(match: .titleAndSubtitle, strategy: .replace)
))

// Match on an explicit key — useful when the visible text differs but the toast
// represents the same logical event. Symmetric: only matches toasts that also
// declare the same key.
BoneToastManager.show(StandardToast(
    "Network unavailable",
    uniqueness: BoneToast.Uniqueness(match: .key("network"), strategy: .ignore)
))
```

**`BoneToast.Uniqueness` options:**

| Property | Values | Default |
|---|---|---|
| `match` | `.auto`, `.title`, `.titleAndSubtitle`, `.key(String)` | `.auto` |
| `strategy` | `.ignore`, `.replace` | `.ignore` |

**Match modes:**

| Mode | Compares |
|---|---|
| `.auto` | Title only when the new toast has no subtitle; title + subtitle when it does. **Default.** |
| `.title` | `textConfig.title` only — same title is always a duplicate, regardless of subtitle. |
| `.titleAndSubtitle` | Both `textConfig.title` and `textConfig.subtitle`. |
| `.key(String)` | Explicit key. **Symmetric** — only matches existing toasts that also use `.key(_)` with the same value. |

**Presets:**

| Preset | Match | Strategy |
|---|---|---|
| `.ignore` | `.auto` | `.ignore` |
| `.replace` | `.auto` | `.replace` |

### Behavior notes

- Uniqueness is a property of the **new** toast — for `.title` / `.titleAndSubtitle`, the existing toast doesn't need to be marked unique itself. The new toast says "I shouldn't appear if a similar one is already here."
- `.key(_)` is symmetric on purpose: requiring both sides to opt in prevents an arbitrary string from colliding with unrelated text-based toasts.
- `.replace` dismisses the existing toast through the normal animated path, then appends the new one — there is a brief visual overlap during the exit/enter transitions.
- The check runs in `BoneToastManager.show(_:)`, so it applies identically to global and scoped managers.

---

## BoneToastManager

### Global Toasts

```swift
// Show from anywhere
BoneToastManager.show(StandardToast.success("Saved!"))

// With dismiss callback
BoneToastManager.show(toast) {
    print("Toast dismissed")
}

// Configure global settings
BoneToastManager.shared.animationConfig = .slide
BoneToastManager.shared.defaultPosition = .bottom
BoneToastManager.shared.stackOrder = .oldestFirst
BoneToastManager.shared.pinning = .whenReadyOnly

// Dismiss all
BoneToastManager.dismissAll()
```

### Awaitable Dismiss

Use the `async` dismiss overloads when you want to do something next that would otherwise interfere with the toast's exit animation — for example, presenting a modal `UIViewController`. The async forms wait for the exit animation to finish before returning.

```swift
// Auto-derives the wait from the toast's effective animation timing
await BoneToastManager.shared.dismiss(id: toast.id)
self.present(modal, animated: true)

// Explicit override (e.g. for a `.custom` timing whose duration we can't infer)
await BoneToastManager.shared.dismiss(id: toast.id, delay: 0.5)

// Skip the wait entirely (equivalent to the synchronous form, but in an async context)
await BoneToastManager.shared.dismiss(id: toast.id, delay: 0)

// Same shape for dismissAll
await BoneToastManager.shared.dismissAll()
await BoneToastManager.shared.dismissAll(delay: nil)  // explicit auto
```

The auto-derived wait uses the toast's effective `BoneToast.Timing.estimatedDuration`:

| Timing | Estimated duration |
|---|---|
| `.snappy` | 0.25s |
| `.smooth` | 0.30s |
| `.bouncy` | 0.40s |
| `.spring(response, _)` | `response × 2.5` |
| `.easeInOut(d)` | `d` |
| `.custom` | 0.40s (opaque — pass an explicit `delay:` for accuracy) |

Sync `dismiss(id:)` / `dismissAll()` remain unchanged for fire-and-forget use.

### Pause-on-Press

Toasts with auto-dismiss timers automatically pause their countdown while the user is pressing on them — release resumes it from where it left off. The manager exposes the same controls programmatically:

```swift
BoneToastManager.shared.pauseDismiss(id: toast.id)
// …later
BoneToastManager.shared.resumeDismiss(id: toast.id)
```

### Scoped Toasts

```swift
struct ModalView: View {
    @State private var manager = BoneToastManager()

    var body: some View {
        Content()
            .scopedToastContainer(manager: manager)
    }
}
```

### Binding-Based API

```swift
struct ContentView: View {
    @State private var showToast = false

    var body: some View {
        Button("Show") { showToast = true }
            .globalToast(isPresented: $showToast) {
                StandardToast.success("Done!")
            }
    }
}
```

### Manager Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `pinning` | `BoneToast.Pinning` | `.none` | Which toasts stay pinned |
| `animationConfig` | `BoneToast.AnimationConfig` | `.bounce` | Default animation |
| `defaultPosition` | `BoneToast.Position` | `.top` | Default toast position |
| `toastSpacing` | `CGFloat` | `6` | Spacing between stacked toasts |
| `stackOrder` | `BoneToast.StackOrder` | `.newestFirst` | Stack ordering |

### Animation Presets

| Preset | Description |
|--------|-------------|
| `.bounce` | Bouncy slide from edge (default) |
| `.slide` | Smooth slide from edge |
| `.scale` | Scale up with spring |
| `.fade` | Simple opacity fade |
| `.pop` | Dramatic pop-in effect |
| `.snappy` | Quick, responsive |
| `.slideFromLeading` | Slide from left |
| `.slideFromTrailing` | Slide from right |
| `.subtle` | Very gentle appearance |

```swift
// Custom animation
let config = BoneToast.AnimationConfig.custom(
    transition: .scale(0.6),
    timing: .spring(response: 0.4, dampingFraction: 0.5)
)
```

### Pinning Options

| Option | Description |
|--------|-------------|
| `.none` | No pinning (default) |
| `.manualOnly` | Pin `.manual` dismiss toasts |
| `.whenReadyOnly` | Pin `.whenReady` toasts (Progress/Activity) |
| `.manualAndWhenReady` | Pin both types |

---

## Interactive Dismissal

The `interactive` property controls tap/swipe dismissal:

```swift
// StandardToast - interactive by default
let toast = StandardToast("Message")
toast.interactive = false  // Disable

// Completable toasts - not interactive by default
let progress = ProgressToast("Loading...")
progress.interactive = true  // Enable after completion
```

**Defaults by dismiss behavior:**
- `.manual`, `.afterDelay` → `interactive = true`
- `.whenReady` → `interactive = false`

---

## Layout & Spacing

BoneToast uses consistent 8pt spacing between all elements:

```
┌─────────────────────────────────────────────┐
│  [Icon] 8pt [Text] 8pt [Button]            │
│  ↑                                     ↑   │
│  contentPadding.leading    contentPadding.trailing
└─────────────────────────────────────────────┘
```

### Content Padding

```swift
.none
.systemDefault
.all(16)
.horizontal(20)
.vertical(12)
.edges(top: 10, leading: 14, bottom: 10, trailing: 14)
.custom(EdgeInsets(...))
```

### Corner Styles

```swift
.capsule                        // Fully rounded (default for short toasts)
.roundedRect(cornerRadius: 12)  // Custom radius (auto for 3+ lines)
```

---

## Type Reference

### BoneToast Namespace

| Type | Description |
|------|-------------|
| `BoneToast.Position` | `.top` or `.bottom` |
| `BoneToast.Phase` | `.pending`, `.active`, `.success`, `.failure` |
| `BoneToast.BackgroundStyle` | `.glass` or `.solid` variants |
| `BoneToast.BackgroundInteraction` | Optional modal-style touch blocking (scrim + outside-tap behavior) |
| `BoneToast.CornerStyle` | `.capsule` or `.roundedRect` |
| `BoneToast.Padding` | Content/edge padding |
| `BoneToast.TextConfig` | Title/subtitle configuration |
| `BoneToast.TextAlignment` | `.leading`, `.center`, `.trailing` |
| `BoneToast.ActionButton` | Action button configuration |
| `BoneToast.ButtonShape` | `.capsule`, `.circle`, `.roundedRect` |
| `BoneToast.AnimationConfig` | Animation presets/custom |
| `BoneToast.Transition` | Transition type |
| `BoneToast.Timing` | Animation timing |
| `BoneToast.DismissBehavior` | `.afterDelay`, `.whenReady`, `.manual` |
| `BoneToast.Pinning` | Pinning configuration |
| `BoneToast.StackOrder` | `.newestFirst`, `.oldestFirst` |

### Toast Classes

| Class | Description |
|-------|-------------|
| `StandardToast` | Simple fire-and-forget notifications |
| `CompletableToast` | Base class for phase-based toasts |
| `ProgressToast` | Progress tracking (0.0-1.0) |
| `ActivityToast` | Indeterminate activity with configurable indicator style |

### Activity Indicator Styles

| Style | Description |
|-------|-------------|
| `.standard` | Pulsing dots (`progress.indicator` with variableColor) |
| `.network(variableValue:rotateSpeed:)` | Rotating partial-fill circle, ideal for network operations (both params optional) |
| `.custom(symbol:variableValue:font:effect:)` | Custom symbol with configurable animation |

### Phase Configuration

| Type | Description |
|------|-------------|
| `ToastPhaseConfig` | Full phase configuration |
| `ToastPhaseConfig.inheritMessage` | Pending config that inherits the active message |
| `SimplePhaseConfig` | Convenience configuration |
| `ToastSymbolConfig` | Symbol configuration per phase |
| `ToastActionButtonOverride` | `.inherit`, `.hidden`, `.button(...)` |
| `ToastSymbols` | Symbol names for all phases |
| `ToastUnifiedSymbolStyle` | Custom symbol styling closure |

---

## UIKit Integration

```swift
class MyViewController: UIViewController {
    // Your app's download manager
    var downloadManager: DownloadManager!

    func showSuccess() {
        BoneToastManager.show(StandardToast.success("Saved!"))
    }

    func startDownload() {
        let progress = BoneToastManager.show(ProgressToast("Downloading..."))

        // Connect your download callbacks to toast updates
        downloadManager.onProgress = { value in
            progress.progress = value
        }

        downloadManager.onComplete = {
            progress.complete(message: "Downloaded!")
        }

        downloadManager.onError = { error in
            progress.fail(message: error.localizedDescription)
        }
    }
}
```

---

## Thread Safety

All toast types are `@MainActor`. Update from any context:

```swift
Task.detached {
    await MainActor.run {
        progressToast.progress = 0.5
    }
}
```

---

## iOS Version Support

- **iOS 26+**: Full liquid glass effect, SF Symbol variable draw mode
- **Pre-iOS 26**: Solid fallback background, ProgressView fallback

---

## Examples

> **Note:** Functions like `connect()`, `initialize()`, `process()`, etc. in these examples are placeholder functions representing your own app logic—they are not part of the BoneToast API.

### Complete Download Flow

```swift
func downloadFile() async {
    let toast = BoneToastManager.show(ProgressToast(
        "Downloading...",
        pendingConfig: ToastPhaseConfig(title: "Connecting...")
    ))

    do {
        // Connection phase (your app's network logic)
        try await connect()
        toast.start()

        // Download phase (your app's download stream)
        for await progress in downloadProgress {
            toast.progress = progress
            if progress > 0.5 {
                toast.message = "Almost there..."
            }
        }

        toast.complete(message: "Download complete!")
    } catch {
        toast.fail(message: "Download failed: \(error.localizedDescription)")
    }
}
```

### Multi-Step Operation

```swift
func performMultiStepOperation() async {
    let toast = BoneToastManager.show(ActivityToast(
        "Processing...",
        pendingConfig: ToastPhaseConfig(title: "Initializing...")
    ))

    // Step 1: Your app's initialization logic
    await initialize()
    toast.start()
    toast.message = "Step 1 of 3..."

    // Step 2: Your app's processing logic
    await process()
    toast.message = "Step 2 of 3..."

    // Step 3: Your app's finalization logic
    await finalize()
    toast.message = "Step 3 of 3..."

    toast.complete(message: "All steps complete!")
}
```

### Custom Styled Toast

```swift
let symbols = ToastSymbols(
    active: "arrow.triangle.2.circlepath",
    pending: "hourglass",
    success: "checkmark.seal.fill",
    failure: "exclamationmark.triangle.fill",
    hasEffects: true,
    replaceFallback: .downUp
)

let style = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
    let base = image
        .font(.system(size: 18, weight: .bold))
        .symbolRenderingMode(.hierarchical)

    switch phase {
        case .pending:
            AnyView(base
                .foregroundStyle(.gray)
                .symbolEffect(.pulse, isActive: effectEnabled))
        case .active:
            AnyView(base
                .foregroundStyle(.blue)
                .symbolEffect(.rotate, options: .repeat(.continuous), isActive: effectEnabled))
        case .success:
            AnyView(base
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: effectEnabled))
        case .failure:
            AnyView(base
                .foregroundStyle(.red)
                .symbolEffect(.bounce, value: effectEnabled))
    }
}

let toast = CompletableToast(
    text: BoneToast.TextConfig("Custom sync..."),
    activeConfig: ToastPhaseConfig(title: "Syncing..."),
    pendingConfig: ToastPhaseConfig(title: "Preparing..."),
    successConfig: ToastPhaseConfig(
        title: "Synced!",
        backgroundStyle: .glass(tintColor: .green)
    ),
    failureConfig: ToastPhaseConfig(
        title: "Sync failed",
        backgroundStyle: .glass(tintColor: .red)
    ),
    unifiedSymbolStyle: style,
    backgroundStyle: .glass(tintColor: .blue)
)
```

### Toast with Action Button

```swift
let toast = StandardToast(
    "3 items deleted",
    systemImage: "trash",
    backgroundStyle: .glass(tintColor: .red),
    dismiss: .auto(delay: 5.0),
    actionButton: BoneToast.ActionButton("Undo") {
        undoDelete()  // Your app's undo logic
    }
)
BoneToastManager.show(toast)
```

### Completable Toast with Per-Phase Buttons

```swift
let toast = CompletableToast(
    text: BoneToast.TextConfig("Uploading file..."),
    activeConfig: ToastPhaseConfig(
        title: "Uploading...",
        actionButton: .button(BoneToast.ActionButton("Cancel") {
            cancelUpload()  // Your app's cancel logic
        })
    ),
    successConfig: ToastPhaseConfig(
        title: "Uploaded!",
        actionButton: .button(BoneToast.ActionButton("View") {
            viewFile()  // Your app's view logic
        })
    ),
    failureConfig: ToastPhaseConfig(
        title: "Upload failed",
        actionButton: .button(BoneToast.ActionButton("Retry") {
            retryUpload()  // Your app's retry logic
        })
    ),
    backgroundStyle: .glass(tintColor: .blue)
)
toast.interactive = true  // Enable button dismissal
```

---

## License

GPL v3 License - See LICENSE file for details.
