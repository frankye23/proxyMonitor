import SwiftUI

struct SkeletonView: View {
    var width: CGFloat = .infinity
    var height: CGFloat = 14

    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(PGStatusColors.textSecondary.opacity(colorScheme == .dark ? 0.25 : 0.15))
            .frame(width: width == .infinity ? nil : width, height: height)
            .frame(maxWidth: width == .infinity ? .infinity : nil, alignment: .leading)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(colorScheme == .dark ? 0.4 : 0.3), location: 0.5),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: shimmerOffset * (geo.size.width + geo.size.width * 0.6))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
                }
                .mask(RoundedRectangle(cornerRadius: 4))
            )
            .onAppear {
                shimmerOffset = 1
            }
    }
}

struct SkeletonCard: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 120)
                SkeletonView(width: 200, height: 12)
                SkeletonView(width: 160, height: 12)
            }
        }
    }
}
