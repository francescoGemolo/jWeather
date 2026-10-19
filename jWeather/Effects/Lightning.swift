import Foundation

enum Lightning {
    struct Strike {
        let age: Double
        let seed: Int
        let level: Double
    }

    static func slotLength(for level: WeatherIntensity) -> Double {
        level == .heavy ? 3.4 : 6.0
    }

    static func current(at time: Double, level: WeatherIntensity) -> Strike? {
        let length = slotLength(for: level)
        let slot = Int(floor(time / length))
        guard unitHash(slot, salt: 11) < 0.85 else { return nil }
        let start = Double(slot) * length + 0.4 + unitHash(slot, salt: 23) * (length - 1.0)
        let age = time - start
        guard age >= 0, age < 0.6 else { return nil }
        var intensity = pulse(age, start: 0, duration: 0.12) + 0.6 * pulse(age, start: 0.16, duration: 0.10)
        if unitHash(slot, salt: 37) > 0.5 {
            intensity += 0.8 * pulse(age, start: 0.30, duration: 0.16)
        }
        return Strike(age: age, seed: slot, level: min(intensity, 1))
    }

    static func level(at time: Double, level: WeatherIntensity) -> Double {
        current(at: time, level: level)?.level ?? 0
    }

    private static func pulse(_ age: Double, start: Double, duration: Double) -> Double {
        let x = (age - start) / duration
        guard x >= 0, x < 1 else { return 0 }
        return x < 0.25 ? x / 0.25 : pow(1 - (x - 0.25) / 0.75, 2)
    }
}