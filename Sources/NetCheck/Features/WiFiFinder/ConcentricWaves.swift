import SwiftUI

struct ConcentricWaves: View {
    let color: Color
    let duration: Double
    let strength: Double   // 0.0 (faible) → 1.0 (fort)
    @State private var animate = false

    // Propriétés visuelles interpolées selon la force du signal
    private var waveCount: Int    { 3 + Int(strength * 4) }           // 3 → 7
    private var lineWidth: Double { 0.8 + strength * 2.2 }            // 0.8px → 3px
    private var startOpacity: Double { 0.2 + strength * 0.55 }        // 0.20 → 0.75
    private var maxScale: Double { 0.55 + strength * 0.45 }           // 0.55 → 1.0 (du cadre)
    private static let size: CGFloat = 220

    var body: some View {
        ZStack {
            ForEach(0..<waveCount, id: \.self) { i in
                let t = waveCount > 1 ? Double(i) / Double(waveCount - 1) : 0
                // Les ondes restent dans leur cadre : jamais par-dessus le titre ou les panneaux
                let targetScale = 0.35 + t * (maxScale - 0.35)
                let opacity = startOpacity * (1.0 - t * 0.8)

                Circle()
                    .stroke(color.opacity(animate ? 0 : opacity), lineWidth: lineWidth)
                    .scaleEffect(animate ? targetScale : 0.12)
                    .animation(
                        .easeOut(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * duration / Double(waveCount)),
                        value: animate
                    )
            }
        }
        .frame(width: Self.size, height: Self.size)
        .onAppear { animate = true }
        .onChange(of: duration) { restart() }
        .onChange(of: waveCount) { restart() }
    }

    private func restart() {
        animate = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animate = true }
    }
}
