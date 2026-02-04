//
//  BoneToast.swift
//  MarketKit
//
//  Copyright © 2025 Allogy Interactive. All rights reserved.
//

import SwiftUI

// MARK: - BoneToast Namespace

/// Namespace for all toast configuration types
public enum BoneToast {
	
	// MARK: - Position
	
	public enum Position: Sendable {
		case top
		case bottom
	}
	
	// MARK: - Toast Padding
	
	public enum Padding: Equatable, Sendable {
		case none
		case systemDefault
		case custom(EdgeInsets)
		
		public static func all(_ value: CGFloat) -> BoneToast.Padding {
			.custom(EdgeInsets(top: value, leading: value, bottom: value, trailing: value))
		}
		
		public static func horizontal(_ value: CGFloat) -> BoneToast.Padding {
			.custom(EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value))
		}
		
		public static func vertical(_ value: CGFloat) -> BoneToast.Padding {
			.custom(EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0))
		}
		
		public static func edges(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> BoneToast.Padding {
			.custom(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
		}
	}
	
	// MARK: - Corner Style
	
	public enum CornerStyle: Equatable, Sendable {
		case capsule
		case roundedRect(cornerRadius: CGFloat)
	}
	
	// MARK: - Toast Background Style
	
	/// The glass effect style to use (iOS 26+ only)
	public enum EffectStyle: Sendable {
		/// Regular glass effect with subtle blur and translucency
		case regular
		/// Clear glass effect with minimal tint
		case clear
	}
	
	// MARK: - Adaptive Color
	
	/// A color that can adapt to light/dark mode
	public enum AdaptiveColor: Sendable {
		/// A single color used in both light and dark modes
		case fixed(Color)
		/// Different colors for light and dark modes
		case adaptive(light: Color, dark: Color)
		
		/// Resolves the color for the given color scheme
		func resolved(for colorScheme: ColorScheme) -> Color {
			switch self {
				case .fixed(let color):
					return color
				case .adaptive(light: let light, dark: let dark):
					return colorScheme == .dark ? dark : light
			}
		}
	}
	
	// MARK: - Toast Border Style
	
	/// Border style configuration for solid toast backgrounds
	public enum BorderStyle: Sendable {
		/// No border
		case none
		
		/// Bordered with customizable border color
		/// - Parameter color: Border color (default: semi-transparent white that adapts to color scheme)
		case bordered(color: BoneToast.AdaptiveColor?)
		
		/// Default bordered style with system-adaptive colors
		public static var bordered: BoneToast.BorderStyle {
			.bordered(color: nil)
		}
		
		/// Default border color for toasts WITH a background color
		/// Semi-transparent white that provides subtle edge definition
		static func defaultColoredBorderColor(for colorScheme: ColorScheme) -> Color {
			colorScheme == .dark
			? Color.white.opacity(0.25)
			: Color.white.opacity(0.2)
		}
		
		/// Default border color for toasts WITHOUT a background color (default background)
		/// Needs different treatment since the background is neutral
		static func defaultNeutralBorderColor(for colorScheme: ColorScheme) -> Color {
			colorScheme == .dark
			? Color.white.opacity(0.08)
			: Color.white.opacity(0.8)
		}
	}
	
	/// Controls the background appearance of a toast
	public enum BackgroundStyle: Sendable {
		/// Uses iOS 26 liquid glass effect. Falls back to solid on older iOS versions.
		/// - Parameters:
		///   - style: The glass effect style (.regular or .clear)
		///   - tintColor: Optional tint color applied to the glass. If nil, no tint is applied.
		case glass(style: BoneToast.EffectStyle, tintColor: Color?)
		
		/// Uses a solid background color (works on all iOS versions)
		/// - Parameters:
		///   - color: Optional background color. If nil, uses a system-adaptive default.
		///   - border: Border style configuration. Default is `.bordered` with system colors.
		case solid(color: Color?, border: BoneToast.BorderStyle)
		
		/// Convenience for creating a glass background with default regular style and optional tint
		public static func glass(tintColor: Color? = nil) -> BoneToast.BackgroundStyle {
			.glass(style: .regular, tintColor: tintColor)
		}
		
		/// Default glass style without tint
		public static var glass: BoneToast.BackgroundStyle {
			.glass(style: .regular, tintColor: nil)
		}
		
		/// Convenience for creating a solid background with default border
		public static func solid(_ color: Color? = nil) -> BoneToast.BackgroundStyle {
			.solid(color: color, border: .bordered)
		}
		
		/// Convenience for creating a solid background with no border
		public static func solidNoBorder(_ color: Color? = nil) -> BoneToast.BackgroundStyle {
			.solid(color: color, border: .none)
		}
		
		/// Returns whether this background style has a tint/background color specified
		public var hasColor: Bool {
			switch self {
				case .glass(style: _, tintColor: let color):
					return color != nil
				case .solid(color: let color, border: _):
					return color != nil
			}
		}
		
		/// Returns the appropriate default font color for this background style
		/// - White for backgrounds with color (good contrast on colored backgrounds)
		/// - Primary for backgrounds without color (adapts to light/dark mode)
		public var defaultFontColor: Color {
			hasColor ? .white : .primary
		}
		
		/// Creates a new background style with the specified tint color, preserving the style type
		public func withTint(_ color: Color) -> BoneToast.BackgroundStyle {
			switch self {
				case .glass(let style, _):
					return .glass(style: style, tintColor: color)
				case .solid(_, let border):
					return .solid(color: color, border: border)
			}
		}
	}
	
	// MARK: - Toast Text Alignment
	
	public enum TextAlignment: Sendable {
		case leading
		case center
		case trailing
		
		var horizontalAlignment: HorizontalAlignment {
			switch self {
				case .leading: .leading
				case .center: .center
				case .trailing: .trailing
			}
		}
		
		var textAlignment: SwiftUI.TextAlignment {
			switch self {
				case .leading: .leading
				case .center: .center
				case .trailing: .trailing
			}
		}
	}
	
	// MARK: - Toast Button Shape
	
	/// Shape options for toast action buttons
	public enum ButtonShape: Equatable, Sendable {
		case capsule
		case circle
		case roundedRect(cornerRadius: CGFloat)
	}
	
	// MARK: - Toast Action Button
	
	/// Configuration for an optional action button displayed on the trailing edge of a toast
	public struct ActionButton: Sendable {
		public let contentBuilder: @MainActor @Sendable () -> AnyView
		public let action: @MainActor @Sendable () -> Void
		
		// Styling
		public let backgroundStyle: BoneToast.BackgroundStyle?
		public let fontColor: Color?
		public let font: Font
		public let shape: BoneToast.ButtonShape
		public let contentPadding: EdgeInsets
		
		// Size constraints
		public let minWidth: CGFloat?
		public let maxWidth: CGFloat?
		
		// MARK: - Primary Initializer (ViewBuilder)
		
		/// Creates an action button with custom content.
		///
		/// - Parameters:
		///   - action: Action performed when button is tapped
		///   - backgroundStyle: Button background (inherits from toast if nil)
		///   - fontColor: Content color (defaults to white)
		///   - font: Font for text content
		///   - shape: Button shape
		///   - contentPadding: Internal padding
		///   - minWidth: Minimum button width (nil for no minimum)
		///   - maxWidth: Maximum button width (nil for no maximum)
		///   - content: Custom content view builder
		public init<Content: View>(
			action: @escaping @MainActor @Sendable () -> Void,
			backgroundStyle: BoneToast.BackgroundStyle? = nil,
			fontColor: Color? = nil,
			font: Font = .system(size: 14, weight: .semibold),
			shape: BoneToast.ButtonShape = .capsule,
			contentPadding: EdgeInsets = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12),
			minWidth: CGFloat? = 60,
			maxWidth: CGFloat? = nil,
			@ViewBuilder content: @escaping @MainActor () -> Content
		) {
			self.contentBuilder = { AnyView(content()) }
			self.action = action
			self.backgroundStyle = backgroundStyle
			self.fontColor = fontColor
			self.font = font
			self.shape = shape
			self.contentPadding = contentPadding
			self.minWidth = minWidth
			self.maxWidth = maxWidth
		}
		
		// MARK: - Convenience Initializer (Title String)
		
		/// Creates an action button with a text title.
		///
		/// - Parameters:
		///   - title: Button text
		///   - action: Action performed when button is tapped
		///   - backgroundStyle: Button background (inherits from toast if nil)
		///   - fontColor: Text color (defaults to white)
		///   - font: Text font
		///   - shape: Button shape (defaults to capsule for text buttons)
		///   - contentPadding: Internal padding
		///   - minWidth: Minimum button width
		///   - maxWidth: Maximum button width
		public init(
			_ title: String,
			action: @escaping @MainActor @Sendable () -> Void,
			backgroundStyle: BoneToast.BackgroundStyle? = nil,
			fontColor: Color? = nil,
			font: Font = .system(size: 14, weight: .semibold),
			shape: BoneToast.ButtonShape = .capsule,
			contentPadding: EdgeInsets = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12),
			minWidth: CGFloat? = 60,
			maxWidth: CGFloat? = nil
		) {
			let resolvedFontColor = fontColor ?? .white
			let resolvedFont = font
			self.contentBuilder = {
				AnyView(
					Text(title)
						.font(resolvedFont)
						.foregroundColor(resolvedFontColor)
				)
			}
			self.action = action
			self.backgroundStyle = backgroundStyle
			self.fontColor = fontColor
			self.font = font
			self.shape = shape
			self.contentPadding = contentPadding
			self.minWidth = minWidth
			self.maxWidth = maxWidth
		}
		
		// MARK: - Convenience Initializer (SF Symbol)
		
		/// Creates an action button with an SF Symbol icon.
		///
		/// - Parameters:
		///   - systemImage: SF Symbol name
		///   - action: Action performed when button is tapped
		///   - backgroundStyle: Button background (inherits from toast if nil)
		///   - fontColor: Icon color (defaults to white)
		///   - symbolSize: Icon size in points
		///   - symbolWeight: Icon weight
		///   - shape: Button shape (defaults to circle for icon buttons)
		///   - contentPadding: Internal padding (defaults to equal padding for circle)
		///   - minWidth: Minimum button width (nil for icon buttons)
		///   - maxWidth: Maximum button width
		public init(
			systemImage: String,
			action: @escaping @MainActor @Sendable () -> Void,
			backgroundStyle: BoneToast.BackgroundStyle? = nil,
			fontColor: Color? = nil,
			symbolSize: CGFloat = 12,
			symbolWeight: Font.Weight = .semibold,
			shape: BoneToast.ButtonShape = .circle,
			contentPadding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
			minWidth: CGFloat? = nil,
			maxWidth: CGFloat? = nil
		) {
			let resolvedFontColor = fontColor ?? .white
			self.contentBuilder = {
				AnyView(
					Image(systemName: systemImage)
						.font(.system(size: symbolSize, weight: symbolWeight))
						.foregroundColor(resolvedFontColor)
				)
			}
			self.action = action
			self.backgroundStyle = backgroundStyle
			self.fontColor = fontColor
			self.font = .system(size: symbolSize, weight: symbolWeight)
			self.shape = shape
			self.contentPadding = contentPadding
			self.minWidth = minWidth
			self.maxWidth = maxWidth
		}
	}
	
	// MARK: - Toast Text Configuration
	
	/// Configuration for toast text content including title, optional subtitle, and styling
	public struct TextConfig: Sendable {
		public let title: String
		public let titleFont: Font
		public let titleColor: Color?
		public let titleLineLimit: Int?
		
		public let subtitle: String?
		public let subtitleFont: Font
		public let subtitleColor: Color?
		public let subtitleLineLimit: Int?
		
		public let alignment: BoneToast.TextAlignment
		
		/// Estimated characters per line for title (based on typical toast width and font size)
		private static let titleCharsPerLine: Int = 35
		
		/// Estimated characters per line for subtitle (smaller font = more chars)
		private static let subtitleCharsPerLine: Int = 45
		
		/// Effective line limit for SwiftUI (converts 0 or nil to nil for unlimited)
		public var effectiveTitleLineLimit: Int? {
			guard let limit = titleLineLimit, limit > 0 else { return nil }
			return limit
		}
		
		/// Effective line limit for SwiftUI (converts 0 or nil to nil for unlimited)
		public var effectiveSubtitleLineLimit: Int? {
			guard let limit = subtitleLineLimit, limit > 0 else { return nil }
			return limit
		}
		
		/// Calculates natural line count based on text length and chars per line
		private static func naturalLineCount(for text: String, charsPerLine: Int) -> Int {
			guard !text.isEmpty else { return 0 }
			return max(1, (text.count + charsPerLine - 1) / charsPerLine)
		}
		
		/// Estimates the number of visible title lines
		/// Uses line limit if set (and > 0), otherwise estimates from text length
		public var estimatedTitleLines: Int {
			let naturalLines = Self.naturalLineCount(for: title, charsPerLine: Self.titleCharsPerLine)
			// nil or 0 means unlimited - use natural lines
			if let limit = titleLineLimit, limit > 0 {
				return min(naturalLines, limit)
			}
			return naturalLines
		}
		
		/// Estimates the number of visible subtitle lines
		/// Uses line limit if set (and > 0), otherwise estimates from text length
		public var estimatedSubtitleLines: Int {
			guard let sub = subtitle else { return 0 }
			let naturalLines = Self.naturalLineCount(for: sub, charsPerLine: Self.subtitleCharsPerLine)
			// nil or 0 means unlimited - use natural lines
			if let limit = subtitleLineLimit, limit > 0 {
				return min(naturalLines, limit)
			}
			return naturalLines
		}
		
		/// Creates a text configuration with title only
		public init(
			_ title: String,
			font: Font = .system(size: 16, weight: .semibold),
			color: Color? = nil,
			lineLimit: Int? = 2,
			alignment: BoneToast.TextAlignment = .leading
		) {
			self.title = title
			self.titleFont = font
			self.titleColor = color
			self.titleLineLimit = lineLimit
			self.subtitle = nil
			self.subtitleFont = .system(size: 14)
			self.subtitleColor = nil
			self.subtitleLineLimit = nil
			self.alignment = alignment
		}
		
		/// Creates a text configuration with title and subtitle
		/// - Parameters:
		///   - hasIcon: Whether an icon will be displayed. Used to determine default alignment.
		///              With icon: defaults to .leading. Without icon: defaults to .center.
		public init(
			title: String,
			titleFont: Font = .system(size: 16, weight: .semibold),
			titleColor: Color? = nil,
			titleLineLimit: Int? = 2,
			subtitle: String?,
			subtitleFont: Font = .system(size: 14),
			subtitleColor: Color? = nil,
			subtitleLineLimit: Int? = 2,
			alignment: BoneToast.TextAlignment? = nil,
			hasIcon: Bool = true
		) {
			self.title = title
			self.titleFont = titleFont
			self.titleColor = titleColor
			self.titleLineLimit = titleLineLimit
			self.subtitle = subtitle
			self.subtitleFont = subtitleFont
			self.subtitleColor = subtitleColor
			self.subtitleLineLimit = subtitleLineLimit
			// Default alignment: .leading if icon present, .center if no icon (when subtitle exists)
			if let alignment {
				self.alignment = alignment
			} else if subtitle != nil {
				self.alignment = hasIcon ? .leading : .center
			} else {
				self.alignment = .leading
			}
		}
	}
	
	// MARK: - Standard Toast Dismiss Behavior
	
	/// Dismiss behavior specifically for standard toasts
	public enum StandardDismiss: Sendable {
		/// Automatically dismiss after a delay
		/// - Parameter delay: If nil, calculates delay based on visible text (accounting for line limits)
		case auto(delay: TimeInterval? = nil)
		
		/// Never auto-dismiss; must be dismissed manually (tap or swipe)
		case manual
		
		/// Calculates an appropriate delay based on visible text content
		/// Uses a line-based approach determined by the configured line limits
		/// - Parameter textConfig: The text configuration to base timing on
		/// - Returns: A delay based on estimated visible lines (minimum 3.0 seconds)
		public static func calculatedDelay(for textConfig: BoneToast.TextConfig) -> TimeInterval {
			let titleLines = textConfig.estimatedTitleLines
			let subtitleLines = textConfig.estimatedSubtitleLines
			
			// Base time for first title line, then additional time per extra line
			// Title lines: 3.0s base + 0.5s per additional line
			// Subtitle lines: 0.5s per line
			let titleTime: TimeInterval = 3.0 + Double(max(0, titleLines - 1)) * 0.5
			let subtitleTime: TimeInterval = Double(subtitleLines) * 0.5
			
			let calculated = titleTime + subtitleTime
			let minTime: TimeInterval = 3.0
			
			return max(calculated, minTime)
		}
	}
	
	// MARK: - Dismiss Behavior
	
	public enum DismissBehavior: Sendable {
		/// Automatically dismiss after the specified delay
		case afterDelay(TimeInterval)
		/// Dismiss after `isReadyToDismiss` becomes true, waiting the specified delay
		case whenReady(delay: TimeInterval)
		/// Never auto-dismiss; must be dismissed manually
		case manual
		
		/// Returns whether this behavior is pinnable (afterDelay is never pinnable)
		var isPinnable: Bool {
			switch self {
				case .afterDelay: false
				case .whenReady, .manual: true
			}
		}
	}
	
	// MARK: - Toast Transition
	
	/// Controls the visual transition effect for toast appearance/disappearance
	public enum Transition: Sendable, Equatable {
		/// Slides from the edge based on toast position (top toasts slide from top, bottom from bottom)
		case slide
		
		/// Slides from a specific edge, regardless of toast position
		case move(edge: Edge)
		
		/// Scales from a smaller size with opacity fade
		/// - Parameter scale: Starting scale factor (0.0 to 1.0). Default: 0.8
		case scale(Double = 0.8)
		
		/// Simple opacity fade only
		case fade
		
		/// Custom transition for advanced use cases
		case custom(@Sendable () -> AnyTransition)
		
		/// Convenience for default scale transition
		public static var scale: BoneToast.Transition { .scale() }
		
		/// Returns the SwiftUI transition for this style based on position
		func transition(for position: BoneToast.Position) -> AnyTransition {
			switch self {
				case .slide:
					let edge: Edge = position == .top ? .top : .bottom
					// Combine move with additional offset to ensure toasts animate past the safe area
					// and fully exit the screen even when pushed by other stacked toasts
					let extraOffset: CGFloat = position == .top ? -60 : 60
					return .move(edge: edge)
						.combined(with: .offset(y: extraOffset))
						.combined(with: .opacity)
				case .move(let edge):
					// Add extra offset to ensure full screen exit for vertical edges
					let extraOffset: CGFloat
					switch edge {
						case .top: extraOffset = -60
						case .bottom: extraOffset = 60
						case .leading: extraOffset = 0
						case .trailing: extraOffset = 0
					}
					if extraOffset != 0 {
						return .move(edge: edge)
							.combined(with: .offset(y: extraOffset))
							.combined(with: .opacity)
					} else {
						return .move(edge: edge).combined(with: .opacity)
					}
				case .scale(let scale):
					return .scale(scale: scale).combined(with: .opacity)
				case .fade:
					return .opacity
				case .custom(let transitionProvider):
					return transitionProvider()
			}
		}
		
		public static func == (lhs: BoneToast.Transition, rhs: BoneToast.Transition) -> Bool {
			switch (lhs, rhs) {
				case (.slide, .slide): true
				case (.move(let e1), .move(let e2)): e1 == e2
				case (.scale(let s1), .scale(let s2)): s1 == s2
				case (.fade, .fade): true
				case (.custom, .custom): true // Custom transitions are considered equal for simplicity
				default: false
			}
		}
	}
	
	// MARK: - Toast Timing
	
	/// Controls the animation timing curve for toast transitions
	public enum Timing: Sendable, Equatable {
		/// Quick, responsive animation (similar to SwiftUI .snappy)
		case snappy
		
		/// Smooth, fluid eased animation
		case smooth
		
		/// Springy animation with bounce effect
		case bouncy
		
		/// Custom spring animation
		/// - Parameters:
		///   - response: The stiffness of the spring (lower = faster). Default: 0.3
		///   - dampingFraction: How quickly oscillations decay (lower = more bouncy). Default: 0.7
		case spring(response: Double = 0.3, dampingFraction: Double = 0.7)
		
		/// Linear eased animation with specified duration
		case easeInOut(duration: Double = 0.3)
		
		/// Custom animation for advanced use cases
		case custom(@Sendable () -> Animation)
		
		/// Convenience for default spring timing
		public static var spring: BoneToast.Timing { .spring() }
		
		/// Convenience for default easeInOut timing
		public static var easeInOut: BoneToast.Timing { .easeInOut() }
		
		/// Returns the SwiftUI Animation for this timing
		var animation: Animation {
			switch self {
				case .snappy:
					return .snappy(duration: 0.25)
				case .smooth:
					return .smooth(duration: 0.3)
				case .bouncy:
					return .bouncy(duration: 0.32, extraBounce: 0.1)
				case .spring(let response, let dampingFraction):
					return .spring(response: response, dampingFraction: dampingFraction, blendDuration: 0)
				case .easeInOut(let duration):
					return .easeInOut(duration: duration)
				case .custom(let animationProvider):
					return animationProvider()
			}
		}
		
		public static func == (lhs: BoneToast.Timing, rhs: BoneToast.Timing) -> Bool {
			switch (lhs, rhs) {
				case (.snappy, .snappy): true
				case (.smooth, .smooth): true
				case (.bouncy, .bouncy): true
				case (.spring(let r1, let d1), .spring(let r2, let d2)): r1 == r2 && d1 == d2
				case (.easeInOut(let d1), .easeInOut(let d2)): d1 == d2
				case (.custom, .custom): true
				default: false
			}
		}
	}
	
	// MARK: - Toast Animation Config
	
	/// Combines transition and timing into a single animation configuration.
	/// Provides convenient preset combinations and supports custom configurations.
	public enum AnimationConfig: Sendable, Equatable {
		// MARK: - Standard Presets
		
		/// Bouncy slide from screen edge (default). Slides in with a springy bounce.
		case bounce
		
		/// Smooth slide from screen edge. Slides in with eased timing.
		case slide
		
		/// Scale up with spring. Starts small and grows to full size.
		case scale
		
		/// Simple fade in/out. Subtle opacity-only transition.
		case fade
		
		/// Slides in from the leading edge with bounce.
		case slideFromLeading
		
		/// Slides in from the trailing edge with bounce.
		case slideFromTrailing
		
		/// Dramatic pop effect. Starts very small and pops in with bounce.
		case pop
		
		/// Very subtle appearance. Gentle fade with smooth timing.
		case subtle
		
		/// Quick snappy slide. Fast and responsive.
		case snappy
		
		// MARK: - Custom Configuration
		
		/// Custom animation configuration for advanced use cases.
		/// - Parameters:
		///   - transition: The visual transition effect
		///   - timing: The animation timing curve
		case custom(transition: BoneToast.Transition, timing: BoneToast.Timing)
		
		// MARK: - Properties
		
		/// The transition effect for this configuration
		public var transition: BoneToast.Transition {
			switch self {
				case .bounce, .slide, .snappy:
					return .slide
				case .scale:
					return .scale(0.8)
				case .fade, .subtle:
					return .fade
				case .slideFromLeading:
					return .move(edge: .leading)
				case .slideFromTrailing:
					return .move(edge: .trailing)
				case .pop:
					return .scale(0.5)
				case .custom(let transition, _):
					return transition
			}
		}
		
		/// The timing curve for this configuration
		public var timing: BoneToast.Timing {
			switch self {
				case .bounce, .slideFromLeading, .slideFromTrailing, .pop:
					return .bouncy
				case .slide, .fade:
					return .easeInOut
				case .scale:
					return .spring
				case .subtle:
					return .smooth
				case .snappy:
					return .snappy
				case .custom(_, let timing):
					return timing
			}
		}
		
		/// Default animation configuration
		public static var `default`: BoneToast.AnimationConfig { .bounce }
	}
	
	// MARK: - Toast Stack Order
	
	/// Controls how new toasts are stacked relative to existing ones
	public enum StackOrder: Sendable {
		/// Newest toasts appear closest to the screen edge, pushing older toasts away.
		/// For top position: new toasts push older ones down.
		/// For bottom position: new toasts push older ones up.
		case newestFirst
		
		/// Oldest toasts stay closest to the screen edge, new toasts appear further away.
		/// For top position: new toasts appear below older ones.
		/// For bottom position: new toasts appear above older ones.
		case oldestFirst
	}
	
	// MARK: - Toast Pinning
	
	/// Configuration for which toast types should be pinned to the top of the queue.
	/// Pinned toasts remain at the leading edge (top for top position, bottom for bottom position)
	/// while non-pinned toasts appear after them. Note: `afterDelay` toasts are never pinnable.
	public enum Pinning: Sendable {
		/// No toasts are pinned; all toasts appear in insertion order
		case none
		/// Only `manual` dismiss behavior toasts are pinned
		case manualOnly
		/// Only `whenReady` dismiss behavior toasts are pinned
		case whenReadyOnly
		/// Both `manual` and `whenReady` dismiss behavior toasts are pinned
		case manualAndWhenReady
		
		/// Returns whether a toast with the given dismiss behavior should be pinned
		func shouldPin(_ behavior: BoneToast.DismissBehavior) -> Bool {
			switch (self, behavior) {
				case (.none, _):
					return false
				case (.manualOnly, .manual):
					return true
				case (.whenReadyOnly, .whenReady):
					return true
				case (.manualAndWhenReady, .manual), (.manualAndWhenReady, .whenReady):
					return true
				default:
					return false
			}
		}
	}
	
} // end BoneToast namespace

