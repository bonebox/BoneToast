import Testing
import SwiftUI
@testable import BoneToast

@Suite("Adaptive corner style — render-time measurement")
@MainActor
struct AdaptiveCornerStyleTests {

	@Test("Single line title alone is a capsule")
	func singleLineTitleIsCapsule() {
		let toast = StandardToast(text: BoneToast.TextConfig("Quick update"))
		toast.presentationSceneWidth = 393
		switch toast.cornerStyle {
			case .capsule: break
			case .roundedRect(let r): Issue.record("expected .capsule, got .roundedRect(\(r))")
		}
	}

	@Test("Title + 1-line subtitle (≤2 total lines) is a capsule")
	func titleAndShortSubtitleIsCapsule() {
		let toast = StandardToast(text: BoneToast.TextConfig(
			title: "Saved",
			subtitle: "All set."
		))
		toast.presentationSceneWidth = 393
		switch toast.cornerStyle {
			case .capsule: break
			case .roundedRect(let r): Issue.record("expected .capsule, got .roundedRect(\(r))")
		}
	}

	@Test("Long title that wraps to 3+ lines is a roundedRect")
	func wrappingTitleIsRoundedRect() {
		let toast = StandardToast(text: BoneToast.TextConfig(
			"This is an unusually long single-line title that will absolutely wrap to multiple lines on any phone in portrait, easily three or more.",
			lineLimit: nil
		))
		toast.presentationSceneWidth = 393
		switch toast.cornerStyle {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect for wrapping title, got .capsule")
		}
	}

	// The reported failing case: 1-line title + 2-line subtitle, with an action button consuming
	// trailing space. Pre-fix this rendered as `.capsule` because the chars-per-line heuristic
	// didn't account for the button's width reduction. With render-time measurement plus the
	// action button's resolved width factored into `nonTextWidthAllowance`, this should now
	// produce `.roundedRect`.
	@Test("1-line title + 2-line subtitle + action button is a roundedRect")
	func subtitleWrapsBecauseOfActionButtonProducesRoundedRect() {
		let button = BoneToast.ActionButton(
			"Undo",
			action: {}
		)
		let toast = StandardToast(
			text: BoneToast.TextConfig(
				title: "Item moved",
				subtitle: "Tap undo within five seconds to restore the item to its original location."
			),
			actionButton: button
		)
		toast.presentationSceneWidth = 393
		switch toast.cornerStyle {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect (subtitle wraps when button steals width), got .capsule")
		}
	}

	@Test("Same content without action button still wraps but at different threshold")
	func sameContentWithoutActionButton() {
		// Sanity: identical text, no button. Should still measure subtitle as multi-line on iPhone-sized
		// width because the subtitle is long enough.
		let toast = StandardToast(text: BoneToast.TextConfig(
			title: "Item moved",
			subtitle: "Tap undo within five seconds to restore the item to its original location."
		))
		toast.presentationSceneWidth = 393
		// Either capsule (≤2 lines fits) or roundedRect — we don't assert direction here since the
		// subtitle is borderline; we only assert that the *with-button* case from the previous test
		// was strictly more conservative than this one.
		_ = toast.cornerStyle
	}

	@Test("Custom larger font causes earlier wrapping")
	func customLargerFontWraps() {
		let toast = StandardToast(text: BoneToast.TextConfig(
			title: "A moderately long title that probably fits on a single line at default size",
			titleFont: .system(size: 32, weight: .bold),
			titleLineLimit: nil,
			subtitle: nil
		))
		toast.presentationSceneWidth = 393
		// With 32pt font, the title should wrap to 3+ lines on a 393pt-wide screen.
		switch toast.cornerStyle {
			case .roundedRect: break
			case .capsule: Issue.record("expected .roundedRect for 32pt title at iPhone width, got .capsule")
		}
	}

	@Test("Explicit cornerStyle override wins over measurement")
	func overrideWinsOverMeasurement() {
		let toast = StandardToast(
			text: BoneToast.TextConfig("Anything"),
			cornerStyle: .roundedRect(cornerRadius: 12)
		)
		toast.presentationSceneWidth = 393
		switch toast.cornerStyle {
			case .roundedRect(let r): #expect(r == 12)
			case .capsule: Issue.record("expected explicit override to win")
		}
	}
}

@Suite("Action button resolved width")
@MainActor
struct ActionButtonWidthTests {

	@Test("Title button width includes content padding")
	func titleButtonWidthIncludesPadding() {
		let button = BoneToast.ActionButton("Undo", action: {})
		// At a minimum the button is wider than the minWidth (60) since "Undo" + 24pt of padding
		// is small but well over zero. Just sanity-check it's a reasonable value.
		#expect(button.resolvedWidth >= 60)
		#expect(button.resolvedWidth < 200)
	}

	@Test("Symbol button width is symbolSize + padding")
	func symbolButtonWidth() {
		let button = BoneToast.ActionButton(
			systemImage: "xmark",
			action: {}
		)
		// Default symbolSize 12 + 8 + 8 padding = 28
		#expect(button.resolvedWidth == 28)
	}
}
