import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    static let panelRadius: CGFloat = 24
    static let panelWidth: CGFloat = 352
    static let panelOpacity: Double = 0.88

    static let low = Color(hex: 0x4a6cf7)
    static let high = Color(hex: 0xf2553d)
    static let sun = Color(hex: 0xffa51f)
    static let moon = Color(hex: 0xdfe6ff)
    static let bolt = Color(hex: 0xe4dcff)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}