// MARK: - View Extension

private extension View {
	@ViewBuilder
	func toastPadding(_ padding: BoneToast.Padding) -> some View {
		switch padding {
			case .none: self
			case .systemDefault: self.padding()
			case .custom(let insets): self.padding(insets)
		}
	}
}

// MARK: - Toast Protocol

/// Protocol defining the requirements for a toast that can be displayed by BoneToastManager
@MainActor
public protocol BoneToastType: AnyObject, Identifiable, Observable where ID == UUID {
	var id: UUID { get }
	var backgroundStyle: BoneToast.BackgroundStyle { get }
	var contentPadding: BoneToast.Padding { get }
	var edgePadding: BoneToast.Padding { get }
	var expandWidth: Bool { get }
	
	/// Text configuration used for adaptive corner style calculation
	var textConfig: BoneToast.TextConfig { get }
	
	/// Optional position override. When nil, uses the manager's default position.
	var positionOverride: BoneToast.Position? { get }
	
	/// Optional corner style override. When nil, uses adaptive style based on text line count.
	var cornerStyleOverride: BoneToast.CornerStyle? { get }
	
	/// Determines how and when the toast should be dismissed
	var dismissBehavior: BoneToast.DismissBehavior { get }
	
	/// For toasts with `.whenReady` dismiss behavior, indicates when the toast is ready to dismiss
	var isReadyToDismiss: Bool { get }
	
	/// Whether this toast has an action button that controls dismiss timing
	var hasActionButton: Bool { get }
	
	/// Set to true when the action button is tapped (triggers dismiss behavior)
	var actionButtonTapped: Bool { get set }
	
	/// Whether the toast can be interactively dismissed (tap/swipe).
	/// Can be toggled at any time. Defaults based on dismissBehavior:
	/// - `.manual` and `.afterDelay` default to true
	/// - `.whenReady` defaults to false
	var interactive: Bool { get set }
	
	/// Optional animation configuration for this toast. If nil, uses the manager's default.
	var animationConfig: BoneToast.AnimationConfig? { get }
	
	/// Whether the content view includes its own background styling.
	/// If true, the container will not apply an additional background.
	var contentIncludesBackground: Bool { get }
	
	/// The content view for the toast
	@ViewBuilder var content: AnyView { get }
}

public extension BoneToastType {
	/// Default implementation returns nil, meaning the manager's default will be used
	var animationConfig: BoneToast.AnimationConfig? { nil }
	
	/// Default implementation returns false, meaning the container applies the background
	var contentIncludesBackground: Bool { false }
	
	/// Default implementation returns false - most toasts don't have action buttons
	var hasActionButton: Bool { false }
	
	/// Default interactive value based on dismiss behavior
	var defaultInteractive: Bool {
		switch dismissBehavior {
			case .manual, .afterDelay: return true
			case .whenReady: return false
		}
	}
	
	/// Resolved corner style - uses override if provided, otherwise calculates based on line count
	/// Capsule for 1-2 lines, rounded rect for 3+ lines
	var cornerStyle: BoneToast.CornerStyle {
		if let override = cornerStyleOverride {
			return override
		}
		let totalLines = textConfig.estimatedTitleLines + textConfig.estimatedSubtitleLines
		return totalLines > 2 ? .roundedRect(cornerRadius: 28) : .capsule
	}
}

// MARK: - Toast Shape & Modifiers

private struct ToastBackgroundShape: Shape {
	let cornerStyle: BoneToast.CornerStyle
	
	func path(in rect: CGRect) -> Path {
		switch cornerStyle {
			case .capsule:
				return Capsule().path(in: rect)
			case .roundedRect(let cornerRadius):
				return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
		}
	}
}

private struct ToastWidthModifier: ViewModifier {
	let expandWidth: Bool
	
	func body(content: Content) -> some View {
		if expandWidth {
			content.frame(maxWidth: .infinity)
		} else {
			AdaptiveToastLayout {
				content
			}
		}
	}
}

/// A layout that sizes to fit content if it fits on a single line,
/// otherwise expands to fill available width and allows text to wrap.
private struct AdaptiveToastLayout: Layout {
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		guard let subview = subviews.first else { return .zero }
		
		let idealSize = subview.sizeThatFits(.unspecified)
		let proposedWidth = proposal.width ?? .infinity
		
		if idealSize.width <= proposedWidth {
			return idealSize
		} else {
			let constrainedSize = subview.sizeThatFits(ProposedViewSize(width: proposedWidth, height: nil))
			return CGSize(width: proposedWidth, height: constrainedSize.height)
		}
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		guard let subview = subviews.first else { return }
		subview.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
	}
}

/// Modifier that applies the appropriate background based on BoneToast.BackgroundStyle
private struct ToastBackgroundModifier: ViewModifier {
	let backgroundStyle: BoneToast.BackgroundStyle
	let cornerStyle: BoneToast.CornerStyle
	
	func body(content: Content) -> some View {
		let styledContent = content.frame(minHeight: 44) // Minimum touch target height
		switch backgroundStyle {
			case .glass(style: let glassStyle, tintColor: let tintColor):
				if #available(iOS 26.0, *) {
					styledContent.modifier(BoneEffectModifier(cornerStyle: cornerStyle, glassStyle: glassStyle, tintColor: tintColor))
				} else {
					// Fallback to solid on pre-iOS 26
					styledContent.modifier(SolidBackgroundModifier(cornerStyle: cornerStyle, color: tintColor, borderStyle: .bordered))
				}
			case .solid(color: let color, border: let borderStyle):
				styledContent.modifier(SolidBackgroundModifier(cornerStyle: cornerStyle, color: color, borderStyle: borderStyle))
		}
	}
}

/// A modifier that conditionally applies the background style.
/// Used for toasts where content may include its own background (e.g., completable toasts).
private struct ConditionalBackgroundModifier: ViewModifier {
	let applyBackground: Bool
	let backgroundStyle: BoneToast.BackgroundStyle
	let cornerStyle: BoneToast.CornerStyle
	
	func body(content: Content) -> some View {
		if applyBackground {
			content
				.frame(minHeight: 44)
				.modifier(ToastBackgroundModifier(backgroundStyle: backgroundStyle, cornerStyle: cornerStyle))
		} else {
			content
		}
	}
}

@available(iOS 26.0, *)
private struct BoneEffectModifier: ViewModifier {
	let cornerStyle: BoneToast.CornerStyle
	let glassStyle: BoneToast.EffectStyle
	let tintColor: Color?
	
	@ViewBuilder
	func body(content: Content) -> some View {
		switch cornerStyle {
			case .capsule:
				switch (glassStyle, tintColor) {
					case (.regular, .some(let color)):
						content.glassEffect(.regular.tint(color), in: Capsule())
					case (.regular, .none):
						content.glassEffect(.regular, in: Capsule())
					case (.clear, .some(let color)):
						content.glassEffect(.clear.tint(color), in: Capsule())
					case (.clear, .none):
						content.glassEffect(.clear, in: Capsule())
				}
			case .roundedRect(let cornerRadius):
				let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				switch (glassStyle, tintColor) {
					case (.regular, .some(let color)):
						content.glassEffect(.regular.tint(color), in: shape)
					case (.regular, .none):
						content.glassEffect(.regular, in: shape)
					case (.clear, .some(let color)):
						content.glassEffect(.clear.tint(color), in: shape)
					case (.clear, .none):
						content.glassEffect(.clear, in: shape)
				}
		}
	}
}

private struct SolidBackgroundModifier: ViewModifier {
	let cornerStyle: BoneToast.CornerStyle
	let color: Color?
	let borderStyle: BoneToast.BorderStyle
	@Environment(\.colorScheme) private var colorScheme
	
	/// Whether this toast has a custom background color
	private var hasCustomColor: Bool {
		color != nil
	}
	
	/// Default color that adapts to light/dark mode
	/// Light mode: slightly off-white for better visibility
	/// Dark mode: secondary system background
	private var resolvedColor: Color {
		if let color {
			return color
		}
		return colorScheme == .dark
		? Color(uiColor: .secondarySystemBackground)
		: Color(white: 0.96)
	}
	
	/// Default border color based on whether we have a custom background color
	private var defaultBorderColor: Color {
		hasCustomColor
		? BoneToast.BorderStyle.defaultColoredBorderColor(for: colorScheme)
		: BoneToast.BorderStyle.defaultNeutralBorderColor(for: colorScheme)
	}
	
	/// Shadow opacity - stronger for colored backgrounds in light mode
	private var shadowOpacity: Double {
		if hasCustomColor && colorScheme == .light {
			return 0.25
		}
		return 0.15
	}
	
	func body(content: Content) -> some View {
		content
			.background(
				ToastBackgroundShape(cornerStyle: cornerStyle)
					.fill(resolvedColor)
					.shadow(color: .black.opacity(shadowOpacity), radius: 8, x: 0, y: 4)
			)
			.overlay {
				// Light border drawn inside, on top of background
				if case .bordered(color: let borderColor) = borderStyle {
					borderView(color: borderColor?.resolved(for: colorScheme) ?? defaultBorderColor)
				}
			}
	}
	
	@ViewBuilder
	private func borderView(color: Color) -> some View {
		switch cornerStyle {
			case .capsule:
				Capsule()
					.strokeBorder(color, lineWidth: 1)
			case .roundedRect(let cornerRadius):
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
					.strokeBorder(color, lineWidth: 1)
		}
	}
}

// MARK: - Toast Action Button View

/// View that renders a BoneToast.ActionButton with styling inherited from the parent toast
@MainActor
private struct ActionButtonView: View {
	let config: BoneToast.ActionButton
	let toastBackgroundStyle: BoneToast.BackgroundStyle
	let toastFontColor: Color?
	let onDismiss: () -> Void
	
	var body: some View {
		Button {
			config.action()
			onDismiss()
		} label: {
			config.contentBuilder()
				.padding(config.contentPadding)
				.frame(minWidth: config.minWidth, maxWidth: config.maxWidth)
				.modifier(CircleAspectRatioModifier(isCircle: config.shape == .circle))
		}
		.buttonStyle(UnifiedToastButtonStyle(
			backgroundColor: effectiveBackgroundColor,
			shape: config.shape
		))
		.fixedSize(horizontal: true, vertical: false)
		// Reduce vertical space to toast edges
		.padding(.vertical, -4)
	}
	
