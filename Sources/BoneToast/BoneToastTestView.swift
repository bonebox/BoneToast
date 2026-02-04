//
//  BoneToastTestView.swift
//  BoneToast
//
//  Copyright © 2025 Allogy Interactive. All rights reserved.
//

import SwiftUI

/// A test view for exercising BoneToast functionality
public struct BoneToastTestView: View {
	@Environment(\.dismiss) private var dismiss

	// MARK: - Configuration State
	@State private var presentationMode: TestPresentationMode = .global
	@State private var useManager: Bool = false

	/// Presentation mode options for testing
	public enum TestPresentationMode: String, CaseIterable {
		case global = "Global"
		case scoped = "Scoped (Overlay)"

		public var isGlobal: Bool { self == .global }
		public var isScoped: Bool { self == .scoped }
	}
	@State private var positionOption: PositionOption = .defaultTop
	@State private var pinningStyle: BoneToast.Pinning = .none
	@State private var stackOrder: BoneToast.StackOrder = .newestFirst
	@State private var animationStyle: AnimationStyleOption = .bounce
	@State private var cornerStyle: CornerStyleOption = .adaptive
	@State private var backgroundStyleOption: BackgroundStyleOption = .glass

	// MARK: - Single Toast State
	@State private var showSingleToast = false
	@State private var singleToast: StandardToast?

	// MARK: - Completable Toast State (unified Progress/Activity)
	@State private var showProgressToast = false
	@State private var progressToast: ProgressToast?
	@State private var showActivityToast = false
	@State private var activityToast: CompletableToast?  // ActivityToast/NetworkActivityToast both inherit from this

	// MARK: - Binding-Based Demo State
	@State private var showBindingToast = false
	@State private var bindingToastDismissCount = 0

	// MARK: - Manager
	@State private var toastManager: BoneToastManager?

	public enum AnimationStyleOption: String, CaseIterable {
		case bounce = "Bounce"
		case slide = "Slide"
		case scale = "Scale"
		case fade = "Fade"
		case slideFromLeading = "Slide Leading"
		case slideFromTrailing = "Slide Trailing"
		case pop = "Pop"
		case snappy = "Snappy"

		public var animationConfig: BoneToast.AnimationConfig {
			switch self {
			case .bounce: .bounce
			case .slide: .slide
			case .scale: .scale
			case .fade: .fade
			case .slideFromLeading: .slideFromLeading
			case .slideFromTrailing: .slideFromTrailing
			case .pop: .pop
			case .snappy: .snappy
			}
		}
	}

	public enum CornerStyleOption: String, CaseIterable {
		case adaptive = "Adaptive"
		case capsule = "Capsule"
		case roundedRect = "Rounded (28pt)"

		public var style: BoneToast.CornerStyle? {
			switch self {
				case .adaptive: nil
				case .capsule: .capsule
				case .roundedRect: .roundedRect(cornerRadius: 28)
			}
		}
	}

	public enum BackgroundStyleOption: String, CaseIterable {
		case glass = "Glass"
		case glassClear = "Glass (Clear)"
		case solid = "Solid"
		case solidNoBorder = "Solid (No Border)"

		public func backgroundStyle(tintColor: Color?) -> BoneToast.BackgroundStyle {
			switch self {
			case .glass:
				if let tintColor {
					return .glass(tintColor: tintColor)
				} else {
					return .glass
				}
			case .glassClear:
				return .glass(style: .clear, tintColor: tintColor)
			case .solid:
				return .solid(tintColor)
			case .solidNoBorder:
				return .solidNoBorder(tintColor)
			}
		}
	}

	public enum PositionOption: String, CaseIterable {
		case defaultTop = "Default (Top)"
		case defaultBottom = "Default (Bottom)"
		case forceTop = "Force Top"
		case forceBottom = "Force Bottom"

		public var managerDefault: BoneToast.Position {
			switch self {
				case .defaultTop, .forceTop: .top
				case .defaultBottom, .forceBottom: .bottom
			}
		}

