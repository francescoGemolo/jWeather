import SwiftUI

struct Tone {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ hex: UInt32, alpha: Double = 1) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }

    func mixed(with other: Tone, _ t: Double) -> Tone {
        Tone(red: red + (other.red - red) * t,
             green: green + (other.green - green) * t,
             blue: blue + (other.blue - blue) * t,
             alpha: alpha + (other.alpha - alpha) * t)
    }

    func darkened(_ amount: Double) -> Tone {
        let keep = 1 - min(max(amount, 0), 1)
        return Tone(red: red * keep, green: green * keep, blue: blue * keep, alpha: alpha)
    }
}

struct Palette {
    let darkness: Double
    let foreground: Color
    let mute: Color
    let line: Color
    let panelBase: Color
    let glassTint: Color
    let glassHighlight: Color
    let chipFill: Color
    let sheet: Color
    let fog: Color
    let cloudHigh: Tone
    let cloudLow: Tone

    init(darkness t: Double) {
        func pick(_ light: Tone, _ dark: Tone) -> Tone { light.mixed(with: dark, t) }
        darkness = t
        foreground = pick(Tone(0x1d1d1f), Tone(0xf5f5f7)).color
        mute = pick(Tone(0x8e8e93), Tone(0xa2a2aa)).color
        line = pick(Tone(0x000000, alpha: 0.08), Tone(0xffffff, alpha: 0.10)).color
        panelBase = pick(Tone(0xfbfbfd), Tone(0x1c1c1f)).color
        glassTint = pick(Tone(0xffffff, alpha: 0.38), Tone(0xffffff, alpha: 0.07)).color
        glassHighlight = pick(Tone(0xffffff, alpha: 0.95), Tone(0xffffff, alpha: 0.22)).color
        chipFill = pick(Tone(0x000000, alpha: 0.05), Tone(0xffffff, alpha: 0.09)).color
        sheet = pick(Tone(0xffffff), Tone(0x1c1c20)).color
        fog = pick(Tone(0x8d99ad), Tone(0xd5dcec)).color
        cloudHigh = pick(Tone(0xffffff), Tone(0x3b3c46))
        cloudLow = pick(Tone(0xdde2ec), Tone(0x25262d))
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(darkness: 0)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

struct NightPalette: ViewModifier, Animatable {
    var night: Double
    let systemIsDark: Bool

    var animatableData: Double {
        get { night }
        set { night = newValue }
    }

    func body(content: Content) -> some View {
        let darkness = systemIsDark ? 1 : night
        content
            .environment(\.palette, Palette(darkness: darkness))
            .environment(\.colorScheme, darkness > 0.5 ? .dark : .light)
    }
}