	/// Derive background color - defaults to semi-transparent white
	private var effectiveBackgroundColor: Color {
		if let backgroundStyle = config.backgroundStyle {
			// User specified custom background
			switch backgroundStyle {
				case .glass:
					// For glass, use semi-transparent white
					return Color.white.opacity(0.2)
				case .solid(let color, _):
					return color ?? Color.white.opacity(0.2)
			}
		}
		// Default: semi-transparent white for unified appearance
		return Color.white.opacity(0.2)
	}
}

/// Modifier that applies 1:1 aspect ratio for circle buttons to ensure perfect circles
private struct CircleAspectRatioModifier: ViewModifier {
	let isCircle: Bool
	
	func body(content: Content) -> some View {
		if isCircle {
			content.aspectRatio(1, contentMode: .fit)
		} else {
			content
		}
	}
}

/// Unified button style for all toast action buttons
/// Provides consistent appearance: semi-transparent white background, white border,
/// scale-up effect on press, and background brightening on press
private struct UnifiedToastButtonStyle: ButtonStyle {
	let backgroundColor: Color
	let shape: BoneToast.ButtonShape
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.background(
				effectiveBackgroundColor(isPressed: configuration.isPressed),
				in: shapeView
			)
			.overlay {
				// Subtle white border for all buttons
				switch shape {
					case .capsule:
						Capsule()
							.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
					case .circle:
						Circle()
							.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
					case .roundedRect(let radius):
						RoundedRectangle(cornerRadius: radius, style: .continuous)
							.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
				}
			}
			.shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
		// Scale up when pressed (emulating glass button behavior)
			.scaleEffect(configuration.isPressed ? 1.1 : 1.0)
			.animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
	}
	
	private var shapeView: AnyShape {
		switch shape {
			case .capsule:
				AnyShape(Capsule())
			case .circle:
				AnyShape(Circle())
			case .roundedRect(let cornerRadius):
				AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		}
	}
	
	/// Background color with pressed state - brightens when pressed
	private func effectiveBackgroundColor(isPressed: Bool) -> Color {
		if isPressed {
			return backgroundColor.mix(with: .white, by: 0.1)
		}
		return backgroundColor
	}
}

// MARK: - Standard Toast

/// A standard toast for simple, fire-and-forget notifications.
/// Message and appearance are immutable after creation.
@Observable
@MainActor
public final class StandardToast: BoneToastType {
	public let id = UUID()
	public let textConfig: BoneToast.TextConfig
	public let systemImage: String?
	public let systemImageSize: CGFloat
	public let systemImageColor: Color?
	public let backgroundStyle: BoneToast.BackgroundStyle
	public let positionOverride: BoneToast.Position?
	public let dismissStyle: BoneToast.StandardDismiss
	public let contentPadding: BoneToast.Padding
	public let edgePadding: BoneToast.Padding
	public let cornerStyleOverride: BoneToast.CornerStyle?
	public let expandWidth: Bool
	public let actionButton: BoneToast.ActionButton?
	public let animationConfig: BoneToast.AnimationConfig?
	private let iconBuilder: (@MainActor () -> AnyView)?
	
	/// Set to true when the action button is tapped (triggers dismiss behavior)
	public var actionButtonTapped: Bool = false
	
	/// Whether the toast can be interactively dismissed (tap/swipe)
	public var interactive: Bool
	
	/// Whether this toast has an action button
	public var hasActionButton: Bool { actionButton != nil }
	
	/// Resolved title color (uses backgroundStyle default if not specified)
	public var titleColor: Color {
		textConfig.titleColor ?? backgroundStyle.defaultFontColor
	}
	
	/// Resolved subtitle color (uses backgroundStyle default with reduced opacity if not specified)
	public var subtitleColor: Color {
		textConfig.subtitleColor ?? backgroundStyle.defaultFontColor.opacity(0.85)
	}
	
	public var dismissBehavior: BoneToast.DismissBehavior {
		switch dismissStyle {
			case .auto(let delay):
				// If action button is present and no explicit delay, use brief delay (0.5s) after button tap
				if actionButton != nil && delay == nil {
					return .afterDelay(0.2)
				}
				let resolvedDelay = delay ?? BoneToast.StandardDismiss.calculatedDelay(for: textConfig)
				return .afterDelay(resolvedDelay)
			case .manual:
				return .manual
		}
	}
	
	public var isReadyToDismiss: Bool { true }
	
	// MARK: - Primary Initializer
	
	/// Creates a standard toast with full text configuration.
	///
	/// This is the designated initializer. All other initializers delegate to this one.
	///
	/// - Parameters:
	///   - text: Text configuration including title, optional subtitle, fonts, colors, and alignment
	///   - systemImage: SF Symbol name (optional)
	///   - systemImageSize: Icon size in points
	///   - systemImageColor: Icon color (defaults to text color if nil)
	///   - backgroundStyle: Background appearance (glass or solid)
	///   - position: Screen position (.top or .bottom)
	///   - dismiss: Dismiss behavior (.auto() or .manual)
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape (auto-selected based on content height if nil)
	///   - expandWidth: Whether to expand to full width
	///   - actionButton: Optional action button on trailing edge
	///   - animationConfig: Per-toast animation (uses manager default if nil)
	public init(
		text: BoneToast.TextConfig,
		systemImage: String? = nil,
		systemImageSize: CGFloat = 16,
		systemImageColor: Color? = nil,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		position: BoneToast.Position? = nil,
		dismiss: BoneToast.StandardDismiss = .auto(),
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle? = nil,
		expandWidth: Bool = false,
		actionButton: BoneToast.ActionButton? = nil,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		self.textConfig = text
		self.systemImage = systemImage
		self.systemImageSize = systemImageSize
		self.systemImageColor = systemImageColor
		self.backgroundStyle = backgroundStyle
		self.positionOverride = position
		self.dismissStyle = dismiss
		self.contentPadding = contentPadding
		self.edgePadding = edgePadding
		self.cornerStyleOverride = cornerStyle
		self.expandWidth = expandWidth
		self.actionButton = actionButton
		self.animationConfig = animationConfig
		self.iconBuilder = nil
		// Default interactive based on dismiss behavior (manual/afterDelay = true, whenReady = false)
		self.interactive = true
	}
	
	/// Creates a standard toast with full text configuration and custom icon view.
	///
	/// - Parameters:
	///   - text: Text configuration including title, optional subtitle, fonts, colors, and alignment
	///   - icon: Custom icon view builder
	///   - backgroundStyle: Background appearance (glass or solid)
	///   - position: Screen position (.top or .bottom)
	///   - dismiss: Dismiss behavior (.auto() or .manual)
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape (auto-selected based on content height if nil)
	///   - expandWidth: Whether to expand to full width
	///   - actionButton: Optional action button on trailing edge
	///   - animationConfig: Per-toast animation (uses manager default if nil)
	public init<Icon: View>(
		text: BoneToast.TextConfig,
		@ViewBuilder icon: @escaping () -> Icon,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		position: BoneToast.Position? = nil,
		dismiss: BoneToast.StandardDismiss = .auto(),
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle? = nil,
		expandWidth: Bool = false,
		actionButton: BoneToast.ActionButton? = nil,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		self.textConfig = text
		self.systemImage = nil
		self.systemImageSize = 16
		self.systemImageColor = nil
		self.backgroundStyle = backgroundStyle
		self.positionOverride = position
		self.dismissStyle = dismiss
		self.contentPadding = contentPadding
		self.edgePadding = edgePadding
		self.cornerStyleOverride = cornerStyle
		self.expandWidth = expandWidth
		self.actionButton = actionButton
		self.animationConfig = animationConfig
		self.iconBuilder = { AnyView(icon()) }
		self.interactive = true
	}
	
	// MARK: - Convenience Initializers
	
	/// Creates a simple toast with a title message.
	///
	/// This is a convenience initializer for simple single-line toasts. For toasts with
	/// subtitles or advanced text options, use `init(text:)` with a `BoneToast.TextConfig`.
	///
	/// - Parameters:
	///   - message: The toast message
	///   - systemImage: SF Symbol name (optional)
	///   - systemImageSize: Icon size in points
	///   - systemImageColor: Icon color (defaults to text color if nil)
	///   - backgroundStyle: Background appearance (glass or solid)
	///   - font: Message font
	///   - fontColor: Message color (auto-selected based on background if nil)
	///   - position: Screen position (.top or .bottom)
	///   - dismiss: Dismiss behavior (.auto() or .manual)
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape (auto-selected based on content height if nil)
	///   - expandWidth: Whether to expand to full width
	///   - textAlignment: Text alignment within the toast
	///   - actionButton: Optional action button on trailing edge
	///   - animationConfig: Per-toast animation (uses manager default if nil)
	public convenience init(
		_ message: String,
		systemImage: String? = nil,
		systemImageSize: CGFloat = 16,
		systemImageColor: Color? = nil,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		dismiss: BoneToast.StandardDismiss = .auto(),
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle? = nil,
		expandWidth: Bool = false,
		textAlignment: BoneToast.TextAlignment = .leading,
		actionButton: BoneToast.ActionButton? = nil,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		self.init(
			text: BoneToast.TextConfig(message, font: font, color: fontColor, alignment: textAlignment),
			systemImage: systemImage,
			systemImageSize: systemImageSize,
			systemImageColor: systemImageColor,
			backgroundStyle: backgroundStyle,
			position: position,
			dismiss: dismiss,
			contentPadding: contentPadding,
			edgePadding: edgePadding,
			cornerStyle: cornerStyle,
			expandWidth: expandWidth,
			actionButton: actionButton,
			animationConfig: animationConfig
		)
	}
	
	/// Creates a simple toast with a title message and custom icon view.
	///
	/// This is a convenience initializer for simple single-line toasts with custom icons.
	/// For toasts with subtitles or advanced text options, use `init(text:icon:)` with a `BoneToast.TextConfig`.
	///
	/// - Parameters:
	///   - message: The toast message
	///   - icon: Custom icon view builder
	///   - backgroundStyle: Background appearance (glass or solid)
	///   - font: Message font
	///   - fontColor: Message color (auto-selected based on background if nil)
	///   - position: Screen position (.top or .bottom)
	///   - dismiss: Dismiss behavior (.auto() or .manual)
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape (auto-selected based on content height if nil)
	///   - expandWidth: Whether to expand to full width
	///   - textAlignment: Text alignment within the toast
	///   - actionButton: Optional action button on trailing edge
	///   - animationConfig: Per-toast animation (uses manager default if nil)
	public convenience init<Icon: View>(
		_ message: String,
		@ViewBuilder icon: @escaping () -> Icon,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		dismiss: BoneToast.StandardDismiss = .auto(),
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle? = nil,
		expandWidth: Bool = false,
		textAlignment: BoneToast.TextAlignment = .leading,
		actionButton: BoneToast.ActionButton? = nil,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		self.init(
			text: BoneToast.TextConfig(message, font: font, color: fontColor, alignment: textAlignment),
			icon: icon,
			backgroundStyle: backgroundStyle,
			position: position,
			dismiss: dismiss,
			contentPadding: contentPadding,
			edgePadding: edgePadding,
			cornerStyle: cornerStyle,
			expandWidth: expandWidth,
			actionButton: actionButton,
			animationConfig: animationConfig
		)
	}
	
	@MainActor
	public var content: AnyView {
		AnyView(
			HStack(spacing: 8) {
				if textConfig.alignment == .trailing || textConfig.alignment == .center {
					Spacer(minLength: 0)
				}
				iconView
				textView
				if let actionButton {
					// Consistent 8pt spacing between text and button (from HStack spacing)
					ActionButtonView(
						config: actionButton,
						toastBackgroundStyle: backgroundStyle,
						toastFontColor: titleColor,
						onDismiss: { [weak self] in self?.actionButtonTapped = true }
					)
				} else if textConfig.alignment == .leading || textConfig.alignment == .center {
					// Only add trailing spacer when no action button
					Spacer(minLength: 0)
				}
			}
				.toastPadding(contentPadding)
		)
	}
	
	@MainActor @ViewBuilder
	private var textView: some View {
		VStack(alignment: textConfig.alignment.horizontalAlignment, spacing: 2) {
			Text(textConfig.title)
				.font(textConfig.titleFont)
				.foregroundColor(titleColor)
				.lineLimit(textConfig.effectiveTitleLineLimit)
				.multilineTextAlignment(textConfig.alignment.textAlignment)
			
			if let subtitle = textConfig.subtitle {
				Text(subtitle)
					.font(textConfig.subtitleFont)
					.foregroundColor(subtitleColor)
					.lineLimit(textConfig.effectiveSubtitleLineLimit)
					.multilineTextAlignment(textConfig.alignment.textAlignment)
			}
		}
	}
	
	@MainActor @ViewBuilder
	private var iconView: some View {
		if let iconBuilder {
			iconBuilder()
		} else if let systemImage {
			Image(systemName: systemImage)
				.font(.system(size: systemImageSize, weight: .semibold))
				.foregroundColor(systemImageColor ?? titleColor)
		}
	}
	
	// MARK: - Static Factories
	
	public static func error(_ message: String, position: BoneToast.Position? = nil, dismiss: BoneToast.StandardDismiss = .auto()) -> StandardToast {
		StandardToast(
			message,
			systemImage: "exclamationmark.triangle.fill",
			backgroundStyle: BoneToast.BackgroundStyle.glass(tintColor: .red),
			position: position,
			dismiss: dismiss
		)
	}
	
	public static func success(_ message: String, position: BoneToast.Position? = nil, dismiss: BoneToast.StandardDismiss = .auto()) -> StandardToast {
		StandardToast(
			message,
			systemImage: "checkmark.circle.fill",
			backgroundStyle: BoneToast.BackgroundStyle.glass(tintColor: .green),
			position: position,
			dismiss: dismiss
		)
	}
	
	public static func warning(_ message: String, position: BoneToast.Position? = nil, dismiss: BoneToast.StandardDismiss = .auto()) -> StandardToast {
		StandardToast(
			message,
			systemImage: "exclamationmark.triangle.fill",
			backgroundStyle: BoneToast.BackgroundStyle.glass(tintColor: .orange),
			position: position,
			dismiss: dismiss
		)
	}
	
	public static func info(_ message: String, position: BoneToast.Position? = nil, dismiss: BoneToast.StandardDismiss = .auto()) -> StandardToast {
		StandardToast(
			message,
			systemImage: "info.circle.fill",
			backgroundStyle: BoneToast.BackgroundStyle.glass(tintColor: .blue),
			position: position,
			dismiss: dismiss
		)
	}
}

// MARK: - BoneToast Extension (Icon & CompletionState)

public extension BoneToast {
	
	/// Represents an icon for toast notifications, supporting both SF Symbols and custom views.
	/// SF Symbols use smooth `.replace` transitions, while custom views use crossfade.
	enum Icon: Sendable {
		/// SF Symbol icon with optional configuration.
		/// Uses smooth `.replace` symbol transitions and supports variable value/color animations.
		/// - Parameters:
		///   - name: The SF Symbol name (e.g., "checkmark.circle.fill")
		///   - size: Icon size in points (defaults to toast's symbolSize if nil)
		///   - weight: Font weight (defaults to .semibold if nil)
		case symbol(_ name: String, size: CGFloat? = nil, weight: Font.Weight? = nil)
		
		/// Custom view icon. Uses crossfade transitions between states.
		case custom(@MainActor () -> AnyView)
		
		/// The SF Symbol name if this is a symbol icon, nil otherwise
		public var symbolName: String? {
			if case .symbol(let name, _, _) = self { return name }
			return nil
		}
		
		/// Whether this is an SF Symbol (as opposed to a custom view)
		public var isSymbol: Bool { symbolName != nil }
		
		/// Creates an SF Symbol Image view with the specified configuration
		@MainActor
		public func makeSymbolImage(defaultSize: CGFloat, color: Color) -> some View {
			guard case .symbol(let name, let size, let weight) = self else {
				return AnyView(EmptyView())
			}
			return AnyView(
				Image(systemName: name)
					.font(.system(size: size ?? defaultSize, weight: weight ?? .semibold))
					.foregroundStyle(color)
			)
		}
		
		/// Creates the icon view (either SF Symbol or custom)
		@MainActor
		public func makeView(defaultSize: CGFloat, color: Color) -> AnyView {
			switch self {
				case .symbol(let name, let size, let weight):
					return AnyView(
						Image(systemName: name)
							.font(.system(size: size ?? defaultSize, weight: weight ?? .semibold))
							.foregroundStyle(color)
					)
				case .custom(let builder):
					return builder()
			}
		}
	}
	
	// MARK: - Toast Phase
	
	/// The lifecycle phase of a completable toast
	enum Phase: Sendable, Equatable {
		/// Waiting to start - optional initial state before activity begins
		case pending
		/// In progress - actively showing progress or activity
		case active
		/// Completed successfully
		case success
		/// Completed with failure
		case failure
	}

} // end BoneToast extension

// MARK: - Completable Toast Protocol

/// A protocol for toasts that transition between an active state and a completed state
/// with smooth animated transitions. Supports both success and failure completion states.
/// Uses `isReadyToDismiss` to determine when to show the completed state.
public protocol CompletableBoneToastType: BoneToastType {
	// MARK: - Core Properties
	
	/// The message to display (can change between states)
	var message: String { get set }
	
	/// Font for the message text
	var font: Font { get }
	
	/// Text alignment within the toast
	var textAlignment: BoneToast.TextAlignment { get }
	
	/// The current phase of the toast lifecycle
	var phase: BoneToast.Phase { get }
	