		public var isForced: Bool {
			switch self {
				case .forceTop, .forceBottom: true
				case .defaultTop, .defaultBottom: false
			}
		}

		public var forcedPosition: BoneToast.Position? {
			switch self {
				case .forceTop: .top
				case .forceBottom: .bottom
				case .defaultTop, .defaultBottom: nil
			}
		}
	}

	public init() {}

	public var body: some View {
		NavigationStack {
			Form {
				configurationSection
				standardToastsSection
				actionButtonSection
				customSymbolSection
				animationOverrideSection
				bindingBasedSection
				progressToastsSection
				activityToastsSection

				if useManager || presentationMode.isGlobal {
					managerActionsSection
				}
			}
			.navigationTitle("Toast Tester")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
		.onAppear {
			updateManager()
		}
		.onChange(of: useManager) { _, _ in updateManager() }
		.onChange(of: presentationMode) { _, _ in updateManager() }
		.onChange(of: pinningStyle) { _, newValue in
			if presentationMode.isGlobal {
				BoneToastManager.shared.pinning = newValue
			} else {
				toastManager?.pinning = newValue
			}
		}
		.onChange(of: animationStyle) { _, newValue in
			if presentationMode.isGlobal {
				BoneToastManager.shared.animationConfig = newValue.animationConfig
			} else {
				toastManager?.animationConfig = newValue.animationConfig
			}
		}
		.onChange(of: stackOrder) { _, newValue in
			if presentationMode.isGlobal {
				BoneToastManager.shared.stackOrder = newValue
			} else {
				toastManager?.stackOrder = newValue
			}
		}
		.onChange(of: positionOption, updatePositionOption)
		// Global toast modifiers (when in global mode and not using manager)
		.globalToast(isPresented: $showSingleToast) {
			singleToast ?? StandardToast("")
		}
		.globalToast(isPresented: $showProgressToast) {
			progressToast ?? CompletableToast("")
		}
		.globalToast(isPresented: $showActivityToast) {
			activityToast ?? CompletableToast("")
		}
		// Binding-based demo toast
		.globalToast(isPresented: $showBindingToast) {
			StandardToast(
				"Binding-based toast (dismiss #\(bindingToastDismissCount + 1))",
				systemImage: "link",
				backgroundStyle: .glass(tintColor: .purple),
								cornerStyle: cornerStyle.style
			)
		}
		.onChange(of: showBindingToast) { oldValue, newValue in
			// Track when binding changes from true to false (dismissed)
			if oldValue && !newValue {
				bindingToastDismissCount += 1
			}
		}
		// Scoped container (only used when in scoped mode with manager)
		.modifier(OptionalScopedToastContainerModifier(manager: presentationMode.isScoped && useManager ? toastManager : nil))
	}

	// MARK: - Sections

	private var configurationSection: some View {
		Section("Configuration") {
			Picker("Presentation", selection: $presentationMode) {
				ForEach(TestPresentationMode.allCases, id: \.self) { mode in
					Text(mode.rawValue).tag(mode)
				}
			}

			if !presentationMode.isGlobal {
				Toggle("Use Manager (Queue)", isOn: $useManager)
			}

			Picker("Animation", selection: $animationStyle) {
				ForEach(AnimationStyleOption.allCases, id: \.self) { style in
					Text(style.rawValue).tag(style)
				}
			}

			positionPicker

			Picker("Corner Style", selection: $cornerStyle) {
				ForEach(CornerStyleOption.allCases, id: \.self) { style in
					Text(style.rawValue).tag(style)
				}
			}

			Picker("Background Style", selection: $backgroundStyleOption) {
				ForEach(BackgroundStyleOption.allCases, id: \.self) { style in
					Text(style.rawValue).tag(style)
				}
			}

			if useManager || presentationMode.isGlobal {
				Picker("Stack Order", selection: $stackOrder) {
					Text("Newest First").tag(BoneToast.StackOrder.newestFirst)
					Text("Oldest First").tag(BoneToast.StackOrder.oldestFirst)
				}

				Picker("Pinning", selection: $pinningStyle) {
					Text("None").tag(BoneToast.Pinning.none)
					Text("Manual Only").tag(BoneToast.Pinning.manualOnly)
					Text("When Ready Only").tag(BoneToast.Pinning.whenReadyOnly)
					Text("Manual & When Ready").tag(BoneToast.Pinning.manualAndWhenReady)
				}
			}
		}
	}

	private var positionPicker: some View {
		Picker("Position", selection: $positionOption) {
			ForEach(PositionOption.allCases, id: \.self) { option in
				Text(option.rawValue).tag(option)
			}
		}
	}

	private var standardToastsSection: some View {
		Section("Standard Toasts") {
			Button("Default Toast (No Color)") {
				showStandardToast(StandardToast(
					"Default appearance",
					systemImage: "sparkles",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Info Toast (Top)") {
				showStandardToast(StandardToast(
					"This is an info message",
					systemImage: "info.circle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
					position: resolvedPosition(explicit: .top),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Success Toast (Top)") {
				showStandardToast(StandardToast(
					"Operation completed successfully",
					systemImage: "checkmark.circle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .green),
					position: resolvedPosition(explicit: .top),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Warning Toast (Bottom)") {
				showStandardToast(StandardToast(
					"Please check your input",
					systemImage: "exclamationmark.triangle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .orange),
					position: resolvedPosition(explicit: .bottom),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Error Toast (Bottom)") {
				showStandardToast(StandardToast(
					"Something went wrong",
					systemImage: "exclamationmark.triangle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .red),
					position: resolvedPosition(explicit: .bottom),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Toast with Subtitle (with icon)") {
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig(
						title: "File Downloaded",
						subtitle: "report_2024.pdf saved to Downloads",
						hasIcon: true
					),
					systemImage: "arrow.down.circle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Toast with Subtitle (no icon)") {
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig(
						title: "Changes Saved",
						subtitle: "Your preferences have been updated",
						hasIcon: false
					),
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .green),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Unlimited Lines Toast (auto corner)") {
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig(
						title: "This is a longer title that should wrap to approximately two lines of text",
						titleLineLimit: 0,
						subtitle: "This subtitle is even longer and contains more detailed information that the user might need to read, spanning roughly three lines of text in the toast.",
						subtitleLineLimit: 0,
						hasIcon: true
					),
					systemImage: "doc.text",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .purple),
					position: resolvedPosition()
					// cornerStyle omitted - will auto-select rounded rect since > 4 lines
				))
			}

			Button("Long Text (Auto Timing)") {
				showStandardToast(StandardToast(
					"This is a longer toast message that will automatically calculate its display duration based on the amount of text",
					systemImage: "text.bubble",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .purple),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Manual Dismiss Toast (Bottom)") {
				showStandardToast(StandardToast(
					"Tap to dismiss",
					systemImage: "hand.tap",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .indigo),
					position: resolvedPosition(explicit: .bottom),
					dismiss: .manual,
					cornerStyle: cornerStyle.style
				))
			}
		}
	}

	private var actionButtonSection: some View {
		Section {
			Button("Toast with Action Button") {
				showStandardToast(StandardToast(
					"Undo available",
					systemImage: "arrow.uturn.backward",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
					position: resolvedPosition(),
					dismiss: .manual,
					cornerStyle: cornerStyle.style,
					actionButton: BoneToast.ActionButton("Undo") {
						// Action will dismiss the toast
						if presentationMode.isGlobal {
							BoneToastManager.dismissAll()
						} else {
							toastManager?.dismissAll()
						}
					}
				))
			}

			Button("Action Button (Custom Styling)") {
				showStandardToast(StandardToast(
					"Changes saved",
					systemImage: "checkmark.circle.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .green),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					actionButton: BoneToast.ActionButton(
						"View",
						action: {
							// Custom action
						},
						backgroundStyle: .solid(.white.opacity(0.3)),
						fontColor: .white,
						shape: .roundedRect(cornerRadius: 8)
					)
				))
			}

			Button("Action Button (SF Symbol)") {
				showStandardToast(StandardToast(
					"New notification",
					systemImage: "bell.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					actionButton: BoneToast.ActionButton(
						systemImage: "xmark",
						action: {
							// Dismiss action
						}
					)
				))
			}

			Button("Action Button (Long Text)") {
				showStandardToast(StandardToast(
					text: .init("This is a longer message that will need to wrap to multiple lines to demonstrate how the action button behaves", lineLimit: 0),
					systemImage: "text.bubble",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .purple),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					actionButton: BoneToast.ActionButton("Details") { }
				))
			}

			Button("Action Button (Short Text)") {
				showStandardToast(StandardToast(
					"OK",
					systemImage: "hand.thumbsup.fill",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .orange),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					actionButton: BoneToast.ActionButton("Celebrate") { }
				))
			}
		} header: {
			Text("Action Buttons")
		} footer: {
			Text("Action buttons appear on the trailing edge of toasts. They inherit styling from the toast by default. SF Symbol buttons default to a circle shape.")
		}
	}

	private var customSymbolSection: some View {
		Section {
			Button("Standard Toast (Custom Symbol)") {
				// Uses view builder with multi-color symbol rendering
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig("Multi-Color Symbol"),
					icon: {
						Image(systemName: "externaldrive.fill.badge.checkmark")
							.symbolRenderingMode(.multicolor)
							.font(.system(size: 20, weight: .semibold))
					},
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Standard Toast (Palette Symbol)") {
				// Uses palette rendering with custom colors
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig("Palette Rendering"),
					icon: {
						Image(systemName: "person.crop.circle.badge.checkmark")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.green, .blue)
							.font(.system(size: 22, weight: .medium))
					},
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Standard Toast (Hierarchical Symbol)") {
				// Uses hierarchical rendering
				showStandardToast(StandardToast(
					text: BoneToast.TextConfig("Hierarchical Rendering"),
					icon: {
						Image(systemName: "square.stack.3d.up.fill")
							.symbolRenderingMode(.hierarchical)
							.foregroundStyle(.purple)
							.font(.system(size: 20, weight: .bold))
					},
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .purple),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
				))
			}

			Button("Activity Toast (Custom Symbols)") {
				startCustomSymbolActivityToast()
			}

			Button("Progress Toast (Custom Symbols)") {
				startCustomSymbolProgressToast()
			}
		} header: {
			Text("Custom SF Symbols")
		} footer: {
			Text("These toasts use view builders to provide customized SF Symbols with different rendering modes, colors, and effects while still supporting smooth .replace transitions.")
		}
	}

	private var animationOverrideSection: some View {
		Section {
			Button("Toast with Scale Animation") {
				// This toast uses .scale animation regardless of manager's default
				showStandardToast(StandardToast(
					"Scale animation (per-toast)",
					systemImage: "arrow.up.left.and.arrow.down.right",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .cyan),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					animationConfig: .scale
				))
			}

			Button("Toast with Pop Animation") {
				// This toast uses .pop animation regardless of manager's default
				showStandardToast(StandardToast(
					"Pop animation (per-toast)",
					systemImage: "sparkle",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .pink),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					animationConfig: .pop
				))
			}

			Button("Toast with Slide Leading") {
				// This toast slides from leading edge
				showStandardToast(StandardToast(
					"Slide from leading (per-toast)",
					systemImage: "arrow.right",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .mint),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					animationConfig: .slideFromLeading
				))
			}

