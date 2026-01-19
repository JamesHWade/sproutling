//
//  AdaptiveColors.swift
//  Sproutling
//
//  Adaptive color system for dark mode support
//

import SwiftUI
import UIKit

// MARK: - Adaptive Colors Extension

extension Color {

    // MARK: - Card & Surface Colors

    /// Primary card background - white in light mode, dark gray in dark mode
    static var cardBackground: Color {
        Color(UIColor.systemBackground)
    }

    /// Secondary card background - slightly off-white/gray
    static var cardBackgroundSecondary: Color {
        Color(UIColor.secondarySystemBackground)
    }

    /// Tertiary background for nested elements
    static var cardBackgroundTertiary: Color {
        Color(UIColor.tertiarySystemBackground)
    }

    // MARK: - Text Colors

    /// Primary text - adapts to light/dark mode
    static var textPrimary: Color {
        Color(UIColor.label)
    }

    /// Secondary text - lighter/dimmer
    static var textSecondary: Color {
        Color(UIColor.secondaryLabel)
    }

    /// Tertiary text - even lighter
    static var textTertiary: Color {
        Color(UIColor.tertiaryLabel)
    }

    // MARK: - Border & Separator Colors

    /// Subtle border color
    static var borderSubtle: Color {
        Color(UIColor.separator)
    }

    /// Opaque separator
    static var separatorOpaque: Color {
        Color(UIColor.opaqueSeparator)
    }
}

// MARK: - Adaptive Shape Styles

extension ShapeStyle where Self == Color {

    /// Adaptive card fill - use instead of .white for card backgrounds
    static var adaptiveCardFill: Color {
        Color(UIColor.systemBackground)
    }

    /// Adaptive secondary fill
    static var adaptiveSecondaryFill: Color {
        Color(UIColor.secondarySystemBackground)
    }
}

// MARK: - Shadow Modifier for Dark Mode

extension View {
    /// Adaptive shadow that works in both light and dark mode
    /// In dark mode, shadows are subtler or use a glow effect
    func adaptiveShadow(
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.modifier(AdaptiveShadowModifier(radius: radius, x: x, y: y))
    }

    /// Card style with adaptive background and shadow
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .adaptiveShadow()
    }
}

struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            // In dark mode, use a subtle lighter shadow/glow
            content.shadow(color: .white.opacity(0.05), radius: radius, x: x, y: y)
        } else {
            // In light mode, use traditional dark shadow
            content.shadow(color: .black.opacity(0.1), radius: radius, x: x, y: y)
        }
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Creates an adaptive gradient that works in dark mode
    static func adaptive(
        lightColors: [Color],
        darkColors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        AdaptiveGradient(
            lightColors: lightColors,
            darkColors: darkColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

struct AdaptiveGradient: View {
    @Environment(\.colorScheme) var colorScheme

    let lightColors: [Color]
    let darkColors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkColors : lightColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