	/// Default icon size for this toast type
	var symbolSize: CGFloat { get }
	
	/// The current icon view (should update in place based on phase)
	@MainActor @ViewBuilder var iconView: AnyView { get }
	
	// MARK: - Phase Configurations
	
	/// Configuration for the active phase (required)
	var activePhaseConfig: ToastPhaseConfig { get }
	
	/// Configuration for the pending phase (optional - nil means no pending phase)
	var pendingPhaseConfig: ToastPhaseConfig? { get }
	
	/// Configuration for the success phase (optional - nil means no success transition)
	var successPhaseConfig: ToastPhaseConfig? { get }
	
	/// Configuration for the failure phase (optional - nil means no failure transition)
	var failurePhaseConfig: ToastPhaseConfig? { get }
	
	// MARK: - Base Styling
	
	/// Base background style (used when phase doesn't override)
	var baseBackgroundStyle: BoneToast.BackgroundStyle { get }
	
	/// Base font/icon color (used when phase doesn't override)
	var baseFontColor: Color { get }
	
	// MARK: - Computed Styling
	
	/// Current background style based on phase
	var currentBackgroundStyle: BoneToast.BackgroundStyle { get }
	
	/// Current font color based on phase
	var currentFontColor: Color { get }
	
	/// Current action button based on phase (nil if no button)
	var currentActionButton: BoneToast.ActionButton? { get }
	
	// MARK: - Pending State
	
	/// Whether the toast is currently in pending state
	var isPending: Bool { get }
	
	/// Transitions from pending to active state. No-op if not in pending state.
	func start()
	
	// MARK: - Lifecycle Methods

	/// Marks the toast as successfully complete with animated transition.
	/// - Parameter message: Optional new message to display (overrides successPhaseConfig.title)
	func complete(message: String?)

	/// Marks the toast as failed with animated transition.
	/// - Parameter message: Optional new message to display (overrides failurePhaseConfig.title)
	func fail(message: String?)
}

// MARK: - Completable Toast Default Implementations

public extension CompletableBoneToastType {
	/// Completable toasts handle their own background for proper state animations
	var contentIncludesBackground: Bool { true }
	
	/// Whether the toast is in pending state
	var isPending: Bool { phase == .pending }
	
	/// The current background style (uses protocol's currentBackgroundStyle)
	var backgroundStyle: BoneToast.BackgroundStyle { currentBackgroundStyle }
	
	/// The current font color (uses protocol's currentFontColor)
	var fontColor: Color { currentFontColor }
	
	// MARK: - Convenience Methods

	/// Convenience: complete with no parameters (uses successPhaseConfig.title if set)
	func complete() {
		complete(message: nil)
	}

	/// Convenience: fail with no parameters (uses failurePhaseConfig.title if set)
	func fail() {
		fail(message: nil)
	}
}

// MARK: - Toast Phase Configuration

/// Configuration for how a symbol should be displayed in a toast phase
public enum ToastSymbolConfig: Sendable {
	/// No symbol shown for this phase
	case none
	
	/// Use the same symbol as the active phase (no .replace transition)
	case useActive
	
	/// Show a symbol with default styling (font size, weight, color from toast)
	/// - Parameters:
	///   - name: SF Symbol name
	///   - replaceFallback: Fallback effect for `.replace.magic(fallback:)` transition (default: .offUp)
	case symbol(_ name: String, replaceFallback: ReplaceSymbolEffect = .offUp)
	
	/// Show a symbol with custom styling
	/// - Parameters:
	///   - name: SF Symbol name
	///   - hasEffect: Whether the styling closure applies a symbolEffect (for transition timing)
	///   - replaceFallback: Fallback effect for `.replace.magic(fallback:)` transition (default: .offUp)
	///   - style: Closure that receives the Image and effectEnabled flag, returns styled view
	case custom(
		_ name: String,
		hasEffect: Bool,
		replaceFallback: ReplaceSymbolEffect = .offUp,
		style: @MainActor @Sendable (Image, Bool) -> AnyView
	)
	
	/// Returns the symbol name, or nil for .none/.useActive
	var symbolName: String? {
		switch self {
			case .none, .useActive: nil
			case .symbol(let name, _), .custom(let name, _, _, _): name
		}
	}
	
	/// Whether this config uses an effect that needs timing management
	var hasEffect: Bool {
		switch self {
			case .none, .useActive, .symbol: false
			case .custom(_, let hasEffect, _, _): hasEffect
		}
	}
	
	/// The fallback effect for `.replace.magic(fallback:)` transition
	var replaceFallback: ReplaceSymbolEffect {
		switch self {
			case .none, .useActive: .offUp
			case .symbol(_, let fallback): fallback
			case .custom(_, _, let fallback, _): fallback
		}
	}
}

/// Symbol names for each phase of a completable toast.
/// Used with unified styling where one closure handles all phases.
public struct ToastSymbols: Sendable {
	/// Symbol name for the active phase
	public let active: String
	
	/// Symbol name for the pending phase (nil uses active's symbol with no replace animation)
	public let pending: String?
	
	/// Symbol name for the success phase
	public let success: String
	
	/// Symbol name for the failure phase
	public let failure: String
	
	/// Whether any phase transition requires effect timing management
	public let hasEffects: Bool
	
	/// Fallback effect for `.replace.magic(fallback:)` when magic replacement isn't available.
	///
	/// Choose based on your use case:
	/// - `.offUp` (default): Best when colors change between phases. The outgoing symbol fades
	///   in place, minimizing visibility of color changes during the transition.
	/// - `.downUp` or `.upUp`: Best when using `.variableColor` or similar continuous animations.
	///   These effects halt the animation before the replace, resulting in a smoother handoff.
	public let replaceFallback: ReplaceSymbolEffect
	
	/// Optional static variable value for SF Symbol fill.
	/// When set, this value is used for active/pending phases instead of the toast's progress value.
	/// Useful for symbols that need a fixed fill level (e.g., 0.9 for network activity indicators).
	public let staticVariableValue: Double?
	
	/// Creates symbol configuration for all phases.
	/// - Parameters:
	///   - active: Symbol name for the active phase
	///   - pending: Symbol name for pending (nil = use active's symbol, no replace animation)
	///   - success: Symbol name for success phase
	///   - failure: Symbol name for failure phase
	///   - hasEffects: Whether your styling closure applies symbolEffects that need timing management
	///   - replaceFallback: Fallback effect for `.replace.magic(fallback:)` (default: .offUp).
	///     Use `.downUp`/`.upUp` with variableColor animations; use `.offUp` when colors change between phases.
	///   - staticVariableValue: Fixed variable value for active/pending phases (nil uses toast's progress value)
	public init(
		active: String,
		pending: String? = nil,
		success: String = "checkmark.circle.fill",
		failure: String = "xmark.circle.fill",
		hasEffects: Bool = false,
		replaceFallback: ReplaceSymbolEffect = .offUp,
		staticVariableValue: Double? = nil
	) {
		self.active = active
		self.pending = pending
		self.success = success
		self.failure = failure
		self.hasEffects = hasEffects
		self.replaceFallback = replaceFallback
		self.staticVariableValue = staticVariableValue
	}
}

/// Unified symbol styling configuration.
/// Provides a single styling closure that handles all phases, ensuring consistent view structure
/// for smooth `.replace` transitions between symbols.
///
/// Example usage:
/// ```swift
/// ToastUnifiedSymbolStyle(
///     symbols: ToastSymbols(
///         active: "progress.indicator",
///         pending: nil,  // Uses active's symbol
///         success: "checkmark.circle.fill",
///         failure: "xmark.circle.fill",
///         hasEffects: true
///     ),
///     style: { image, phase, effectEnabled in
///         image
///             .font(.system(size: 16, weight: .semibold))
///             .foregroundStyle(.white)
///             .symbolRenderingMode(phase == .success ? .multicolor : .hierarchical)
///             .symbolEffect(
///                 .variableColor.iterative.dimInactiveLayers.nonReversing,
///                 options: .repeat(.continuous),
///                 isActive: phase == .active && effectEnabled
///             )
///             .symbolEffect(.bounce, value: phase == .success ? effectEnabled : false)
///     }
/// )
/// ```
public struct ToastUnifiedSymbolStyle: Sendable {
	/// Symbol names for each phase
	public let symbols: ToastSymbols
	
	/// Unified styling closure that receives the image, current phase, and effect enabled state.
	/// Apply ALL modifiers you need for ANY phase, using conditionals to vary values by phase.
	/// This ensures the view structure stays consistent for smooth `.replace` transitions.
	public let style: @MainActor @Sendable (Image, BoneToast.Phase, Bool) -> AnyView
	
	/// Creates a unified symbol style configuration.
	/// - Parameters:
	///   - symbols: Symbol names for each phase
	///   - style: Styling closure that handles all phases. Receives (Image, Phase, effectEnabled).
	public init<V: View>(
		symbols: ToastSymbols,
		@ViewBuilder style: @escaping @MainActor @Sendable (Image, BoneToast.Phase, Bool) -> V
	) {
		self.symbols = symbols
		self.style = { image, phase, effectEnabled in
			AnyView(style(image, phase, effectEnabled))
		}
	}
}

/// Configuration for action button behavior in a phase
public enum ToastActionButtonOverride: Sendable {
	/// Use the base toast's action button (if any)
	case inherit
	/// Hide the action button for this phase
	case hidden
	/// Show a specific action button
	case button(BoneToast.ActionButton)
}

/// Protocol defining the content and styling properties for a toast phase.
/// Each phase can be thought of as a "virtual toast" that transitions smoothly to the next.
public protocol ToastPhaseProviding: Sendable {
	/// Title text for this phase (nil keeps previous phase's title)
	var title: String? { get }
	
	/// Subtitle text for this phase (nil keeps previous, empty string hides it)
	var subtitle: String? { get }
	
	/// Symbol configuration for this phase
	var symbol: ToastSymbolConfig { get }
	
	/// Title font override (nil inherits from base)
	var titleFont: Font? { get }
	
	/// Subtitle font override (nil inherits from base)
	var subtitleFont: Font? { get }
	
	/// Font/icon color override (nil inherits from base)
	var fontColor: Color? { get }
	
	/// Background style override (nil inherits from base)
	var backgroundStyle: BoneToast.BackgroundStyle? { get }
	
	/// Action button configuration for this phase
	var actionButton: ToastActionButtonOverride { get }
}

/// Default implementations for optional properties
public extension ToastPhaseProviding {
	var subtitle: String? { nil }
	var titleFont: Font? { nil }
	var subtitleFont: Font? { nil }
	var fontColor: Color? { nil }
	var backgroundStyle: BoneToast.BackgroundStyle? { nil }
	var actionButton: ToastActionButtonOverride { .inherit }
}

/// Configuration for a toast phase including text, symbol, and styling.
/// Conforms to `ToastPhaseProviding` protocol for extensibility.
public struct ToastPhaseConfig: ToastPhaseProviding, Sendable {
	/// Title text for this phase
	public let title: String?
	
	/// Subtitle text for this phase (optional)
	public let subtitle: String?
	
	/// Symbol configuration for this phase
	public let symbol: ToastSymbolConfig
	
	/// Title font override (nil inherits from base)
	public let titleFont: Font?
	
	/// Subtitle font override (nil inherits from base)
	public let subtitleFont: Font?
	
	/// Background style override for this phase (nil inherits from base)
	public let backgroundStyle: BoneToast.BackgroundStyle?
	
	/// Font color override for this phase (nil inherits from base)
	public let fontColor: Color?
	
	/// Action button configuration for this phase
	public let actionButton: ToastActionButtonOverride
	
	/// Creates a phase configuration
	public init(
		title: String? = nil,
		subtitle: String? = nil,
		symbol: ToastSymbolConfig = .none,
		titleFont: Font? = nil,
		subtitleFont: Font? = nil,
		backgroundStyle: BoneToast.BackgroundStyle? = nil,
		fontColor: Color? = nil,
		actionButton: ToastActionButtonOverride = .inherit
	) {
		self.title = title
		self.subtitle = subtitle
		self.symbol = symbol
		self.titleFont = titleFont
		self.subtitleFont = subtitleFont
		self.backgroundStyle = backgroundStyle
		self.fontColor = fontColor
		self.actionButton = actionButton
	}
	
	// MARK: - Convenience Initializers
	
	/// A pending phase config that inherits the message from the active phase.
	/// Use this as a default for `pendingConfig` to enable pending state without custom text.
	public static var inheritMessage: ToastPhaseConfig {
		ToastPhaseConfig(title: nil, symbol: .useActive)
	}

	/// Creates a phase config with just a symbol name
	public static func symbol(_ name: String, title: String? = nil) -> ToastPhaseConfig {
		ToastPhaseConfig(title: title, symbol: .symbol(name))
	}

	/// Creates a phase config that uses the active phase's symbol
	public static func useActiveSymbol(title: String? = nil) -> ToastPhaseConfig {
		ToastPhaseConfig(title: title, symbol: .useActive)
	}

	/// Creates a phase config with no symbol
	public static func noSymbol(title: String? = nil) -> ToastPhaseConfig {
		ToastPhaseConfig(title: title, symbol: .none)
	}
	
	/// Creates a phase config with custom symbol styling
	/// - Parameters:
	///   - symbolName: SF Symbol name
	///   - title: Optional title for this phase
	///   - hasEffect: Whether the styling closure applies a symbolEffect (for transition timing)
	///   - replaceFallback: Fallback effect for `.replace.magic(fallback:)` (default: .offUp).
	///     Use `.downUp`/`.upUp` with variableColor or continuous animations.
	///   - backgroundStyle: Optional background style override
	///   - fontColor: Optional font color override
	///   - actionButton: Action button configuration
	///   - style: Closure that styles the Image (receives Image and effectEnabled flag)
	public static func custom<V: View>(
		_ symbolName: String,
		title: String? = nil,
		hasEffect: Bool = false,
		replaceFallback: ReplaceSymbolEffect = .offUp,
		backgroundStyle: BoneToast.BackgroundStyle? = nil,
		fontColor: Color? = nil,
		actionButton: ToastActionButtonOverride = .inherit,
		@ViewBuilder style: @escaping @MainActor @Sendable (Image, Bool) -> V
	) -> ToastPhaseConfig {
		ToastPhaseConfig(
			title: title,
			symbol: .custom(symbolName, hasEffect: hasEffect, replaceFallback: replaceFallback, style: { image, effectEnabled in
				AnyView(style(image, effectEnabled))
			}),
			backgroundStyle: backgroundStyle,
			fontColor: fontColor,
			actionButton: actionButton
		)
	}
}

// MARK: - Simple Phase Options for Convenience Initializers

/// Configuration for a phase in convenience initializers.
/// Provides a simpler API than `ToastPhaseConfig` while still allowing per-phase customization
/// of message, symbol, and background style.
public struct SimplePhaseConfig: Sendable {
	/// Whether this phase is enabled
	public let isEnabled: Bool
	
	/// Custom message for this phase (nil uses the active phase's message)
	public let message: String?
	
	/// Custom symbol name for this phase (nil uses default: checkmark.circle.fill for success, xmark.circle.fill for failure)
	public let symbol: String?
	
	/// Custom background style for this phase (nil inherits from base toast)
	public let backgroundStyle: BoneToast.BackgroundStyle?
	
	/// Creates a phase configuration.
	public init(
		isEnabled: Bool = true,
		message: String? = nil,
		symbol: String? = nil,
		backgroundStyle: BoneToast.BackgroundStyle? = nil
	) {
		self.isEnabled = isEnabled
		self.message = message
		self.symbol = symbol
		self.backgroundStyle = backgroundStyle
	}
	
	// MARK: - Static Helpers
	
	/// Phase is disabled (not shown)
	public static let disabled = SimplePhaseConfig(isEnabled: false)
	
	/// Phase is enabled with defaults (default symbol, inherits message and background)
	public static let enabled = SimplePhaseConfig(isEnabled: true)
	
	/// Phase is enabled with a custom message
	public static func message(_ message: String) -> SimplePhaseConfig {
		SimplePhaseConfig(message: message)
	}
	
	/// Phase is enabled with a custom symbol
	public static func symbol(_ symbol: String) -> SimplePhaseConfig {
		SimplePhaseConfig(symbol: symbol)
	}
	
	/// Phase is enabled with custom message and symbol
	public static func config(
		message: String? = nil,
		symbol: String? = nil,
		backgroundStyle: BoneToast.BackgroundStyle? = nil
	) -> SimplePhaseConfig {
		SimplePhaseConfig(message: message, symbol: symbol, backgroundStyle: backgroundStyle)
	}
}

// MARK: - Completable Toast

/// A unified toast that supports progress indicators and activity spinners with smooth phase transitions.
///
/// `CompletableToast` handles the full lifecycle: pending → active → success/failure.
/// It can be used as either:
/// - **Progress-style**: Set `progress` (0.0-1.0) to drive the indicator
/// - **Activity-style**: Call `complete()` or `fail()` when done
///
/// Both styles can be combined - a progress toast can also be manually completed early.
///
/// ## Phase Transitions
/// - **pending → active**: Call `start()` or set `progress > 0` (auto-starts)
/// - **active → success**: Call `complete()` or set `progress = 1.0`
/// - **active → failure**: Call `fail()`
///
/// ## Symbol Transitions
/// Uses smooth `.replace` transitions between SF Symbols. For custom styling, provide
/// styling closures that receive the base Image and apply your modifiers.
@Observable
public class CompletableToast: CompletableBoneToastType {
	public let id = UUID()
	
	// MARK: - Content
	
	/// The text configuration for the toast
	public let textConfig: BoneToast.TextConfig
	
	/// The current message (can be updated dynamically)
	public var message: String
	
	/// Whether the toast has completed successfully
	public private(set) var isSuccess = false

	/// Whether the toast has failed
	public private(set) var isFailed = false
	
	// MARK: - Phase Configurations
	
