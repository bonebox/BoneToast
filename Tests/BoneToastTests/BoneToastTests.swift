import Testing
import SwiftUI
@testable import BoneToast

/// Renders a toast and returns the line count SwiftUI's layout produces. Uses
/// `UIHostingController.sizeThatFits` to drive an actual layout pass — the same engine that
/// renders the toast on screen — so tests reflect what the user will see.
@MainActor
private func renderedLineCount(
	for toast: StandardToast,
	containerWidth: CGFloat = 393
) async -> Int {
	let tracker = BoneToastLineCountTracker()

	// Mirror the toast view's layering: content + edge padding, with the line-count tracker
	// injected via environment so the internal Layout reports back to it.
	let view = toast.content
		.environment(\.boneToastLineCountTracker, tracker)
		.frame(maxWidth: .infinity)
		.padding(.horizontal, 16)

	let host = UIHostingController(rootView: view)
	host.view.frame = CGRect(x: 0, y: 0, width: containerWidth, height: 0)
	let fitted = host.sizeThatFits(in: CGSize(width: containerWidth, height: 0))
	host.view.frame = CGRect(x: 0, y: 0, width: containerWidth, height: fitted.height)
	host.view.layoutIfNeeded()

	// `lineCount` is updated by a deferred `Task { @MainActor in ... }` inside the Layout, so
	// we yield a few times to let those tasks run before reading.
	for _ in 0..<10 where tracker.lineCount == nil {
		await Task.yield()
	}
	return tracker.lineCount ?? 1
}

@MainActor
private func resolvedCornerStyle(for toast: StandardToast, containerWidth: CGFloat = 393) async -> BoneToast.CornerStyle {
	let lines = await renderedLineCount(for: toast, containerWidth: containerWidth)
	return resolveCornerStyle(override: toast.cornerStyleOverride, measuredLineCount: lines) ?? .capsule
}

@Suite("Adaptive corner style — SwiftUI render-time measurement")
@MainActor
struct AdaptiveCornerStyleTests {

	@Test("Single line title alone is a capsule")
	func singleLineTitleIsCapsule() async {
		let toast = StandardToast(text: BoneToast.TextConfig("Quick update"))
		switch await resolvedCornerStyle(for: toast) {
			case .capsule: break
			case .roundedRect(let r): Issue.record("expected .capsule, got .roundedRect(\(r))")
		}
	}

	@Test("Title + 1-line subtitle (≤2 total lines) is a capsule")
	func titleAndShortSubtitleIsCapsule() async {
		let toast = StandardToast(text: BoneToast.TextConfig(
			title: "Saved",
			subtitle: "All set."
		))
		switch await resolvedCornerStyle(for: toast) {
			case .capsule: break
			case .roundedRect(let r): Issue.record("expected .capsule, got .roundedRect(\(r))")
		}
	}

	@Test("Long title that wraps to 3+ lines is a roundedRect")
	func wrappingTitleIsRoundedRect() async {
		let toast = StandardToast(text: BoneToast.TextConfig(
			"This is an unusually long single-line title that will absolutely wrap to multiple lines on any phone in portrait, easily three or more.",
			lineLimit: nil
		))
		switch await resolvedCornerStyle(for: toast) {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect for wrapping title, got .capsule")
		}
	}

	// The original failing case: 1-line title + multi-line subtitle wrapped by an action button.
	// SwiftUI's wrap is the source of truth here, so the corner style and the visible wrapping
	// always agree — no NSAttributedString drift.
	@Test("1-line title + multi-line subtitle + action button is a roundedRect")
	func subtitleWrapsBecauseOfActionButtonProducesRoundedRect() async {
		let button = BoneToast.ActionButton("Undo", action: {})
		let toast = StandardToast(
			text: BoneToast.TextConfig(
				title: "Item moved",
				subtitle: "Tap undo within five seconds to restore the item to its original location."
			),
			actionButton: button
		)
		switch await resolvedCornerStyle(for: toast) {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect (subtitle wraps when button steals width), got .capsule")
		}
	}

	@Test("Custom larger font causes earlier wrapping")
	func customLargerFontWraps() async {
		let toast = StandardToast(text: BoneToast.TextConfig(
			title: "A moderately long title that probably fits on a single line at default size",
			titleFont: .system(size: 32, weight: .bold),
			titleLineLimit: nil,
			subtitle: nil
		))
		switch await resolvedCornerStyle(for: toast) {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect for 32pt title at iPhone width, got .capsule")
		}
	}

