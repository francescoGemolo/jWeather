import Foundation

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return Double(z >> 11) / 9007199254740992.0
    }
}

func unitHash(_ n: Int, salt: UInt64 = 0) -> Double {
    var random = SeededRandom(seed: UInt64(truncatingIfNeeded: n) &* 0x2545F4914F6CDD1D &+ salt)
    return random.next()
}

func positiveMod(_ value: Double, _ modulus: Double) -> Double {
    let remainder = value.truncatingRemainder(dividingBy: modulus)
    return remainder < 0 ? remainder + modulus : remainder
}

func lerp(_ range: ClosedRange<Double>, _ t: Double) -> Double {
    range.lowerBound + (range.upperBound - range.lowerBound) * t
}

func wave(_ time: Double, period: Double, phase: Double = 0) -> Double {
    sin(2 * Double.pi * time / period + phase)
}