	/// Configuration for the active phase (required)
	public let activePhaseConfig: ToastPhaseConfig
	
	/// Configuration for the pending phase (optional - nil means no pending phase)
	public let pendingPhaseConfig: ToastPhaseConfig?
	
	/// Configuration for the success phase (optional - nil means no success transition)
	public let successPhaseConfig: ToastPhaseConfig?
	
	/// Configuration for the failure phase (optional - nil means no failure transition)
	public let failurePhaseConfig: ToastPhaseConfig?
	
	/// Unified symbol styling (when set, overrides per-phase symbol configs for smooth transitions)
	public let unifiedSymbolStyle: ToastUnifiedSymbolStyle?
	
	/// Icon size in points (used for default symbol styling)
	public let symbolSize: CGFloat
	
	// MARK: - Layout & Presentation
	
	public let positionOverride: BoneToast.Position?
	public let dismissDelayAfterCompletion: TimeInterval
	public let contentPadding: BoneToast.Padding
	public let edgePadding: BoneToast.Padding
	public let cornerStyleOverride: BoneToast.CornerStyle?
	public let expandWidth: Bool
	public let actionButton: BoneToast.ActionButton?
	public let animationConfig: BoneToast.AnimationConfig?
	
	/// Internal tracking of pending state
	private var _isInPendingState: Bool
	
	// MARK: - Base Styling
	
	/// Base background style (used when phase doesn't override)
	public let baseBackgroundStyle: BoneToast.BackgroundStyle
	
	/// Base font/icon color (used when phase doesn't override)
	public let baseFontColor: Color
	
	/// Whether the toast can be interactively dismissed
	public var interactive: Bool = false
	
	/// Whether the action button was tapped (triggers dismissal)
	public var actionButtonTapped: Bool = false
	
	// MARK: - Computed Styling
	
	/// Current background style based on phase
	public var currentBackgroundStyle: BoneToast.BackgroundStyle {
		switch phase {
			case .pending: pendingPhaseConfig?.backgroundStyle ?? baseBackgroundStyle
			case .active: activePhaseConfig.backgroundStyle ?? baseBackgroundStyle
			case .success: successPhaseConfig?.backgroundStyle ?? baseBackgroundStyle
			case .failure: failurePhaseConfig?.backgroundStyle ?? baseBackgroundStyle
		}
	}

	/// Current font color based on phase
	public var currentFontColor: Color {
		switch phase {
			case .pending: pendingPhaseConfig?.fontColor ?? baseFontColor
			case .active: activePhaseConfig.fontColor ?? baseFontColor
			case .success: successPhaseConfig?.fontColor ?? baseFontColor
			case .failure: failurePhaseConfig?.fontColor ?? baseFontColor
		}
	}
	
	/// Current title font based on phase
	public var currentTitleFont: Font {
		switch phase {
			case .pending: pendingPhaseConfig?.titleFont ?? textConfig.titleFont
			case .active: activePhaseConfig.titleFont ?? textConfig.titleFont
			case .success: successPhaseConfig?.titleFont ?? textConfig.titleFont
			case .failure: failurePhaseConfig?.titleFont ?? textConfig.titleFont
		}
	}
	
	/// Current subtitle based on phase
	public var currentSubtitle: String? {
		switch phase {
			case .pending: pendingPhaseConfig?.subtitle ?? textConfig.subtitle
			case .active: activePhaseConfig.subtitle ?? textConfig.subtitle
			case .success: successPhaseConfig?.subtitle ?? textConfig.subtitle
			case .failure: failurePhaseConfig?.subtitle ?? textConfig.subtitle
		}
	}
	
	/// Current subtitle font based on phase
	public var currentSubtitleFont: Font {
		switch phase {
			case .pending: pendingPhaseConfig?.subtitleFont ?? textConfig.subtitleFont
			case .active: activePhaseConfig.subtitleFont ?? textConfig.subtitleFont
			case .success: successPhaseConfig?.subtitleFont ?? textConfig.subtitleFont
			case .failure: failurePhaseConfig?.subtitleFont ?? textConfig.subtitleFont
		}
	}
	
	/// Current action button based on phase (resolves inherit/hidden/custom)
	public var currentActionButton: BoneToast.ActionButton? {
		let phaseOverride: ToastActionButtonOverride = switch phase {
			case .pending: pendingPhaseConfig?.actionButton ?? .inherit
			case .active: activePhaseConfig.actionButton
			case .success: successPhaseConfig?.actionButton ?? .inherit
			case .failure: failurePhaseConfig?.actionButton ?? .inherit
		}
		
		switch phaseOverride {
			case .inherit: return actionButton
			case .hidden: return nil
			case .button(let button): return button
		}
	}
	
	// MARK: - Computed Properties (Protocol Conformance)
	
	public var font: Font { textConfig.titleFont }
	public var textAlignment: BoneToast.TextAlignment { textConfig.alignment }
	
	public var dismissBehavior: BoneToast.DismissBehavior {
		.whenReady(delay: dismissDelayAfterCompletion)
	}
	
	/// Whether the toast is ready to be dismissed. Override in subclasses for custom behavior.
	open var isReadyToDismiss: Bool { isSuccess || isFailed }
	
	/// The current phase of the toast. Override in subclasses for custom behavior.
	open var phase: BoneToast.Phase {
		if isFailed { return .failure }
		if isSuccess { return .success }
		if _isInPendingState { return .pending }
		return .active
	}
	
	/// The variable value to use for SF Symbol fill (e.g., progress indicator).
	/// Override in subclasses to provide dynamic values (e.g., ProgressToast returns progress).
	open var symbolVariableValue: Double { 0 }
	
	// MARK: - Lifecycle Methods
	
	/// Transitions from pending to active state. No-op if not pending.
	public func start() {
		guard _isInPendingState else { return }
		withAnimation(.smooth(duration: 0.3)) {
			_isInPendingState = false
			// Restore active message if pending had a custom message
			if pendingPhaseConfig?.title != nil {
				message = activePhaseConfig.title ?? textConfig.title
			}
		}
	}
	
	/// Marks the toast as successfully complete.
	///
	/// Note: Has no effect if the toast is in pending state. Call `start()` first to
	/// transition from pending to active before completing.
	///
	/// - Parameter message: Optional message override (uses successPhaseConfig.title if nil)
	public func complete(message: String? = nil) {
		// Cannot complete while in pending state - must call start() first
		guard !_isInPendingState else { return }

		withAnimation(.smooth(duration: 0.2)) {
			// Use provided message, or fall back to success config title, or keep current
			if let message {
				self.message = message
			} else if let successTitle = successPhaseConfig?.title {
				self.message = successTitle
			}
			self.isSuccess = true
		}
	}

	/// Marks the toast as failed.
	///
	/// Note: Has no effect if the toast is in pending state. Call `start()` first to
	/// transition from pending to active before failing.
	///
	/// - Parameter message: Optional message override (uses failurePhaseConfig.title if nil)
	public func fail(message: String? = nil) {
		// Cannot fail while in pending state - must call start() first
		guard !_isInPendingState else { return }

		withAnimation(.smooth(duration: 0.2)) {
			// Use provided message, or fall back to failure config title, or keep current
			if let message {
				self.message = message
			} else if let failureTitle = failurePhaseConfig?.title {
				self.message = failureTitle
			}
			self.isFailed = true
		}
	}
	
	// MARK: - Primary Initializer
	
	/// Creates a completable toast with phase-based configuration.
	///
	/// Each phase (active, pending, success, failure) has its own configuration including
	/// text, symbol, and styling options.
	///
	/// - Parameters:
	///   - text: Base text configuration (title used as active phase title if not specified in activeConfig)
	///   - activeConfig: Configuration for the active phase (required)
	///   - pendingConfig: Configuration for pending phase (nil = no pending phase)
	///   - successConfig: Configuration for success phase (nil = no success transition)
	///   - failureConfig: Configuration for failure phase (nil = no failure transition)
	///   - symbolSize: Default icon size in points for phases using default styling
	///   - backgroundStyle: Base background style (phases can override)
	///   - position: Screen position (.top or .bottom)
	///   - dismissDelayAfterCompletion: Delay before auto-dismiss
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape
	///   - expandWidth: Whether to expand to full width
	///   - actionButton: Optional action button
	///   - animationConfig: Per-toast animation configuration
	public init(
		text: BoneToast.TextConfig,
		activeConfig: ToastPhaseConfig,
		pendingConfig: ToastPhaseConfig? = nil,
		successConfig: ToastPhaseConfig? = nil,
		failureConfig: ToastPhaseConfig? = nil,
		unifiedSymbolStyle: ToastUnifiedSymbolStyle? = nil,
		symbolSize: CGFloat = 16,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		position: BoneToast.Position? = nil,
		dismissDelayAfterCompletion: TimeInterval = 1.5,
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle = .capsule,
		expandWidth: Bool = false,
		actionButton: BoneToast.ActionButton? = nil,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		self.textConfig = text
		self.activePhaseConfig = activeConfig
		self.pendingPhaseConfig = pendingConfig
		self.successPhaseConfig = successConfig
		self.failurePhaseConfig = failureConfig
		self.unifiedSymbolStyle = unifiedSymbolStyle
		self._isInPendingState = pendingConfig != nil
		self.message = pendingConfig?.title ?? activeConfig.title ?? text.title
		self.symbolSize = symbolSize
		self.baseBackgroundStyle = backgroundStyle
		self.baseFontColor = text.titleColor ?? backgroundStyle.defaultFontColor
		self.positionOverride = position
		self.dismissDelayAfterCompletion = dismissDelayAfterCompletion
		self.contentPadding = contentPadding
		self.edgePadding = edgePadding
		self.cornerStyleOverride = cornerStyle
		self.expandWidth = expandWidth
		self.actionButton = actionButton
		self.animationConfig = animationConfig
	}
	
	// MARK: - Convenience Initializers
	
	/// Creates a completable toast with simplified phase configuration.
	///
	/// This convenience initializer uses `SimplePhaseConfig` for easy configuration while
	/// still allowing per-phase customization of message, symbol, and background style.
	/// The `ToastUnifiedSymbolStyle` is built automatically to ensure smooth `.replace` transitions.
	///
	/// Phase configuration options:
	/// - `.disabled`: Phase not shown
	/// - `.enabled`: Phase uses default symbols, inherits message and background
	/// - `.message("text")`: Phase with custom message
	/// - `.symbol("name")`: Phase with custom SF Symbol
	/// - `.config(message:symbol:backgroundStyle:)`: Full customization
	///
	/// For full control over styling (symbol effects, rendering modes, etc.), use the
	/// primary initializer with `ToastPhaseConfig` and `ToastUnifiedSymbolStyle`.
	///
	/// - Parameters:
	///   - message: The main message to display
	///   - subtitle: Optional subtitle text
	///   - activeSymbol: SF Symbol name for the active phase (nil = no symbol)
	///   - backgroundStyle: Base background style for the toast
	///   - font: Font for the message
	///   - subtitleFont: Font for the subtitle
	///   - fontColor: Color for text and icons
	///   - position: Screen position
	///   - pending: Pending phase configuration (default: disabled)
	///   - success: Success phase configuration (default: disabled)
	///   - failure: Failure phase configuration (default: disabled)
	///   - dismissDelayAfterCompletion: Delay before auto-dismiss
	///   - contentPadding: Internal padding around content
	///   - edgePadding: Padding from screen edges
	///   - cornerStyle: Corner shape
	///   - expandWidth: Whether to expand to full width
	///   - animationConfig: Per-toast animation configuration
	public convenience init(
		_ message: String,
		subtitle: String? = nil,
		activeSymbol: String? = nil,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		subtitleFont: Font = .system(size: 14),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		pending: SimplePhaseConfig = .disabled,
		success: SimplePhaseConfig = .disabled,
		failure: SimplePhaseConfig = .disabled,
		dismissDelayAfterCompletion: TimeInterval = 1.5,
		contentPadding: BoneToast.Padding = .edges(top: 10, leading: 14, bottom: 10, trailing: 14),
		edgePadding: BoneToast.Padding = .systemDefault,
		cornerStyle: BoneToast.CornerStyle = .capsule,
		expandWidth: Bool = false,
		animationConfig: BoneToast.AnimationConfig? = nil
	) {
		let resolvedFontColor = fontColor ?? backgroundStyle.defaultFontColor
		
		// Determine if we need symbols at all
		let hasSymbols = activeSymbol != nil || success.isEnabled || failure.isEnabled
		
		// Build unified symbol style if we have symbols
		var unifiedStyle: ToastUnifiedSymbolStyle? = nil
		if hasSymbols {
			// Resolve symbol names: use custom if provided, otherwise defaults
			let activeSymbolName = activeSymbol ?? "circle"  // Default to circle if no active but success/failure enabled
			let pendingSymbolName = pending.symbol  // nil = use active symbol (no replace animation)
			let successSymbolName = success.symbol ?? "checkmark.circle.fill"
			let failureSymbolName = failure.symbol ?? "xmark.circle.fill"
			
			let symbols = ToastSymbols(
				active: activeSymbolName,
				pending: pendingSymbolName,
				success: successSymbolName,
				failure: failureSymbolName,
				hasEffects: success.isEnabled  // Bounce effect on success
			)
			
			unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
				image
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(resolvedFontColor)
					.symbolRenderingMode(.monochrome)
					.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false)
			}
		}
		
		// Resolve phase configs for text/message and background style handling
		let pendingConfig: ToastPhaseConfig? = pending.isEnabled
		? ToastPhaseConfig(title: pending.message ?? message, backgroundStyle: pending.backgroundStyle)
		: nil
		
		let successConfig: ToastPhaseConfig? = success.isEnabled
		? ToastPhaseConfig(title: success.message, backgroundStyle: success.backgroundStyle)
		: nil
		
		// Failure defaults to red tint using base style type (glass/solid)
		let failureBackgroundStyle: BoneToast.BackgroundStyle? = if let explicit = failure.backgroundStyle {
			explicit
		} else if failure.isEnabled {
			// Inherit style type from base, apply red tint
			switch backgroundStyle {
				case .glass: .glass(tintColor: .red)
				case .solid: .solid(.red)
			}
		} else {
			nil
		}
		
		let failureConfig: ToastPhaseConfig? = failure.isEnabled
		? ToastPhaseConfig(title: failure.message, backgroundStyle: failureBackgroundStyle)
		: nil
		
		// Build TextConfig - use full initializer if subtitle provided
		let textConfig: BoneToast.TextConfig
		if let subtitle {
			textConfig = BoneToast.TextConfig(
				title: message,
				titleFont: font,
				titleColor: fontColor,
				subtitle: subtitle,
				subtitleFont: subtitleFont,
				hasIcon: activeSymbol != nil
			)
		} else {
			textConfig = BoneToast.TextConfig(message, font: font, color: fontColor)
		}
		
		self.init(
			text: textConfig,
			activeConfig: ToastPhaseConfig(title: message),
			pendingConfig: pendingConfig,
			successConfig: successConfig,
			failureConfig: failureConfig,
			unifiedSymbolStyle: unifiedStyle,
			backgroundStyle: backgroundStyle,
			position: position,
			dismissDelayAfterCompletion: dismissDelayAfterCompletion,
			contentPadding: contentPadding,
			edgePadding: edgePadding,
			cornerStyle: cornerStyle,
			expandWidth: expandWidth,
			animationConfig: animationConfig
		)
	}
	
	// MARK: - Content View
	
	@MainActor
	public var content: AnyView {
		AnyView(CompletableToastContentView(toast: self))
	}
	
	@MainActor
	public var iconView: AnyView {
		AnyView(currentIcon)
	}
	
	// MARK: - Symbol Resolution Helpers
	
	/// Resolves .useActive to use active's symbol name
	private func resolvedSymbolName(for config: ToastSymbolConfig) -> String? {
		switch config {
			case .none: return nil
			case .useActive: return activePhaseConfig.symbol.symbolName
			case .symbol(let name, _), .custom(let name, _, _, _): return name
		}
	}
	
	/// Check if a phase uses the active symbol (for determining if replace animation is needed)
	private func phaseUsesActiveSymbol(_ config: ToastSymbolConfig?) -> Bool {
		guard let config else { return true } // nil config = use active
		switch config {
			case .none, .useActive: return true
			case .symbol, .custom: return false
		}
	}
	
	/// Check if any phase config has an effect
	private var anyPhaseHasEffect: Bool {
		activePhaseConfig.symbol.hasEffect ||
		(pendingPhaseConfig?.symbol.hasEffect ?? false) ||
		(successPhaseConfig?.symbol.hasEffect ?? false) ||
		(failurePhaseConfig?.symbol.hasEffect ?? false)
	}
	
	@MainActor @ViewBuilder
	private var currentIcon: some View {
		// If unified symbol style is provided, use it directly (best for smooth transitions)
		if let unified = unifiedSymbolStyle {
			HybridSymbolTransitionView(
				phase: phase,
				symbols: unified.symbols,
				style: unified.style,
				variableValue: symbolVariableValue
			)
		} else {
			// Fall back to per-phase config approach (may not have smooth transitions with effects)
			let activeSymbolConfig = activePhaseConfig.symbol
			let activeSymbolName = activeSymbolConfig.symbolName ?? ""
			
			// If active has no symbol, show nothing
			if activeSymbolName.isEmpty {
				EmptyView()
			} else {
				// Build ToastSymbols from phase configs
				let symbols = ToastSymbols(
					active: activeSymbolName,
					pending: phaseUsesActiveSymbol(pendingPhaseConfig?.symbol) ? nil : (pendingPhaseConfig?.symbol.symbolName ?? activeSymbolName),
					success: successPhaseConfig?.symbol.symbolName ?? activeSymbolName,
					failure: failurePhaseConfig?.symbol.symbolName ?? activeSymbolName,
					hasEffects: anyPhaseHasEffect
				)
				
				// Create unified style closure that wraps per-phase configs
				// Note: This may not provide smooth transitions when different phases use different effects
				let wrappedStyle: @MainActor (Image, BoneToast.Phase, Bool) -> AnyView = { [
					symbolSize,
					baseFontColor,
					activeConfig = activePhaseConfig,
					pendingConfig = pendingPhaseConfig,
					successConfig = successPhaseConfig,
					failureConfig = failurePhaseConfig
				] image, phase, effectEnabled in
					// Get the config for the current phase
					let config: ToastSymbolConfig = switch phase {
						case .pending: pendingConfig?.symbol ?? .useActive
						case .active: activeConfig.symbol
						case .success: successConfig?.symbol ?? .useActive
						case .failure: failureConfig?.symbol ?? .useActive
					}
					
					// Apply styling based on config type
					switch config {
						case .none, .symbol, .useActive:
							// Default styling
							return AnyView(image
								.font(.system(size: symbolSize, weight: .semibold))
								.foregroundStyle(baseFontColor))
						case .custom(_, _, _, let style):
							return style(image, effectEnabled)
					}
				}
				
				HybridSymbolTransitionView(
					phase: phase,
					symbols: symbols,
					style: wrappedStyle,
					variableValue: symbolVariableValue
				)
			}
		}
	}
}

