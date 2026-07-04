import SwiftUI

struct LatencySparkline: View {
    let samples: [LatencySample]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard samples.count >= 2 else { return }

            let maxVal = samples.map(\.milliseconds).max() ?? 1
            let minVal = samples.map(\.milliseconds).min() ?? 0
            let range = max(maxVal - minVal, 1)
            let step = size.width / CGFloat(samples.count - 1)

            var path = Path()
            for (i, sample) in samples.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - CGFloat((sample.milliseconds - minVal) / range) * (size.height * 0.85) - size.height * 0.075
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Gradient fill
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()

            let gradient = Gradient(colors: [color.opacity(0.15), color.opacity(0)])
            context.fill(fillPath, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            // Stroke
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
