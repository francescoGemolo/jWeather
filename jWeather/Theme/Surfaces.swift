import SwiftUI

private struct ChipBackground<S: Shape>: ViewModifier {
    let shape: S
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content.background(shape.fill(palette.chipFill))
    }
}

private struct GlassChip<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(palette.glassTint)
                shape.strokeBorder(LinearGradient(colors: [palette.glassHighlight, Color.clear],
                                                  startPoint: .top, endPoint: .center), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
        }
    }
}

extension View {
    func chipBackground<S: Shape>(_ shape: S) -> some View {
        modifier(ChipBackground(shape: shape))
    }

    func glassChip<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassChip(shape: shape))
    }
}