// MARK: - Progress Toast

/// A toast that displays progress (0.0 to 1.0) with a filling circle symbol.
///
/// Use `ProgressToast` for operations where you can track progress. The circle
/// symbol fills in as `progress` increases. When `progress` reaches 1.0, the
/// toast automatically transitions to success state.
///
/// ## Usage
/// ```swift
/// let toast = ProgressToast("Downloading...")
/// toast.progress = 0.5 // Circle is half filled
/// toast.progress = 1.0 // Auto-completes when progress reaches 1.0
/// ```
///
/// ## Phase Transitions
/// - **pending → active**: Call `start()` or set `progress > 0` (auto-starts)
/// - **active → success**: Set `progress = 1.0` or call `complete()`
/// - **active → failure**: Call `fail()`
@Observable
public final class ProgressToast: CompletableToast {
	/// The current progress (0.0 to 1.0). Setting progress > 0 auto-starts the toast.
	/// When progress reaches 1.0, the toast automatically completes.
	public var progress: Double = 0 {
		didSet {
			// Auto-start when progress begins
			if progress > 0 {
				start()
			}
			// Auto-complete when progress reaches 1.0
			if progress >= 1.0 && !isSuccess && !isFailed {
				complete()
			}
		}
	}
	
	/// Returns the progress value for SF Symbol variable fill.
	public override var symbolVariableValue: Double { progress }
	
	/// Ready to dismiss when success, failed, or progress reaches 1.0.
	public override var isReadyToDismiss: Bool { isSuccess || isFailed || progress >= 1.0 }
	
	/// Phase includes progress-based success detection.
	public override var phase: BoneToast.Phase {
		if isFailed { return .failure }
		if isSuccess || progress >= 1.0 { return .success }
		// Use base class for pending state check (via super causes issues with stored properties)
		return super.phase
	}
	
	/// Creates a progress toast with a filling circle indicator.
	///
	/// - Parameters:
	///   - message: The message to display
	///   - backgroundStyle: Background style for the toast
	///   - font: Font for the message
	///   - fontColor: Color for text and icons
	///   - position: Screen position
	///   - pendingConfig: Pending phase config (default: `.inheritMessage` enables pending with same message; `nil` disables)
	///   - successConfig: Custom success phase config
	///   - failureConfig: Custom failure phase config
	///   - dismissDelayAfterCompletion: Delay before auto-dismiss
	///   - cornerStyle: Corner shape
	public init(
		_ message: String,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		pendingConfig: ToastPhaseConfig? = .inheritMessage,
		successConfig: ToastPhaseConfig? = nil,
		failureConfig: ToastPhaseConfig? = nil,
		dismissDelayAfterCompletion: TimeInterval = 1.5,
		cornerStyle: BoneToast.CornerStyle = .capsule
	) {
		let resolvedFontColor = fontColor ?? backgroundStyle.defaultFontColor
		let hasPendingPhase = pendingConfig != nil

		// Extract custom symbols from configs (if provided)
		let resolvedSuccessSymbol = successConfig?.symbol.symbolName ?? "checkmark.circle.fill"
		let resolvedFailureSymbol = failureConfig?.symbol.symbolName ?? "xmark.circle.fill"

		// Use unified symbol styling for smooth transitions
		// Use .downUp when there are animated effects (pulse) for smoother transition
		let symbols = ToastSymbols(
			active: "circle",
			pending: hasPendingPhase ? "circle" : nil,
			success: resolvedSuccessSymbol,
			failure: resolvedFailureSymbol,
			hasEffects: hasPendingPhase,
			replaceFallback: hasPendingPhase ? .downUp : .offUp
		)

		let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
			image
				.font(.system(size: 16, weight: .semibold))
				.foregroundStyle(resolvedFontColor)
				.symbolRenderingMode(.hierarchical)
				.symbolEffect(.pulse, options: .repeat(.continuous), isActive: phase == .pending && effectEnabled)
		}

		// Phase configs for text/message handling
		let activeConfig = ToastPhaseConfig(title: message)

		// Default failure config uses red tint, inheriting style type from base
		let resolvedFailureConfig: ToastPhaseConfig?
		if let explicit = failureConfig {
			resolvedFailureConfig = explicit
		} else {
			let redBackground: BoneToast.BackgroundStyle = switch backgroundStyle {
				case .glass: .glass(tintColor: .red)
				case .solid: .solid(.red)
			}
			resolvedFailureConfig = ToastPhaseConfig(backgroundStyle: redBackground)
		}

		super.init(
			text: BoneToast.TextConfig(message, font: font, color: fontColor),
			activeConfig: activeConfig,
			pendingConfig: pendingConfig,
			successConfig: successConfig,
			failureConfig: resolvedFailureConfig,
			unifiedSymbolStyle: unifiedStyle,
			backgroundStyle: backgroundStyle,
			position: position,
			dismissDelayAfterCompletion: dismissDelayAfterCompletion,
			cornerStyle: cornerStyle
		)
	}
}

// MARK: - Activity Indicator Style

/// The visual style for an activity toast's indicator.
public enum ActivityIndicatorStyle: Sendable {
	/// Standard pulsing dots indicator using `progress.indicator` with variableColor animation.
	/// Best for general-purpose loading states.
	case standard

	/// Rotating partially-filled circle indicator.
	/// The circle is 90% filled and rotates continuously. Best for network operations.
	case network

	/// Custom indicator with user-defined symbol and styling.
	/// - Parameters:
	///   - symbol: SF Symbol name for the indicator
	///   - variableValue: Optional variable value for SF Symbol fill (0.0-1.0)
	///   - weight: Font weight for the symbol (default: .semibold)
	///   - effect: The symbol effect to apply during active/pending phases
	case custom(symbol: String, variableValue: Double? = nil, weight: Font.Weight = .semibold, effect: ActivitySymbolEffect)

	/// Symbol effects available for custom activity indicators
	public enum ActivitySymbolEffect: Sendable, Equatable {
		/// Variable color animation (iterative, dims inactive layers)
		case variableColor
		/// Continuous rotation
		case rotate(speed: Double = 1.0)
		/// Pulsing animation
		case pulse
		/// Breathing animation
		case breathe
		/// No animation (static symbol)
		case none

		/// Check if this is the `.none` case (for comparison without Equatable on associated values)
		var isNone: Bool {
			if case .none = self { return true }
			return false
		}
	}
}

// MARK: - Activity Toast

/// A toast with a spinning indicator for indeterminate operations.
///
/// Use `ActivityToast` when you don't know the progress of an operation.
/// The indicator style can be customized via the `style` parameter.
///
/// ## Usage
/// ```swift
/// // Standard pulsing indicator
/// let toast = ActivityToast("Processing...")
///
/// // Network-style rotating circle
/// let networkToast = ActivityToast("Connecting...", style: .network)
///
/// // Custom indicator
/// let customToast = ActivityToast("Loading...", style: .custom(
///     symbol: "arrow.trianglehead.2.clockwise",
///     effect: .rotate(speed: 1.5)
/// ))
///
/// // Later...
/// toast.complete(message: "Done!")
/// ```
///
/// ## Phase Transitions
/// - **pending → active**: Call `start()`
/// - **active → success**: Call `complete()`
/// - **active → failure**: Call `fail()`
@Observable
public final class ActivityToast: CompletableToast {
	/// Creates an activity toast with a spinning indicator.
	///
	/// - Parameters:
	///   - message: The message to display
	///   - style: The indicator style (default: .standard pulsing dots)
	///   - backgroundStyle: Background style for the toast
	///   - font: Font for the message
	///   - fontColor: Color for text and icons
	///   - position: Screen position
	///   - pendingConfig: Pending phase config (default: `.inheritMessage` enables pending with same message; `nil` disables)
	///   - successConfig: Custom success phase config
	///   - failureConfig: Custom failure phase config
	///   - dismissDelayAfterCompletion: Delay before auto-dismiss
	///   - cornerStyle: Corner shape
	public init(
		_ message: String,
		style: ActivityIndicatorStyle = .standard,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		pendingConfig: ToastPhaseConfig? = .inheritMessage,
		successConfig: ToastPhaseConfig? = nil,
		failureConfig: ToastPhaseConfig? = nil,
		dismissDelayAfterCompletion: TimeInterval = 1.5,
		cornerStyle: BoneToast.CornerStyle = .capsule
	) {
		let resolvedFontColor = fontColor ?? backgroundStyle.defaultFontColor

		// Extract custom symbols from configs (if provided)
		let customSuccessSymbol = successConfig?.symbol.symbolName
		let customFailureSymbol = failureConfig?.symbol.symbolName

		// Build symbols and unified style based on indicator style
		let (_, unifiedStyle) = Self.buildSymbolConfiguration(
			style: style,
			fontColor: resolvedFontColor,
			successSymbol: customSuccessSymbol,
			failureSymbol: customFailureSymbol
		)

		// Phase configs for text/message handling
		let activeConfig = ToastPhaseConfig(title: message)

		// Default failure config uses red tint, inheriting style type from base
		let resolvedFailureConfig: ToastPhaseConfig?
		if let explicit = failureConfig {
			resolvedFailureConfig = explicit
		} else {
			let redBackground: BoneToast.BackgroundStyle = switch backgroundStyle {
				case .glass: .glass(tintColor: .red)
				case .solid: .solid(.red)
			}
			resolvedFailureConfig = ToastPhaseConfig(backgroundStyle: redBackground)
		}

		super.init(
			text: BoneToast.TextConfig(message, font: font, color: fontColor),
			activeConfig: activeConfig,
			pendingConfig: pendingConfig,
			successConfig: successConfig,
			failureConfig: resolvedFailureConfig,
			unifiedSymbolStyle: unifiedStyle,
			backgroundStyle: backgroundStyle,
			position: position,
			dismissDelayAfterCompletion: dismissDelayAfterCompletion,
			cornerStyle: cornerStyle
		)
	}

	/// Builds the symbol configuration for the given indicator style
	private static func buildSymbolConfiguration(
		style: ActivityIndicatorStyle,
		fontColor: Color,
		successSymbol: String? = nil,
		failureSymbol: String? = nil
	) -> (ToastSymbols, ToastUnifiedSymbolStyle) {
		// Default symbols (can be overridden by successConfig/failureConfig)
		let resolvedSuccessSymbol = successSymbol ?? "checkmark.circle.fill"
		let resolvedFailureSymbol = failureSymbol ?? "xmark.circle.fill"

		switch style {
			case .standard:
				let symbols = ToastSymbols(
					active: "progress.indicator",
					pending: nil,
					success: resolvedSuccessSymbol,
					failure: resolvedFailureSymbol,
					hasEffects: true,
					replaceFallback: .downUp
				)
				let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
					image
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(fontColor)
						.symbolRenderingMode(.hierarchical)
						.symbolEffect(
							.variableColor.iterative.dimInactiveLayers.nonReversing,
							options: .repeat(.continuous),
							isActive: (phase == .active || phase == .pending) && effectEnabled
						)
						.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false)
				}
				return (symbols, unifiedStyle)

			case .network:
				let symbols = ToastSymbols(
					active: "circle",
					pending: nil,
					success: resolvedSuccessSymbol,
					failure: resolvedFailureSymbol,
					hasEffects: true,
					replaceFallback: .downUp,
					staticVariableValue: 0.9
				)
				let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
					let styledImage = image
						.font(.system(size: 16, weight: .bold))
						.foregroundStyle(fontColor)
						.symbolRenderingMode(.hierarchical)

					switch phase {
						case .active, .pending:
							AnyView(styledImage
								.symbolEffect(.rotate, options: .repeat(.continuous).speed(2), isActive: effectEnabled))
						case .success:
							AnyView(styledImage
								.symbolEffect(.bounce, value: effectEnabled))
						case .failure:
							AnyView(styledImage)
					}
				}
				return (symbols, unifiedStyle)

			case .custom(let symbol, let variableValue, let weight, let effect):
				let symbols = ToastSymbols(
					active: symbol,
					pending: nil,
					success: resolvedSuccessSymbol,
					failure: resolvedFailureSymbol,
					hasEffects: !effect.isNone,
					replaceFallback: !effect.isNone ? .downUp : .offUp,
					staticVariableValue: variableValue
				)
				let unifiedStyle = ToastUnifiedSymbolStyle(symbols: symbols) { image, phase, effectEnabled in
					let styledImage = image
						.font(.system(size: 16, weight: weight))
						.foregroundStyle(fontColor)
						.symbolRenderingMode(.hierarchical)

					let isActivePhase = (phase == .active || phase == .pending) && effectEnabled

					switch effect {
						case .variableColor:
							AnyView(styledImage
								.symbolEffect(
									.variableColor.iterative.dimInactiveLayers.nonReversing,
									options: .repeat(.continuous),
									isActive: isActivePhase
								)
								.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false))
						case .rotate(let speed):
							switch phase {
								case .active, .pending:
									AnyView(styledImage
										.symbolEffect(.rotate, options: .repeat(.continuous).speed(speed), isActive: effectEnabled))
								case .success:
									AnyView(styledImage
										.symbolEffect(.bounce, value: effectEnabled))
								case .failure:
									AnyView(styledImage)
							}
						case .pulse:
							AnyView(styledImage
								.symbolEffect(.pulse, options: .repeat(.continuous), isActive: isActivePhase)
								.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false))
						case .breathe:
							AnyView(styledImage
								.symbolEffect(.breathe, options: .repeat(.continuous), isActive: isActivePhase)
								.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false))
						case .none:
							AnyView(styledImage
								.symbolEffect(.bounce, value: phase == .success ? effectEnabled : false))
					}
				}
				return (symbols, unifiedStyle)
		}
	}
}

/// Type alias for backwards compatibility - use `ActivityToast` with `.network` style instead
@available(*, deprecated, renamed: "ActivityToast", message: "Use ActivityToast with style: .network")
public typealias NetworkActivityToast = ActivityToast

// MARK: - Network Activity Toast Convenience

public extension ActivityToast {
	/// Creates a network-style activity toast with a rotating circle indicator.
	///
	/// This is a convenience initializer equivalent to `ActivityToast(..., style: .network)`.
	///
	/// - Parameters:
	///   - message: The message to display
	///   - backgroundStyle: Background style for the toast
	///   - font: Font for the message
	///   - fontColor: Color for text and icons
	///   - position: Screen position
	///   - pendingConfig: Pending phase config (default: `.inheritMessage` enables pending with same message; `nil` disables)
	///   - successConfig: Custom success phase config
	///   - failureConfig: Custom failure phase config
	///   - dismissDelayAfterCompletion: Delay before auto-dismiss
	///   - cornerStyle: Corner shape
	static func network(
		_ message: String,
		backgroundStyle: BoneToast.BackgroundStyle = .glass,
		font: Font = .system(size: 16, weight: .semibold),
		fontColor: Color? = nil,
		position: BoneToast.Position? = nil,
		pendingConfig: ToastPhaseConfig? = .inheritMessage,
		successConfig: ToastPhaseConfig? = nil,
		failureConfig: ToastPhaseConfig? = nil,
		dismissDelayAfterCompletion: TimeInterval = 1.5,
		cornerStyle: BoneToast.CornerStyle = .capsule
	) -> ActivityToast {
		ActivityToast(
			message,
			style: .network,
			backgroundStyle: backgroundStyle,
			font: font,
			fontColor: fontColor,
			position: position,
			pendingConfig: pendingConfig,
			successConfig: successConfig,
			failureConfig: failureConfig,
			dismissDelayAfterCompletion: dismissDelayAfterCompletion,
			cornerStyle: cornerStyle
		)
	}
}

// MARK: - Completable Toast Content View

/// A reusable view that handles smooth animated transitions between active and completed states.
/// Content updates in place rather than being swapped for smoother animations.
/// Includes background styling within Observable context for proper animation.
@MainActor
private struct CompletableToastContentView<Toast: CompletableBoneToastType>: View {
	@Bindable var toast: Toast
	
	var body: some View {
		// Consistent spacing of 8 between all elements (icon ↔ text ↔ button)
		HStack(spacing: 8) {
			toast.iconView
			Text(toast.message)
				.font(toast.font)
				.foregroundColor(toast.fontColor)
				.multilineTextAlignment(toast.textAlignment.textAlignment)
				.lineLimit(1)
				.contentTransition(.interpolate)
				.animation(.smooth(duration: 0.15), value: toast.message)
			if let actionButton = toast.currentActionButton {
				ActionButtonView(
					config: actionButton,
					toastBackgroundStyle: toast.backgroundStyle,
					toastFontColor: toast.fontColor,
					onDismiss: { toast.actionButtonTapped = true }
				)
			}
		}
		.toastPadding(toast.contentPadding)
		.frame(minHeight: 44) // Minimum touch target height
		.modifier(CompletableToastBackgroundModifier(toast: toast))
		.geometryGroup() // Coordinates animations across children
		.animation(.smooth(duration: 0.2), value: toast.isReadyToDismiss)
		.animation(.smooth(duration: 0.2), value: toast.message)
		.animation(.smooth(duration: 0.2), value: toast.phase)
	}
}

