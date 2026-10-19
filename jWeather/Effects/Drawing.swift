import SwiftUI

func discPath(x: Double, y: Double, radius: Double) -> Path {
    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
}

extension GraphicsContext {
    func fillSoftEllipse(in rect: CGRect, color: Color, opacity: Double, steps: Int = 10) {
        for step in 0..<steps {
            let fraction = CGFloat(step) / CGFloat(steps)
            let shrunk = rect.insetBy(dx: rect.width * fraction / 2, dy: rect.height * fraction / 2)
            fill(Path(ellipseIn: shrunk), with: .color(color.opacity(opacity / Double(steps) * 1.6)))
        }
    }
}