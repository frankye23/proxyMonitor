import SwiftUI

struct RiskAlertsView: View {
    let alerts: [RiskAlert]

    var body: some View {
        VStack(spacing: 8) {
            if alerts.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(PGStatusColors.heroTeal)
                    Text("未发现风险连接")
                        .font(.system(size: 11))
                        .foregroundStyle(PGStatusColors.heroTeal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            } else {
                ForEach(alerts) { alert in
                    alertRow(alert)
                }
            }
        }
        .padding(.top, 4)
    }

    private func alertRow(_ alert: RiskAlert) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: alert.severity == .high ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .font(.system(size: 12))
                .foregroundStyle(alert.severity == .high ? PGStatusColors.heroRedOrange : PGStatusColors.heroAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PGStatusColors.textPrimary)

                Text(alert.description)
                    .font(.system(size: 10))
                    .foregroundStyle(PGStatusColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("建议：\(alert.suggestion)")
                    .font(.system(size: 10))
                    .foregroundStyle(PGStatusColors.info)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((alert.severity == .high ? PGStatusColors.heroRedOrange : PGStatusColors.heroAmber).opacity(0.08))
        )
    }
}