/// Background modifier for completable toasts that animates with state changes.
@MainActor
private struct CompletableToastBackgroundModifier<Toast: CompletableBoneToastType>: ViewModifier {
	@Bindable var toast: Toast
	
	func body(content: Content) -> some View {
		let state = toast.phase
		let backgroundStyle = toast.backgroundStyle
		let cornerStyle = toast.cornerStyle
		
		// Extract current tint color
		let currentColor: Color = {
			switch backgroundStyle {
				case .glass(_, let tint): return tint ?? .clear
				case .solid(let color, _): return color ?? Color(uiColor: .secondarySystemBackground)
			}
		}()
		
		content
			.background {
				ToastBackgroundShape(cornerStyle: cornerStyle)
					.fill(currentColor)
			}
			.modifier(BoneOverlayModifier(backgroundStyle: backgroundStyle, cornerStyle: cornerStyle))
			.animation(.smooth(duration: 0.25), value: state)
	}
}

/// Applies glass effect overlay when needed
private struct BoneOverlayModifier: ViewModifier {
	let backgroundStyle: BoneToast.BackgroundStyle
	let cornerStyle: BoneToast.CornerStyle
	
	private var isGlass: Bool {
		if case .glass = backgroundStyle { return true }
		return false
	}
	
	private var glassStyle: BoneToast.EffectStyle {
		if case .glass(let style, _) = backgroundStyle { return style }
		return .regular
	}
	
	func body(content: Content) -> some View {
		if #available(iOS 26.0, *), isGlass {
			switch cornerStyle {
				case .capsule:
					content.glassEffect(glassStyle == .regular ? .regular : .clear, in: Capsule())
				case .roundedRect(let r):
					content.glassEffect(glassStyle == .regular ? .regular : .clear, in: RoundedRectangle(cornerRadius: r, style: .continuous))
			}
		} else {
			content
		}
	}
}

// MARK: - Public Conditional Effect Extensions

public extension View {
	/// Conditionally applies a variable color spinner effect to an SF Symbol.
	///
	/// Use this in view builders to ensure smooth `.replace` transitions. The effect is
	/// completely removed when `isActive` is false (not just paused), which prevents
	/// visual artifacts during symbol transitions.
	///
	/// Example:
	/// ```swift
	/// ActivityToast(
	///     text: BoneToast.TextConfig("Syncing..."),
	///     activeIcon: { isSpinning in
	///         Image(systemName: "arrow.triangle.2.circlepath")
	///             .conditionalVariableColorEffect(isActive: isSpinning)
	///     },
	///     // ...
	/// )
	/// ```
	///
	/// - Parameter isActive: Whether the effect should be applied
	/// - Returns: The view with or without the variable color effect
	@ViewBuilder
	func conditionalVariableColorEffect(isActive: Bool) -> some View {
		if isActive {
			self.symbolEffect(
				.variableColor.iterative.dimInactiveLayers.nonReversing,
				options: .repeat(.continuous)
			)
		} else {
			self
		}
	}
	
	/// Conditionally applies a rotation spinner effect to an SF Symbol.
	///
	/// Use this in view builders to ensure smooth `.replace` transitions. The effect is
	/// completely removed when `isActive` is false (not just paused), which prevents
	/// visual artifacts during symbol transitions.
	///
	/// - Parameter isActive: Whether the effect should be applied
	/// - Returns: The view with or without the rotation effect
	@ViewBuilder
	func conditionalRotateEffect(isActive: Bool) -> some View {
		if isActive {
			self.symbolEffect(.rotate.clockwise.byLayer, options: .repeat(.continuous))
		} else {
			self
		}
	}
	
	/// Conditionally applies a custom symbol effect.
	///
	/// Use this to apply any custom `.symbolEffect()` configuration that will be completely
	/// removed when `isActive` is false, ensuring smooth `.replace` transitions.
	///
	/// Example:
	/// ```swift
	/// Image(systemName: "arrow.triangle.2.circlepath")
	///     .conditionalEffect(isActive: isAnimating) { view in
	///         view.symbolEffect(
	///             .variableColor.iterative.dimInactiveLayers.nonReversing,
	///             options: .repeat(.continuous)
	///         )
	///     }
	/// ```
	///
	/// - Parameters:
	///   - isActive: Whether the effect should be applied
	///   - effectBuilder: Closure that applies the effect to the view
	/// - Returns: The view with or without the effect
	@ViewBuilder
	func conditionalEffect<EffectedView: View>(
		isActive: Bool,
		@ViewBuilder apply effectBuilder: (Self) -> EffectedView
	) -> some View {
		if isActive {
			effectBuilder(self)
		} else {
			self
		}
	}
}

/// Handles SF Symbol transitions using a unified styling approach.
///
/// This view maintains ONE Image internally and passes it to a SINGLE styling closure
/// along with the current phase. This preserves view identity for smooth `.replace` transitions.
///
/// Features:
/// - Symbol names are separate from styling
/// - ONE styling closure handles ALL phases (ensures consistent view structure)
/// - Styling closure receives (Image, Phase, effectEnabled) and returns styled view
/// - Supports variableValue for progress indicators
/// - Configurable `.replace` fallback effect via `symbols.replaceFallback`
///
/// Transition sequence:
/// 1. `effectEnabled = false` - disables current icon's animation
/// 2. `displayedPhase = newPhase` - changes symbol name (triggers .replace animation)
/// 3. Task.sleep() - waits for .replace animation to complete
/// 4. `effectEnabled = true` - enables new icon's animation
///
/// Choosing a `.replace` fallback effect:
/// - `.offUp` (default): Best when colors change between phases. The outgoing symbol fades
///   in place rather than animating down, minimizing the visibility of color changes on the
///   outgoing symbol during the transition.
/// - `.downUp` or `.upUp`: Best when using `.variableColor` or similar continuous animations.
///   These effects halt the animation before the replace transition, resulting in a smoother
///   handoff. With `.offUp`, the variableColor animation may conflict with the incoming symbol,
///   causing visual jitter.
@MainActor
private struct HybridSymbolTransitionView: View {
	let phase: BoneToast.Phase
	
	/// Symbol names for each phase
	let symbols: ToastSymbols
	
	/// Unified styling closure: (Image, Phase, effectEnabled) -> AnyView
	/// One closure handles all phases, ensuring consistent view structure for smooth transitions.
	let style: @MainActor (Image, BoneToast.Phase, Bool) -> AnyView
	
	/// Variable value for the SF Symbol (used for progress indicators).
	/// For active phase, this drives the symbol's fill level (0.0-1.0).
	/// For completion phases, defaults to 1.0.
	let variableValue: Double
	
	/// Internal state that controls which phase is displayed.
	/// This lags behind `phase` to allow effects to settle before transitions.
	@State private var displayedPhase: BoneToast.Phase = .pending
	
	/// Whether the current icon's animation effect should be enabled.
	/// Disabled during transitions to prevent visual artifacts.
	@State private var effectEnabled = false
	
	/// Whether the view has completed initial setup.
	/// Prevents race conditions when phase changes arrive before onAppear completes.
	@State private var isReady = false
	
	/// The current symbol name based on displayedPhase
	private var currentSymbol: String {
		switch displayedPhase {
			case .pending: symbols.pending ?? symbols.active
			case .active: symbols.active
			case .success: symbols.success
			case .failure: symbols.failure
		}
	}
	
	/// Whether the given phase uses the active symbol (pending with nil symbol)
	private var pendingUsesActiveSymbol: Bool {
		symbols.pending == nil
	}
	
	/// The variable value to use for the current phase
	private var currentVariableValue: Double {
		switch displayedPhase {
			case .pending:
				// Use static value if set, otherwise 0.0 for pending
				symbols.staticVariableValue ?? 0.0
			case .active:
				// Use static value if set, otherwise the toast's progress value
				symbols.staticVariableValue ?? variableValue
			case .success, .failure:
				1.0
		}
	}
	
	var body: some View {
		// Create ONE Image with the current symbol name and variable value
		let baseImage = Image(systemName: currentSymbol, variableValue: currentVariableValue)
		
		// Pass it to the unified styling closure with current phase
		// On iOS 26+, apply .symbolVariableValueMode(.draw) for proper fill drawing
		Group {
			if #available(iOS 26.0, *) {
				style(baseImage, displayedPhase, effectEnabled)
					.symbolVariableValueMode(.draw)
			} else {
				style(baseImage, displayedPhase, effectEnabled)
			}
		}
		.contentTransition(.symbolEffect(.replace.magic(fallback: symbols.replaceFallback)))
		.onChange(of: phase) { oldPhase, newPhase in
			// Guard: If not ready yet, just sync displayedPhase directly
			// This handles race conditions where start() is called before onAppear completes
			guard isReady else {
				displayedPhase = newPhase
				return
			}
			
			// Special case: pending → active with same symbol (no replace animation needed)
			if oldPhase == .pending && newPhase == .active && pendingUsesActiveSymbol {
				displayedPhase = newPhase
				// Keep effects running since it's the same symbol
				return
			}
			
			// Disable effects before transition
			effectEnabled = false
			
			// Use Task to allow effect to stop rendering before symbol swap
			Task {
				// Yield to let outgoing effect settle
				await Task.yield()
				
				// Swap symbol (triggers .replace animation)
				displayedPhase = newPhase
				
				// Re-enable effects after animation completes (if any effects are used)
				if symbols.hasEffects {
					try? await Task.sleep(for: .milliseconds(350))
					effectEnabled = true
				}
			}
		}
		.onAppear {
			displayedPhase = phase
			if symbols.hasEffects {
				Task {
					await Task.yield()
					effectEnabled = true
					isReady = true
				}
			} else {
				effectEnabled = true
				isReady = true
			}
		}
	}
}

// MARK: - SwiftUI Binding-Based Global Toast

/// Modifier that shows a global toast when a binding is true
private struct GlobalToastModifier<T: BoneToastType>: ViewModifier {
	@Binding var isPresented: Bool
	let toast: () -> T
	@State private var currentToastId: UUID?
	
	func body(content: Content) -> some View {
		content
			.onChange(of: isPresented, initial: true) { _, newValue in
				if newValue {
					showToast()
				} else if let id = currentToastId {
					BoneToastManager.dismiss(id: id)
					currentToastId = nil
				}
			}
			.onDisappear {
				// Dismiss toast if view disappears while toast is showing
				if let id = currentToastId {
					BoneToastManager.dismiss(id: id)
					currentToastId = nil
				}
			}
	}
	
	private func showToast() {
		let newToast = toast()
		currentToastId = newToast.id
		BoneToastManager.show(newToast) { [self] in
			// Sync binding when toast is dismissed
			currentToastId = nil
			isPresented = false
		}
	}
}

/// Controller that manages the persistent global toast window
@MainActor
private final class GlobalToastWindowController {
	private var window: PassthroughWindow?
	private var hostingController: UIHostingController<GlobalToastContainerView>?
	private let manager: BoneToastManager
	private var sceneObserver: NSObjectProtocol?
	
	init(manager: BoneToastManager) {
		self.manager = manager
	}
	
	// Note: No deinit needed - this controller is owned by the BoneToastManager singleton
	// and lives for the app's lifetime. The observer will be cleaned up on app termination.
	
	func setup() {
		// Observe scene connections to set up window when a scene becomes available
		sceneObserver = NotificationCenter.default.addObserver(
			forName: UIScene.didActivateNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor in
				self?.createWindowIfNeeded()
			}
		}
		
		// Try to create immediately if a scene is already available
		createWindowIfNeeded()
	}
	
	private func createWindowIfNeeded() {
		guard window == nil else { return }
		
		guard let windowScene = UIApplication.shared.connectedScenes
			.compactMap({ $0 as? UIWindowScene })
			.first(where: { $0.activationState == .foregroundActive })
				?? UIApplication.shared.connectedScenes
			.compactMap({ $0 as? UIWindowScene })
			.first
		else { return }
		
		let toastWindow = PassthroughWindow(windowScene: windowScene)
		toastWindow.windowLevel = .alert + 100 // Higher than regular alerts
		toastWindow.backgroundColor = .clear
		
		let view = GlobalToastContainerView(manager: manager) { [weak self] frames in
			self?.window?.interactiveRects = frames
		}
		let hosting = UIHostingController(rootView: view)
		hosting.view.backgroundColor = .clear
		hosting.view.frame = toastWindow.bounds
		hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		toastWindow.rootViewController = hosting
		toastWindow.isHidden = false
		
		self.window = toastWindow
		self.hostingController = hosting
	}
}

/// The SwiftUI view displayed in the global toast window
private struct GlobalToastContainerView: View {
	let manager: BoneToastManager
	let onFramesChange: ([CGRect]) -> Void
	
	@State private var currentToastIDs: [UUID] = []
	@State private var isReady = false
	
	private var topToasts: [any BoneToastType] {
		guard isReady else { return [] }
		return manager.toasts.filter { ($0.positionOverride ?? manager.defaultPosition) == .top }.sorted(pinning: manager.pinning, stackOrder: manager.stackOrder, for: .top)
	}
	
	private var bottomToasts: [any BoneToastType] {
		guard isReady else { return [] }
		return manager.toasts.filter { ($0.positionOverride ?? manager.defaultPosition) == .bottom }.sorted(pinning: manager.pinning, stackOrder: manager.stackOrder, for: .bottom)
	}
	
	/// Resolves position for a toast using the manager's default if not specified
	private func resolvedPosition(for toast: any BoneToastType) -> BoneToast.Position {
		toast.positionOverride ?? manager.defaultPosition
	}
	
	/// Computes effective transition for a toast
	private func effectiveTransition(for toast: any BoneToastType) -> BoneToast.Transition {
		toast.animationConfig?.transition ?? manager.animationConfig.transition
	}
	
	/// Computes effective timing for a toast
	private func effectiveTiming(for toast: any BoneToastType) -> BoneToast.Timing {
		toast.animationConfig?.timing ?? manager.animationConfig.timing
	}
	
	var body: some View {
		let topList = topToasts
		let bottomList = bottomToasts
		GeometryReader { outerGeometry in
			let safeTop = outerGeometry.safeAreaInsets.top
			let safeBottom = outerGeometry.safeAreaInsets.bottom
			
			ZStack(alignment: .top) {
				Color.clear
				
				// Top toasts
				VStack(spacing: manager.toastSpacing) {
					ForEach(Array(topList.enumerated()), id: \.element.id) { index, toast in
						let transition = effectiveTransition(for: toast)
						let timing = effectiveTiming(for: toast)
						AnyToastViewForWindow(toast: toast, resolvedPosition: .top, transition: transition, timing: timing) {
							manager.dismiss(id: toast.id)
						}
						.transition(transition.transition(for: .top))
						.zIndex(Double(topList.count - index))
					}
				}
				.padding(.top, safeTop)
				
				// Bottom toasts
				VStack(spacing: manager.toastSpacing) {
					ForEach(Array(bottomList.enumerated()), id: \.element.id) { index, toast in
						let transition = effectiveTransition(for: toast)
						let timing = effectiveTiming(for: toast)
						AnyToastViewForWindow(toast: toast, resolvedPosition: .bottom, transition: transition, timing: timing) {
							manager.dismiss(id: toast.id)
						}
						.transition(transition.transition(for: .bottom))
						.zIndex(Double(bottomList.count - index))
					}
				}
				.frame(maxHeight: .infinity, alignment: .bottom)
				.padding(.bottom, safeBottom)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
		}
		.onPreferenceChange(ToastFramePreferenceKey.self) { frames in
			onFramesChange(Array(frames.values))
		}
		.task {
			// Small delay to ensure the view renders with empty state first,
			// allowing the first toast to animate in properly
			try? await Task.sleep(for: .milliseconds(16))
			withAnimation(manager.animationConfig.timing.animation) {
				isReady = true
			}
			await observeToastChanges()
		}
		.animation(manager.animationConfig.timing.animation, value: currentToastIDs)
	}
	
	@MainActor
	private func observeToastChanges() async {
		while !Task.isCancelled {
			let newIDs = manager.toasts.map(\.id)
			if newIDs != currentToastIDs {
				withAnimation(manager.animationConfig.timing.animation) {
					currentToastIDs = newIDs
				}
				if newIDs.isEmpty {
					onFramesChange([])
				}
			}
			try? await Task.sleep(for: .milliseconds(16))
		}
	}
}

/// Toast view for window-based presentation (used by BoneToastManager)
/// Applies horizontal-only edge padding since safe area handles vertical positioning
private struct AnyToastViewForWindow: View {
	let toast: any BoneToastType
	let resolvedPosition: BoneToast.Position
	let transition: BoneToast.Transition
	let timing: BoneToast.Timing
	let onDismiss: () -> Void
	
	@State private var dragOffset: CGFloat = 0
	private let dismissThreshold: CGFloat = 50
	
	/// Convert edge padding to horizontal-only padding for window presentation
	private var horizontalPadding: EdgeInsets {
		switch toast.edgePadding {
			case .none:
				return EdgeInsets()
			case .systemDefault:
				return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
			case .custom(let insets):
				return EdgeInsets(top: 0, leading: insets.leading, bottom: 0, trailing: insets.trailing)
		}
	}
	
	var body: some View {
		toast.content
			.modifier(ToastWidthModifier(expandWidth: toast.expandWidth))
			.modifier(ConditionalBackgroundModifier(
				applyBackground: !toast.contentIncludesBackground,
				backgroundStyle: toast.backgroundStyle,
				cornerStyle: toast.cornerStyle
			))
			.padding(horizontalPadding)
			.contentShape(Rectangle())
			.offset(y: dragOffset)
			.gesture(swipeGesture)
			.onTapGesture(perform: handleTap)
			.overlay(frameReporter)
	}
	