	@Test("Explicit cornerStyle override wins over measurement")
	func overrideWinsOverMeasurement() async {
		let toast = StandardToast(
			text: BoneToast.TextConfig("Anything"),
			cornerStyle: .roundedRect(cornerRadius: 12)
		)
		switch await resolvedCornerStyle(for: toast) {
			case .roundedRect(let r): #expect(r == 12)
			case .capsule: Issue.record("expected explicit override to win")
		}
	}
}

@Suite("Dismiss delay")
@MainActor
struct DismissDelayTests {

	@Test("Single line → 3.0s")
	func oneLine() {
		#expect(BoneToast.StandardDismiss.calculatedDelay(lineCount: 1) == 3.0)
	}

	@Test("Two lines → 3.5s")
	func twoLines() {
		#expect(BoneToast.StandardDismiss.calculatedDelay(lineCount: 2) == 3.5)
	}

	@Test("Five lines → 5.0s")
	func fiveLines() {
		#expect(BoneToast.StandardDismiss.calculatedDelay(lineCount: 5) == 5.0)
	}

	@Test("Auto-style toast without explicit delay declares dismissDelayDependsOnRender")
	func autoToastDependsOnRender() {
		let toast = StandardToast(text: BoneToast.TextConfig("Hi"))
		#expect(toast.dismissDelayDependsOnRender == true)
	}

	@Test("Toast with explicit delay does not depend on render")
	func explicitDelayDoesNotDependOnRender() {
		let toast = StandardToast(text: BoneToast.TextConfig("Hi"), dismiss: .auto(delay: 5.0))
		#expect(toast.dismissDelayDependsOnRender == false)
	}

	@Test("Toast with action button does not depend on render")
	func actionButtonDoesNotDependOnRender() {
		let toast = StandardToast(
			text: BoneToast.TextConfig("Hi"),
			actionButton: BoneToast.ActionButton("OK", action: {})
		)
		#expect(toast.dismissDelayDependsOnRender == false)
	}
}

@Suite("Uniqueness")
@MainActor
struct UniquenessTests {

	private func makeManager() -> BoneToastManager {
		BoneToastManager() // scoped instance — uses the same show/dismiss path as the global one
	}

	// MARK: - .ignore strategy

	@Test("Unique toast with .ignore shows when no duplicate is present")
	func ignoreShowsWhenNoDuplicate() {
		let manager = makeManager()
		manager.show(StandardToast("Hello", uniqueness: .ignore))
		#expect(manager.toasts.count == 1)
	}

	@Test("Unique toast with .ignore is dropped when a title-matching duplicate exists")
	func ignoreDropsTitleDuplicate() {
		let manager = makeManager()
		let first = StandardToast("Hello")
		manager.show(first)
		manager.show(StandardToast("Hello", uniqueness: .ignore))
		#expect(manager.toasts.count == 1)
		#expect(manager.toasts.first?.id == first.id) // existing toast retained
	}

	// MARK: - .replace strategy

	@Test("Unique toast with .replace dismisses the existing duplicate and shows the new one")
	func replaceSwapsDuplicate() {
		let manager = makeManager()
		let first = StandardToast("Hello")
		manager.show(first)
		let second = StandardToast("Hello", uniqueness: .replace)
		manager.show(second)
		#expect(manager.toasts.count == 1)
		#expect(manager.toasts.first?.id == second.id) // new toast replaces existing
	}

	@Test("Unique toast with .replace appends normally when no duplicate exists")
	func replaceAppendsWhenNoDuplicate() {
		let manager = makeManager()
		manager.show(StandardToast("Different message"))
		let unique = StandardToast("New message", uniqueness: .replace)
		manager.show(unique)
		#expect(manager.toasts.count == 2)
	}

	// MARK: - .auto match resolution

	@Test(".auto compares title only when no subtitle is set")
	func autoUsesTitleWhenNoSubtitle() {
		let manager = makeManager()
		manager.show(StandardToast("Saved"))
		// Auto resolves to .title since the new toast has no subtitle — collides with the first.
		manager.show(StandardToast("Saved", uniqueness: .ignore))
		#expect(manager.toasts.count == 1)
	}

