import SwiftUI

struct AtmosphereView: View {
    let scene: SkyScene
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AtmosphereBackdrop(scene: scene, accent: accent)
            AtmosphereSky(scene: scene)
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.25 : 1.0), value: scene)
        .animation(.easeInOut(duration: reduceMotion ? 0.25 : SkyTiming.dayNight), value: scene.isNight)
    }
}

enum SkyTiming {
    static let dayNight = 1.8
}

private struct AtmosphereBackdrop: View {
    let scene: SkyScene
    let accent: Color
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.panelBase.opacity(Theme.panelOpacity)
            LinearGradient(stops: [.init(color: palette.glassHighlight.opacity(0.14), location: 0),
                                   .init(color: Color.clear, location: 0.22)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(stops: [.init(color: Color(hex: 0x1a1d4d).opacity(0.42), location: 0),
                                   .init(color: Color(hex: 0x1a1d4d).opacity(0), location: 0.78)],
                           startPoint: .top, endPoint: .bottom)
                .opacity(scene.isNight ? 1 : 0)
            ForEach(WeatherCondition.allCases) { condition in
                let tint = SkyScene.tint(for: condition)
                LinearGradient(colors: [tint, tint.opacity(0)],
                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.7))
                    .opacity(scene.condition == condition ? scene.tintOpacity : 0)
            }
            LinearGradient(stops: [.init(color: accent.opacity(0.06), location: 0),
                                   .init(color: accent.opacity(0), location: 0.52)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct AtmosphereSky: View {
    let scene: SkyScene

    var body: some View {
        ZStack {
            FadeLayer(active: scene.sunStrength > 0, duration: SkyTiming.dayNight) {
                SunLayer().opacity(scene.sunStrength)
            }
            FadeLayer(active: scene.moonStrength > 0, duration: SkyTiming.dayNight) {
                MoonLayer().opacity(scene.moonStrength)
            }
            FadeLayer(active: scene.starsStrength > 0, duration: SkyTiming.dayNight) {
                StarsLayer().opacity(scene.starsStrength)
            }
            FadeLayer(active: scene.cloudCount > 0) {
                CloudsLayer(count: scene.cloudCount, shade: scene.cloudShade)
            }
            FadeLayer(active: scene.condition == .fog) {
                FogLayer()
            }
            ForEach(WeatherIntensity.allCases, id: \.self) { level in
                FadeLayer(active: scene.condition == .rain && scene.intensity == level) {
                    RainLayer(level: level)
                }
                FadeLayer(active: scene.condition == .snow && scene.intensity == level) {
                    SnowLayer(level: level)
                }
            }
            ForEach([WeatherIntensity.moderate, WeatherIntensity.heavy], id: \.self) { level in
                FadeLayer(active: scene.condition == .storm && scene.stormLevel == level) {
                    StormLayer(level: level)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct StormFlashOverlay: View {
    let scene: SkyScene

    var body: some View {
        ZStack {
            ForEach([WeatherIntensity.moderate, WeatherIntensity.heavy], id: \.self) { level in
                FadeLayer(active: scene.condition == .storm && scene.stormLevel == level) {
                    MotionTimeline(.fast) { time in
                        Color.white.opacity(0.22 * Lightning.level(at: time, level: level))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}