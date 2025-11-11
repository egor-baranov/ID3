import SwiftUI
import AppKit

enum EditorTheme: Equatable {
    case light
    case dark

    init(colorScheme: ColorScheme) {
        self = colorScheme == .dark ? .dark : .light
    }

    var backgroundColor: Color {
        switch self {
        case .light:
            return Color.white.opacity(0.9)
        case .dark:
            return Color.black.opacity(0.35)
        }
    }

    var containerBackground: Color {
        switch self {
        case .light:
            return Color.white.opacity(0.85)
        case .dark:
            return Color.white.opacity(0.08)
        }
    }

    var borderColor: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.white.opacity(0.12)
        }
    }

    var primaryText: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.85)
        case .dark:
            return Color.white
        }
    }

    var secondaryText: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.6)
        case .dark:
            return Color.white.opacity(0.7)
        }
    }

    var accentButtonTint: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.08)
        case .dark:
            return Color.white.opacity(0.18)
        }
    }

    var nsBackgroundColor: NSColor {
        switch self {
        case .light:
            return NSColor(calibratedWhite: 0.98, alpha: 1.0)
        case .dark:
            return NSColor(calibratedWhite: 0.1, alpha: 0.95)
        }
    }

    var nsPrimaryTextColor: NSColor {
        switch self {
        case .light:
            return NSColor.textColor
        case .dark:
            return NSColor(calibratedWhite: 0.95, alpha: 1.0)
        }
    }

    var keywordColor: NSColor {
        switch self {
        case .light:
            return NSColor.systemBlue
        case .dark:
            return NSColor(calibratedRed: 0.33, green: 0.74, blue: 1.0, alpha: 1.0)
        }
    }

    var stringColor: NSColor {
        switch self {
        case .light:
            return NSColor.systemPink
        case .dark:
            return NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.8, alpha: 1.0)
        }
    }

    var commentColor: NSColor {
        switch self {
        case .light:
            return NSColor(calibratedWhite: 0.45, alpha: 1.0)
        case .dark:
            return NSColor(calibratedWhite: 0.65, alpha: 1.0)
        }
    }

    var numberColor: NSColor {
        NSColor.systemPurple
    }
}