	@Test(".auto compares title + subtitle when the new toast has a subtitle")
	func autoUsesTitleAndSubtitleWhenSubtitlePresent() {
		let manager = makeManager()
		manager.show(StandardToast(text: BoneToast.TextConfig(title: "Saved", subtitle: "First copy")))
		// Same title, different subtitle: .auto resolves to .titleAndSubtitle, so this is NOT a duplicate.
		manager.show(StandardToast(
			text: BoneToast.TextConfig(title: "Saved", subtitle: "Different copy"),
			uniqueness: BoneToast.Uniqueness() // default match: .auto, strategy: .ignore
		))
		#expect(manager.toasts.count == 2)
	}

	@Test(".auto matches when both title and subtitle agree")
	func autoMatchesWhenBothAgree() {
		let manager = makeManager()
		manager.show(StandardToast(text: BoneToast.TextConfig(title: "Saved", subtitle: "All set")))
		manager.show(StandardToast(
			text: BoneToast.TextConfig(title: "Saved", subtitle: "All set"),
			uniqueness: .ignore
		))
		#expect(manager.toasts.count == 1)
	}

	// MARK: - Explicit .title / .titleAndSubtitle

	@Test(".title matches across differing subtitles")
	func titleIgnoresSubtitle() {
		let manager = makeManager()
		manager.show(StandardToast(text: BoneToast.TextConfig(title: "Saved", subtitle: "First")))
		manager.show(StandardToast(
			text: BoneToast.TextConfig(title: "Saved", subtitle: "Second"),
			uniqueness: BoneToast.Uniqueness(match: .title, strategy: .ignore)
		))
		#expect(manager.toasts.count == 1)
	}

	@Test(".titleAndSubtitle differentiates toasts with same title and different subtitle")
	func titleAndSubtitleDifferentiatesBySubtitle() {
		let manager = makeManager()
		manager.show(StandardToast(text: BoneToast.TextConfig(title: "Hello", subtitle: "A")))
		manager.show(StandardToast(
			text: BoneToast.TextConfig(title: "Hello", subtitle: "B"),
			uniqueness: BoneToast.Uniqueness(match: .titleAndSubtitle, strategy: .ignore)
		))
		#expect(manager.toasts.count == 2)
	}

	// MARK: - .key symmetry

	@Test(".key matches only when existing toast uses the same .key value")
	func keyRequiresSymmetricOptIn() {
		let manager = makeManager()
		// Existing toast has matching title text but no .key — should NOT match a .key("auth") toast.
		manager.show(StandardToast("Auth error"))
		manager.show(StandardToast(
			"Auth error",
			uniqueness: BoneToast.Uniqueness(match: .key("auth"), strategy: .ignore)
		))
		#expect(manager.toasts.count == 2)
	}

	@Test(".key matches across different text when both sides use the same key")
	func keyMatchesAcrossDifferentText() {
		let manager = makeManager()
		manager.show(StandardToast(
			"First error",
			uniqueness: BoneToast.Uniqueness(match: .key("auth"), strategy: .ignore)
		))
		manager.show(StandardToast(
			"Different wording, same error",
			uniqueness: BoneToast.Uniqueness(match: .key("auth"), strategy: .replace)
		))
		#expect(manager.toasts.count == 1)
		#expect((manager.toasts.first as? StandardToast)?.textConfig.title == "Different wording, same error")
	}

	@Test(".key does not match different keys")
	func differentKeysDoNotMatch() {
		let manager = makeManager()
		manager.show(StandardToast(
			"First",
			uniqueness: BoneToast.Uniqueness(match: .key("a"), strategy: .ignore)
		))
		manager.show(StandardToast(
			"Second",
			uniqueness: BoneToast.Uniqueness(match: .key("b"), strategy: .ignore)
		))
		#expect(manager.toasts.count == 2)
	}

	// MARK: - Default behavior

	@Test("Non-unique toast coexists with anything")
	func nonUniqueToastIgnoresCollisions() {
		let manager = makeManager()
		manager.show(StandardToast("Same"))
		manager.show(StandardToast("Same")) // no uniqueness — duplicates allowed
		#expect(manager.toasts.count == 2)
	}
}