			Button("Toast with Fade Animation") {
				// This toast uses fade animation
				showStandardToast(StandardToast(
					"Fade animation (per-toast)",
					systemImage: "circle.dotted",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .gray),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style,
					animationConfig: .fade
				))
			}

			Button("Toast with Manager Default") {
				// This toast uses the manager's default animation
				showStandardToast(StandardToast(
					"Manager default animation",
					systemImage: "gearshape",
					backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .orange),
					position: resolvedPosition(),
					cornerStyle: cornerStyle.style
					// animationConfig omitted - uses manager's default
				))
			}
		} header: {
			Text("Per-Toast Animation Override")
		} footer: {
			Text("Each toast can specify its own animation, overriding the manager's default (\(animationStyle.rawValue)).")
		}
	}

	private var bindingBasedSection: some View {
		Section {
			Button("Show Binding-Based Toast") {
				showBindingToast = true
			}

			HStack {
				Text("Binding state:")
				Spacer()
				Text(showBindingToast ? "true" : "false")
					.font(.headline)
					.foregroundStyle(showBindingToast ? .green : .secondary)
			}

			HStack {
				Text("Dismiss count:")
				Spacer()
				Text("\(bindingToastDismissCount)")
					.font(.headline)
					.foregroundStyle(bindingToastDismissCount > 0 ? .primary : .secondary)
			}
		} header: {
			Text("Binding-Based API")
		} footer: {
			Text("Uses .globalToast(isPresented:) modifier. The binding automatically resets to false when the toast is dismissed (by timeout, swipe, or programmatically).")
		}
	}

	private var progressToastsSection: some View {
		Section("Progress Toast") {
			Button("Progress Toast (Success)") {
				startProgressToast(shouldFail: false)
			}

			Button("Progress Toast (Failure)") {
				startProgressToast(shouldFail: true)
			}

			Button("Progress Toast (All Phases Custom Symbols)") {
				startStyledProgressToast()
			}

			Button("Progress Toast (Pending → Success)") {
				startPendingProgressToast(shouldFail: false)
			}

			Button("Progress Toast (Pending → Failure)") {
				startPendingProgressToast(shouldFail: true)
			}
		}
	}

	private var activityToastsSection: some View {
		Section("Activity Toast") {
			Button("Activity Toast - Success (2s)") {
				startActivityToast(duration: 2.0, shouldFail: false)
			}

			Button("Activity Toast - Failure (2s)") {
				startActivityToast(duration: 2.0, shouldFail: true)
			}

			Button("Activity Toast (All Phases Custom Symbols)") {
				startStyledActivityToast()
			}

			Button("Activity Toast (Pending → Success)") {
				startPendingActivityToast(shouldFail: false)
			}

			Button("Activity Toast (Pending → Failure)") {
				startPendingActivityToast(shouldFail: true)
			}

			Button("Network Activity Toast") {
				startNetworkActivityToast()
			}
		}
	}

	private var managerActionsSection: some View {
		Section {
			Button("Dismiss All") {
				if presentationMode.isGlobal {
					BoneToastManager.dismissAll()
				} else {
					toastManager?.dismissAll()
				}
			}
			.foregroundStyle(.red)

			if presentationMode.isGlobal {
				HStack {
					Text("Queue count:")
					Spacer()
					Text("\(BoneToastManager.shared.toasts.count)")
						.font(.headline)
						.foregroundStyle(BoneToastManager.shared.isEmpty ? .secondary : .primary)
				}
			} else if let manager = toastManager {
				HStack {
					Text("Queue count:")
					Spacer()
					Text("\(manager.toasts.count)")
						.font(.headline)
						.foregroundStyle(manager.toasts.isEmpty ? .secondary : .primary)
				}
			}
		} header: {
			Text(presentationMode.isGlobal ? "Global Manager" : "Manager Actions")
		} footer: {
			if presentationMode.isGlobal {
				Text("Global toasts appear above all content including modals and sheets.")
			}
		}
	}

	// MARK: - Actions

	private func updateManager() {
		if useManager && !presentationMode.isGlobal {
			toastManager = BoneToastManager(
				pinning: pinningStyle,
				animationConfig: animationStyle.animationConfig,
				defaultPosition: positionOption.managerDefault,
				stackOrder: stackOrder
			)
		} else {
			toastManager = nil
		}
	}

	private func updatePositionOption(_: PositionOption, _ newValue: PositionOption) {
		BoneToastManager.shared.defaultPosition = newValue.managerDefault
		toastManager?.defaultPosition = newValue.managerDefault
	}

	/// Resolves the effective position for a toast.
	/// - Parameter explicitPosition: The position explicitly set for this toast (if any)
	/// - Returns: The position to use - forced position if force mode is active, explicit position if provided, nil otherwise
	private func resolvedPosition(explicit explicitPosition: BoneToast.Position? = nil) -> BoneToast.Position? {
		if positionOption.isForced {
			return positionOption.forcedPosition
		}
		return explicitPosition
	}

	private func showStandardToast(_ toast: StandardToast) {
		if presentationMode.isGlobal {
			BoneToastManager.show(toast)
		} else if useManager, let manager = toastManager {
			manager.show(toast)
		} else {
			singleToast = toast
			showSingleToast = true
		}
	}

	private func startProgressToast(shouldFail: Bool) {
		let toast = ProgressToast(
			"Downloading...",
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulateProgress(for: shownToast, shouldFail: shouldFail)
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulateProgress(for: shownToast, shouldFail: shouldFail)
		} else {
			progressToast = toast
			showProgressToast = true
			simulateProgress(for: toast, shouldFail: shouldFail)
		}
	}

	private func startStyledProgressToast() {
		// Create toast with custom symbols for ALL phases to test .replace transitions
		// Note: Using base CompletableToast since custom symbols don't support variable fill
		let toast = CompletableToast(
			text: BoneToast.TextConfig("Uploading..."),
			activeConfig: ToastPhaseConfig(title: "Uploading...", symbol: .symbol("icloud.and.arrow.up")),
			pendingConfig: ToastPhaseConfig(title: "Preparing upload...", symbol: .symbol("doc.badge.clock")),
			successConfig: ToastPhaseConfig(
				symbol: .symbol("icloud.and.arrow.up.fill"),
				backgroundStyle: .glass(tintColor: .blue),
				fontColor: .white
			),
			failureConfig: ToastPhaseConfig(
				symbol: .symbol("icloud.slash.fill"),
				backgroundStyle: .glass(tintColor: .red),
				fontColor: .white
			),
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		// Use activity-style simulation since custom symbols don't use progress fill
		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else {
			activityToast = toast  // Stored in activity slot since it behaves like an activity toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: Bool.random())
		}
	}

	private func startPendingProgressToast(shouldFail: Bool) {
		let toast = ProgressToast(
			"Downloading...",
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
			position: resolvedPosition(),
			pendingConfig: ToastPhaseConfig(title: "Connecting to server..."),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingProgress(for: shownToast, shouldFail: shouldFail)
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingProgress(for: shownToast, shouldFail: shouldFail)
		} else {
			progressToast = toast
			showProgressToast = true
			simulatePendingProgress(for: toast, shouldFail: shouldFail)
		}
	}

	private func simulatePendingProgress(for toast: ProgressToast, shouldFail: Bool) {
		Task {
			// Simulate API connection delay (1.5 seconds in pending state)
			try? await Task.sleep(for: .seconds(1.5))

			// Transition from pending → active
			await MainActor.run {
				toast.start()
			}

			// Simulate progress
			let maxProgress = shouldFail ? 60 : 99
			for i in 1...maxProgress {
				try? await Task.sleep(for: .milliseconds(30))
				await MainActor.run {
					withAnimation(.linear(duration: 0.03)) {
						toast.progress = Double(i) / 100.0
					}
				}
			}

			// Complete or fail
			await MainActor.run {
				if shouldFail {
					toast.fail(message: "Failed!")
				} else {
					toast.complete(message: "Complete!")
				}
			}
		}
	}

	private func simulateProgress(for toast: ProgressToast, shouldFail: Bool = false) {
		Task {
			// Small delay to ensure view is fully initialized before transitioning
			try? await Task.sleep(for: .milliseconds(100))

			// Transition from pending → active (if in pending state)
			await MainActor.run {
				toast.start()
			}

			// Use smaller increments (1%) with shorter intervals for smoother animation
			let maxProgress = shouldFail ? 60 : 99
			for i in 1...maxProgress {
				try? await Task.sleep(for: .milliseconds(30))
				await MainActor.run {
					withAnimation(.linear(duration: 0.03)) {
						toast.progress = Double(i) / 100.0
					}
				}
			}
			// Complete or fail based on parameter
			await MainActor.run {
				if shouldFail {
					toast.fail(message: "Failed!")
				} else {
					toast.complete(message: "Complete!")
				}
			}
		}
	}

	private func startActivityToast(duration: TimeInterval, shouldFail: Bool = false) {
		let toast = ActivityToast(
			"Processing...",
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .orange),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulateActivity(for: shownToast, duration: duration, shouldFail: shouldFail)
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulateActivity(for: shownToast, duration: duration, shouldFail: shouldFail)
		} else {
			activityToast = toast
			showActivityToast = true
			simulateActivity(for: toast, duration: duration, shouldFail: shouldFail)
		}
	}

	private func startStyledActivityToast() {
		// Create toast with custom symbols for ALL phases to test .replace transitions
		let toast = CompletableToast(
			text: BoneToast.TextConfig("Syncing..."),
			activeConfig: ToastPhaseConfig(title: "Syncing...", symbol: .symbol("arrow.trianglehead.2.clockwise")),
			pendingConfig: ToastPhaseConfig(title: "Waiting for connection...", symbol: .symbol("wifi.exclamationmark")),
			successConfig: ToastPhaseConfig(
				symbol: .symbol("checkmark.seal.fill"),
				backgroundStyle: .glass(tintColor: .green),
				fontColor: .white
			),
			failureConfig: ToastPhaseConfig(
				symbol: .symbol("xmark.seal.fill"),
				backgroundStyle: .glass(tintColor: .red),
				fontColor: .white
			),
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else {
			activityToast = toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: Bool.random())
		}
	}

	private func startPendingActivityToast(shouldFail: Bool) {
		let toast = ActivityToast(
			"Processing...",
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .orange),
			position: resolvedPosition(),
			pendingConfig: ToastPhaseConfig(title: "Preparing request..."),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: shouldFail)
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: shouldFail)
		} else {
			activityToast = toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: shouldFail)
		}
	}

	private func simulatePendingActivity(for toast: CompletableToast, shouldFail: Bool) {
		Task {
			// Simulate API connection delay (1.5 seconds in pending state)
			try? await Task.sleep(for: .seconds(1.5))

			// Manually start the activity (transitions from pending → active)
			await MainActor.run {
				toast.start()
			}

			// Simulate activity duration (longer to observe spinner effect)
			try? await Task.sleep(for: .seconds(4.0))

			// Complete or fail
			await MainActor.run {
				if shouldFail {
					toast.fail(message: "Error!")
				} else {
					toast.complete(message: "Done!")
				}
			}
		}
	}

	private func startNetworkActivityToast() {
		let toast = ActivityToast(
			"Fetching data...",
			style: .network,
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: .blue),
			position: resolvedPosition(),
			pendingConfig: ToastPhaseConfig(title: "Connecting...")
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else {
			activityToast = toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: Bool.random())
		}
	}

	private func simulateActivity(for toast: CompletableToast, duration: TimeInterval, shouldFail: Bool = false) {
		Task {
			// Small delay to ensure view is fully initialized before transitioning
			try? await Task.sleep(for: .milliseconds(100))

			// Transition from pending → active (if in pending state)
			await MainActor.run {
				toast.start()
			}

			// Simulate activity duration
			try? await Task.sleep(for: .seconds(duration))

			// Complete or fail
			await MainActor.run {
				if shouldFail {
					toast.fail(message: "Error!")
				} else {
					toast.complete(message: "Done!")
				}
			}
		}
	}

	private func startCustomSymbolActivityToast() {
		// Completable toast with custom SF Symbol styling closures for all phases
		// Using ToastPhaseConfig.custom() for each phase with custom styling
		// This preserves Image identity for smooth .replace transitions
		// Uses .downUp for smoother transitions with variableColor animations
		let toast = CompletableToast(
			text: BoneToast.TextConfig("Syncing files..."),
			activeConfig: ToastPhaseConfig.custom(
				"arrow.triangle.2.circlepath",
				title: "Syncing files...",
				hasEffect: true,
				replaceFallback: .downUp
			) { image, effectEnabled in
				// Active: blue with custom variable color effect
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.blue)
					.font(.system(size: 18, weight: .semibold))
					.symbolEffect(
						.variableColor.iterative.dimInactiveLayers.nonReversing,
						options: .repeat(.continuous),
						isActive: effectEnabled
					)
			},
			pendingConfig: ToastPhaseConfig.custom(
				"ellipsis.circle",
				title: "Connecting to iCloud...",
				hasEffect: true,
				replaceFallback: .downUp
			) { image, effectEnabled in
				// Pending: gray with custom variable color effect
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.gray)
					.font(.system(size: 18, weight: .semibold))
					.symbolEffect(
						.variableColor.iterative.dimInactiveLayers.nonReversing,
						options: .repeat(.continuous),
						isActive: effectEnabled
					)
			},
			successConfig: ToastPhaseConfig.custom(
				"wifi",  // Using wifi for distinctive variableColor animation (bars animate sequentially)
				hasEffect: true,
				replaceFallback: .downUp
			) { image, effectEnabled in
				// Success: green with variable color
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.green)
					.font(.system(size: 18, weight: .semibold))
					.symbolEffect(
						.variableColor.iterative.dimInactiveLayers.nonReversing,
						options: .repeat(.continuous),
						isActive: effectEnabled
					)
			},
			failureConfig: ToastPhaseConfig.custom(
				"xmark.circle",
				hasEffect: true,
				replaceFallback: .downUp
			) { image, effectEnabled in
				// Failure: red with variable color
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.red)
					.font(.system(size: 18, weight: .semibold))
					.symbolEffect(
						.variableColor.iterative.dimInactiveLayers.nonReversing,
						options: .repeat(.continuous),
						isActive: effectEnabled
					)
			},
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else {
			activityToast = toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: Bool.random())
		}
	}

	private func startCustomSymbolProgressToast() {
		// Toast with custom SF Symbol styling closures for all phases
		// Using ToastPhaseConfig.custom() for each phase
		// Note: Using base CompletableToast since custom symbols don't support variable fill
		let toast = CompletableToast(
			text: BoneToast.TextConfig("Uploading photos..."),
			activeConfig: ToastPhaseConfig.custom("photo.stack", title: "Uploading photos...") { image, _ in
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.orange)
					.font(.system(size: 18, weight: .semibold))
			},
			pendingConfig: ToastPhaseConfig.custom("photo.badge.arrow.down", title: "Preparing photos...") { image, _ in
				image
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.gray)
					.font(.system(size: 18, weight: .semibold))
			},
			successConfig: ToastPhaseConfig.custom("photo.stack.fill") { image, _ in
				image
					.symbolRenderingMode(.multicolor)
					.font(.system(size: 18, weight: .semibold))
			},
			failureConfig: ToastPhaseConfig.custom("photo.badge.exclamationmark.fill") { image, _ in
				image
					.symbolRenderingMode(.palette)
					.foregroundStyle(.white, .red)
					.font(.system(size: 18, weight: .semibold))
			},
			backgroundStyle: backgroundStyleOption.backgroundStyle(tintColor: nil),
			position: resolvedPosition(),
			cornerStyle: cornerStyle.style ?? .capsule
		)

		// Use activity-style simulation since custom symbols don't use progress fill
		if presentationMode.isGlobal {
			let shownToast = BoneToastManager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else if useManager, let manager = toastManager {
			let shownToast = manager.show(toast)
			simulatePendingActivity(for: shownToast, shouldFail: Bool.random())
		} else {
			activityToast = toast  // Stored in activity slot since it behaves like an activity toast
			showActivityToast = true
			simulatePendingActivity(for: toast, shouldFail: Bool.random())
		}
	}
}

// MARK: - Helper Modifier

private struct OptionalScopedToastContainerModifier: ViewModifier {
	let manager: BoneToastManager?

	func body(content: Content) -> some View {
		if let manager = manager {
			content.scopedToastContainer(manager: manager)
		} else {
			content
		}
	}
}

// MARK: - Preview

#Preview {
	BoneToastTestView()
}
