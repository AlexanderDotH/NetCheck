import SwiftUI

/// Window backdrop for the feature panels.
///
/// The tinted background extends under the transparent title bar, but the content
/// stays inside the safe area so it never collides with the window buttons or the
/// title-bar drag region.
public struct FeatureWindowBackground<Content: View>: View {
    let tintColor: Color
    let content: Content

    public init(tintColor: Color = .blue, @ViewBuilder content: () -> Content) {
        self.tintColor = tintColor
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                ZStack {
                    Rectangle().fill(.background)
                    LinearGradient(
                        colors: [tintColor.opacity(0.16), tintColor.opacity(0.04), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: tintColor)
            }
    }
}