	private var frameReporter: some View {
		GeometryReader { geometry in
			Color.clear
				.preference(key: ToastFramePreferenceKey.self, value: [toast.id: geometry.frame(in: .global)])
		}
		.allowsHitTesting(false)
	}
	
	private var swipeGesture: some Gesture {
		DragGesture()
			.onChanged { value in
				guard canDismiss else { return }
				
				let translation = value.translation.height
				if resolvedPosition == .top && translation < 0 {
					dragOffset = translation
				} else if resolvedPosition == .bottom && translation > 0 {
					dragOffset = translation
				}
			}
			.onEnded { value in
				guard canDismiss else { return }
				
				let translation = value.translation.height
				let shouldDismiss: Bool
				if resolvedPosition == .top {
					shouldDismiss = translation < -dismissThreshold
				} else {
					shouldDismiss = translation > dismissThreshold
				}
				
				if shouldDismiss {
					onDismiss()
				} else {
					withAnimation(timing.animation) {
						dragOffset = 0
					}
				}
			}
	}
	
	private func handleTap() {
		guard canDismiss else { return }
		onDismiss()
	}
	
	private var canDismiss: Bool {
		guard toast.interactive else { return false }
		switch toast.dismissBehavior {
			case .afterDelay, .manual:
				return true
			case .whenReady:
				return toast.isReadyToDismiss
		}
	}
}

// MARK: - Toast Manager

/// Manages a queue of toasts, handling positioning and automatic dismissal.
/// The manager is agnostic to toast types - it relies on the BoneToastType protocol.
///
/// Use `BoneToastManager.shared` for global toasts that appear above all content (including modals).
/// Create an instance for scoped toasts within a specific view hierarchy.
///
/// ```swift
/// // Global toasts (window-based, above everything)
/// BoneToastManager.show(StandardToast.success("Saved!"))
///
/// // Scoped toasts (overlay-based, within view hierarchy)
/// @State private var manager = BoneToastManager()
/// // ... .scopedToastContainer(manager: manager)
/// ```
@Observable
@MainActor
public final class BoneToastManager {
	// MARK: - Shared Instance (Global Toasts)
	
	/// The shared global toast manager instance.
	/// Toasts shown via this instance appear in a dedicated window above all content.
	public static let shared = BoneToastManager(isGlobal: true)
	
	// MARK: - Static Convenience Methods
	
	/// Shows a toast globally (convenience for `BoneToastManager.shared.show(_:)`)
	@discardableResult
	public static func show<T: BoneToastType>(_ toast: T) -> T {
		shared.show(toast)
	}
	
	/// Shows a toast globally with a dismiss callback
	@discardableResult
	public static func show<T: BoneToastType>(_ toast: T, onDismiss: (@MainActor () -> Void)?) -> T {
		shared.show(toast, onDismiss: onDismiss)
	}
	
	/// Dismisses a global toast by ID
	public static func dismiss(id: UUID) {
		shared.dismiss(id: id)
	}
	
	/// Dismisses all global toasts
	public static func dismissAll() {
		shared.dismissAll()
	}
	
	// MARK: - Properties
	
	public private(set) var toasts: [any BoneToastType] = []
	private var dismissTasks: [UUID: Task<Void, Never>] = [:]
	private var observationTasks: [UUID: Task<Void, Never>] = [:]
	private var actionButtonTasks: [UUID: Task<Void, Never>] = [:]
	private var dismissCallbacks: [UUID: @MainActor () -> Void] = [:]
	
	/// Whether this is the global (window-based) manager
	private let isGlobal: Bool
	
	/// Controller managing the persistent toast window (global mode only)
	private var windowController: GlobalToastWindowController?
	
	/// Whether the global toast window has been set up
	public private(set) var isSetup: Bool = false
	
	/// Configuration for which toast types should be pinned to the top of the queue
	public var pinning: BoneToast.Pinning
	
	/// Default animation configuration for toast transitions
	public var animationConfig: BoneToast.AnimationConfig
	
	/// Default position for toasts that don't specify their own position
	public var defaultPosition: BoneToast.Position
	
	/// Spacing between stacked toasts (default: 6)
	public var toastSpacing: CGFloat
	
	/// Controls how new toasts are stacked relative to existing ones
	public var stackOrder: BoneToast.StackOrder
	
	// MARK: - Initialization
	
	/// Creates a scoped toast manager for use with `.scopedToastContainer(manager:)`
	public init(
		pinning: BoneToast.Pinning = .none,
		animationConfig: BoneToast.AnimationConfig = .bounce,
		defaultPosition: BoneToast.Position = .top,
		toastSpacing: CGFloat = 6,
		stackOrder: BoneToast.StackOrder = .newestFirst
	) {
		self.isGlobal = false
		self.pinning = pinning
		self.animationConfig = animationConfig
		self.defaultPosition = defaultPosition
		self.toastSpacing = toastSpacing
		self.stackOrder = stackOrder
	}
	
	/// Private initializer for the global shared instance
	private init(isGlobal: Bool) {
		self.isGlobal = isGlobal
		self.pinning = .none
		self.animationConfig = .bounce
		self.defaultPosition = .top
		self.toastSpacing = 6
		self.stackOrder = .newestFirst
	}
	
	// MARK: - Global Setup
	
	/// Sets up the global toast window. Called automatically on first toast, but can be called
	/// explicitly at app launch for eager initialization. Only affects the shared instance.
	public func setup() {
		guard isGlobal, !isSetup else { return }
		windowController = GlobalToastWindowController(manager: self)
		windowController?.setup()
		isSetup = true
	}
	
	/// Shows a toast and returns it for further manipulation
	@discardableResult
	public func show<T: BoneToastType>(_ toast: T) -> T {
		show(toast, onDismiss: nil)
	}
	
	/// Shows a toast with an optional dismiss callback
	/// - Parameters:
	///   - toast: The toast to display
	///   - onDismiss: Called when the toast is dismissed (by auto-dismiss, user tap, swipe, or programmatic dismissal)
	/// - Returns: The same toast instance for chaining or later reference
	@discardableResult
	public func show<T: BoneToastType>(_ toast: T, onDismiss: (@MainActor () -> Void)?) -> T {
		// Auto-setup for global instance
		if isGlobal && !isSetup {
			setup()
		}
		
		let effectiveTiming = toast.animationConfig?.timing ?? animationConfig.timing
		withAnimation(effectiveTiming.animation) {
			// Simply append toasts - sorting by pinning is handled in the view
			toasts.append(toast)
		}
		
		if let onDismiss {
			dismissCallbacks[toast.id] = onDismiss
		}
		
		setupDismissal(for: toast)
		return toast
	}
	
	/// Dismisses a specific toast by ID
	public func dismiss(id: UUID) {
		dismissTasks[id]?.cancel()
		dismissTasks.removeValue(forKey: id)
		observationTasks[id]?.cancel()
		observationTasks.removeValue(forKey: id)
		actionButtonTasks[id]?.cancel()
		actionButtonTasks.removeValue(forKey: id)
		
		let callback = dismissCallbacks.removeValue(forKey: id)
		
		withAnimation(animationConfig.timing.animation) {
			toasts.removeAll { $0.id == id }
		}
		
		// Call the dismiss callback after removing the toast
		callback?()
	}
	
	/// Dismisses all toasts
	public func dismissAll() {
		for (id, task) in dismissTasks {
			task.cancel()
			dismissTasks.removeValue(forKey: id)
		}
		for (id, task) in observationTasks {
			task.cancel()
			observationTasks.removeValue(forKey: id)
		}
		for (id, task) in actionButtonTasks {
			task.cancel()
			actionButtonTasks.removeValue(forKey: id)
		}
		
		let callbacks = dismissCallbacks
		dismissCallbacks.removeAll()
		
		withAnimation(animationConfig.timing.animation) {
			toasts.removeAll()
		}
		
		// Call all dismiss callbacks
		for callback in callbacks.values {
			callback()
		}
	}
	
	/// Returns whether the manager has any toasts
	public var isEmpty: Bool {
		toasts.isEmpty
	}
	
	// MARK: - Private
	
	private func setupDismissal(for toast: any BoneToastType) {
		switch toast.dismissBehavior {
			case .afterDelay(let delay):
				if toast.hasActionButton {
					// For action button toasts: wait for button tap, then start delay
					let task = Task { [weak self] in
						while !Task.isCancelled && !toast.actionButtonTapped {
							try? await Task.sleep(for: .milliseconds(50))
						}
						guard !Task.isCancelled else { return }
						try? await Task.sleep(for: .seconds(delay))
						guard !Task.isCancelled else { return }
						self?.dismiss(id: toast.id)
					}
					actionButtonTasks[toast.id] = task
				} else {
					// For regular toasts: start delay immediately
					let task = Task { [weak self] in
						try? await Task.sleep(for: .seconds(delay))
						guard !Task.isCancelled else { return }
						self?.dismiss(id: toast.id)
					}
					dismissTasks[toast.id] = task
				}
				
			case .whenReady(let delay):
				// Observe isReadyToDismiss and dismiss when true (same for all toasts)
				let task = Task { [weak self] in
					while !Task.isCancelled {
						if toast.isReadyToDismiss {
							try? await Task.sleep(for: .seconds(delay))
							guard !Task.isCancelled else { return }
							self?.dismiss(id: toast.id)
							return
						}
						try? await Task.sleep(for: .milliseconds(100))
					}
				}
				observationTasks[toast.id] = task
				
			case .manual:
				// Manual dismiss - do nothing, toast stays until explicitly dismissed
				break
		}
	}
}

// MARK: - Toast View

private struct AnyToastView: View {
	let toast: any BoneToastType
	let resolvedPosition: BoneToast.Position
	let transition: BoneToast.Transition
	let timing: BoneToast.Timing
	let onDismiss: () -> Void
	
	@State private var dragOffset: CGFloat = 0
	private let dismissThreshold: CGFloat = 50
	
	/// Convert edge padding to horizontal-only for stacked toasts
	private var horizontalPadding: EdgeInsets {
		switch toast.edgePadding {
			case .none:
				return EdgeInsets()
			case .systemDefault:
				return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
			case .custom(let insets):
				return EdgeInsets(top: 0, leading: insets.leading, bottom: 0, trailing: insets.trailing)
		}
	}
	
	var body: some View {
		toast.content
			.modifier(ToastWidthModifier(expandWidth: toast.expandWidth))
			.modifier(ConditionalBackgroundModifier(
				applyBackground: !toast.contentIncludesBackground,
				backgroundStyle: toast.backgroundStyle,
				cornerStyle: toast.cornerStyle
			))
			.padding(horizontalPadding)
			.contentShape(Rectangle())
			.offset(y: dragOffset)
			.gesture(swipeGesture)
			.onTapGesture(perform: handleTap)
			.overlay(frameReporter)
	}
	
	private var frameReporter: some View {
		GeometryReader { geometry in
			Color.clear
				.preference(key: ToastFramePreferenceKey.self, value: [toast.id: geometry.frame(in: .global)])
		}
		.allowsHitTesting(false)
	}
	
	private var swipeGesture: some Gesture {
		DragGesture()
			.onChanged { value in
				// Only allow swipe if toast is ready to dismiss or has no completion requirement
				guard canDismiss else { return }
				
				let translation = value.translation.height
				if resolvedPosition == .top && translation < 0 {
					dragOffset = translation
				} else if resolvedPosition == .bottom && translation > 0 {
					dragOffset = translation
				}
			}
			.onEnded { value in
				guard canDismiss else { return }
				
				let translation = value.translation.height
				let shouldDismiss: Bool
				if resolvedPosition == .top {
					shouldDismiss = translation < -dismissThreshold
				} else {
					shouldDismiss = translation > dismissThreshold
				}
				
				if shouldDismiss {
					onDismiss()
				} else {
					withAnimation(timing.animation) {
						dragOffset = 0
					}
				}
			}
	}
	
	private func handleTap() {
		guard canDismiss else { return }
		onDismiss()
	}
	
	private var canDismiss: Bool {
		guard toast.interactive else { return false }
		switch toast.dismissBehavior {
			case .afterDelay, .manual:
				return true
			case .whenReady:
				return toast.isReadyToDismiss
		}
	}
}

// MARK: - View Extensions

// MARK: - Toast Sorting for Scoped Manager

private extension Array where Element == any BoneToastType {
	@MainActor
	func sorted(pinning: BoneToast.Pinning, stackOrder: BoneToast.StackOrder, for position: BoneToast.Position) -> [any BoneToastType] {
		let pinned = self.filter { pinning.shouldPin($0.dismissBehavior) }
		let nonPinned = self.filter { !pinning.shouldPin($0.dismissBehavior) }
		
		// Apply stack order (reverse for newestFirst so newest appears at edge)
		let orderedPinned = stackOrder == .newestFirst ? pinned.reversed() : pinned
		let orderedNonPinned = stackOrder == .newestFirst ? nonPinned.reversed() : nonPinned
		
		if position == .top {
			// Pinned toasts stay at top (closest to edge)
			return Array(orderedPinned) + Array(orderedNonPinned)
		} else {
			// Pinned toasts stay at bottom (closest to edge)
			return Array(orderedNonPinned) + Array(orderedPinned)
		}
	}
}

// MARK: - Scoped Toast Overlay Modifier

private struct BoneToastOverlayModifier: ViewModifier {
	@Bindable var manager: BoneToastManager
	let position: BoneToast.Position
	
	private var alignment: Alignment {
		position == .top ? .top : .bottom
	}
	
	private var filteredToasts: [any BoneToastType] {
		manager.toasts
			.filter { ($0.positionOverride ?? manager.defaultPosition) == position }
			.sorted(pinning: manager.pinning, stackOrder: manager.stackOrder, for: position)
	}
	
	/// Computes effective transition for a toast
	private func effectiveTransition(for toast: any BoneToastType) -> BoneToast.Transition {
		toast.animationConfig?.transition ?? manager.animationConfig.transition
	}
	
	/// Computes effective timing for a toast
	private func effectiveTiming(for toast: any BoneToastType) -> BoneToast.Timing {
		toast.animationConfig?.timing ?? manager.animationConfig.timing
	}
	
	func body(content: Content) -> some View {
		let toasts = filteredToasts
		content
			.overlay(alignment: alignment) {
				VStack(spacing: manager.toastSpacing) {
					ForEach(Array(toasts.enumerated()), id: \.element.id) { index, toast in
						let transition = effectiveTransition(for: toast)
						let timing = effectiveTiming(for: toast)
						AnyToastView(toast: toast, resolvedPosition: position, transition: transition, timing: timing) {
							manager.dismiss(id: toast.id)
						}
						.transition(transition.transition(for: position))
						// Higher zIndex for toasts closer to the edge ensures proper layering during animation
						.zIndex(Double(toasts.count - index))
					}
				}
				.padding(position == .top ? .top : .bottom)
			}
			.animation(manager.animationConfig.timing.animation, value: toasts.map(\.id))
	}
}

// MARK: - View Extensions

public extension View {
	/// Adds a scoped toast container that displays toasts from the manager.
	///
	/// Use this for toasts that should be scoped to a specific view hierarchy and
	/// should NOT appear above modals or sheets presented from that view.
	/// For most use cases, prefer `BoneToastManager` or `.globalToast()` instead.
	///
	/// - Parameter manager: The scoped toast manager (uses overlay presentation)
	func scopedToastContainer(manager: BoneToastManager) -> some View {
		self
			.modifier(BoneToastOverlayModifier(manager: manager, position: .top))
			.modifier(BoneToastOverlayModifier(manager: manager, position: .bottom))
	}
	
	/// Shows a global toast controlled by a binding.
	///
	/// This is the recommended way to show toasts in SwiftUI. The toast appears in a dedicated
	/// window above all content, and the binding is automatically set to false when the toast
	/// is dismissed (by auto-dismiss, user tap, swipe, or programmatic dismissal).
	///
	/// ```swift
	/// @State private var showSuccess = false
	///
	/// Button("Save") {
	///     save()
	///     showSuccess = true
	/// }
	/// .globalToast(isPresented: $showSuccess) {
	///     StandardToast.success("Saved!")
	/// }
	/// ```
	///
	/// - Parameters:
	///   - isPresented: Binding that controls toast visibility
	///   - content: Closure that creates the toast (called when isPresented becomes true)
	func globalToast<T: BoneToastType>(
		isPresented: Binding<Bool>,
		content: @escaping () -> T
	) -> some View {
		modifier(GlobalToastModifier(isPresented: isPresented, toast: content))
	}
}

// MARK: - Passthrough Window

/// A UIWindow that passes through touches to windows below when not hitting toast content
private class PassthroughWindow: UIWindow {
	/// Rects (in window coordinates) where touches should be handled.
	/// Touches outside these rects pass through to windows below.
	var interactiveRects: [CGRect] = []
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		// Check if point is within any interactive rect
		for rect in interactiveRects {
			if rect.contains(point) {
				return super.hitTest(point, with: event)
			}
		}
		// Pass through touches outside interactive areas
		return nil
	}
	
	func updateInteractiveRect(id: AnyHashable, rect: CGRect?) {
		// Simple implementation: just store the rect
		// For multiple toasts, we'd need a dictionary, but for now just use array
		if let rect = rect {
			if !interactiveRects.contains(rect) {
				interactiveRects.removeAll()
				interactiveRects.append(rect)
			}
		} else {
			interactiveRects.removeAll()
		}
	}
}

// MARK: - Toast Frame Preference

/// Preference key for reporting toast frames to the window
private struct ToastFramePreferenceKey: PreferenceKey {
	static let defaultValue: [UUID: CGRect] = [:]
	
	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue()) { $1 }
	}
}

