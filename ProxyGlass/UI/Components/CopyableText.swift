import SwiftUI

struct CopyableText: View {
    let text: String
    @State private var copied = false

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(PGStatusColors.textPrimary)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(PGStatusColors.info)
            }
            .buttonStyle(.plain)
            .contentTransition(.symbolEffect(.replace))
            .accessibilityLabel(copied ? "已复制" : "复制")
            .accessibilityAddTraits(.isButton)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(text)
    }
}
