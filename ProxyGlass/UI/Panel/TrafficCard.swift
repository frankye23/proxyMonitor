import SwiftUI

struct TrafficCard: View {
    var body: some View {
        GlassCard {
            VStack(spacing: 6) {
                HStack {
                    Label("流量统计", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PGStatusColors.textSecondary)
                    Spacer()
                }

                Text("流量统计即将推出")
                    .font(.system(size: 12))
                    .foregroundStyle(PGStatusColors.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .opacity(0.6)
        }
    }
}
