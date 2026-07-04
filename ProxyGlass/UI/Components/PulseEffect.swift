import SwiftUI

struct PulseEffect: ViewModifier {
    let isActive: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        TimelineView(.animation) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            let phase = (t.truncatingRemainder(dividingBy: 2.0)) / 2.0
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.3 * (1 - phase)))
                                .scaleEffect(1 + phase * 0.03)
                                .allowsHitTesting(false)
                        }
                    }
                }
            )
    }
}

extension View {
    func pulseAlert(isActive: Bool, color: Color = PGStatusColors.danger) -> some View {
        modifier(PulseEffect(isActive: isActive, color: color))
    }
}
