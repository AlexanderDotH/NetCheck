import SwiftUI

struct SpeedGauge: View {
    @Environment(\.locale) private var locale
    let value: Double
    let maxValue: Double
    let label: String
    let icon: String
    let color: Color
    var isActive: Bool = false

    @State private var pulse1 = false
    @State private var pulse2 = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Anneaux pulsants visibles uniquement pendant le test
                if isActive {
                    Circle()
                        .stroke(color.opacity(pulse1 ? 0 : 0.35), lineWidth: 2)
                        .scaleEffect(pulse1 ? 1.45 : 1.05)
                        .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: pulse1)

                    Circle()
                        .stroke(color.opacity(pulse2 ? 0 : 0.2), lineWidth: 1.5)
                        .scaleEffect(pulse2 ? 1.7 : 1.1)
                        .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false).delay(0.55), value: pulse2)
                }

                // Fond de la jauge — plus lumineux pendant le test
                Circle()
                    .stroke(color.opacity(isActive ? 0.28 : 0.15), lineWidth: isActive ? 10 : 8)
                    .animation(.easeInOut(duration: 0.4), value: isActive)

                // Arc de progression
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: isActive ? 10 : 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: value)
                    .animation(.easeInOut(duration: 0.4), value: isActive)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(String(format: "%.0f", locale: locale, value))
                        .font(.title2.monospacedDigit().bold())
                    Text(verbatim: "Mb/s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .onChange(of: isActive) {
            if isActive {
                pulse1 = false; pulse2 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    pulse1 = true; pulse2 = true
                }
            } else {
                pulse1 = false; pulse2 = false
            }
        }
    }
}
