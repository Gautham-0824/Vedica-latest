import SwiftUI

/// Reports the window size to `Layout` so every screen adapts live to rotation, iPhone, iPad and split view.
struct AdaptiveRoot<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .onGeometryChange(for: CGSize.self, of: { $0.size }) { Metrics.shared.update($0) }
    }
}

// MARK: - Shared controls

struct RoundIconButton: View {
    var d: String
    var size: CGFloat = 48
    var icon: CGFloat = 24
    var stroke: CGFloat = 2.4
    var fg: Color = Color(hex: 0x3a4860)
    var bg: Color = .white
    var border: Color = Theme.line
    var shadowOn = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Icon(d: d, size: icon, stroke: stroke, color: fg)
                .frame(width: pt(size), height: pt(size))
                .background(Circle().fill(bg))
                .overlay(Circle().stroke(border, lineWidth: 1))
                .shadow(color: Theme.shadow.opacity(shadowOn ? 0.05 : 0), radius: 6, x: 0, y: 4)
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle(scale: 0.92))
    }
}

struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.timingCurve(0.3, 0.7, 0.4, 1, duration: 0.14), value: configuration.isPressed)
    }
}

struct PrimaryPill: View {
    var title: String
    var minWidth: CGFloat = 0
    var height: CGFloat = 56
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.text(17, .bold))
                .foregroundColor(.white)
                .padding(.horizontal, pt(30))
                .frame(minWidth: pt(minWidth), minHeight: pt(height))
                .background(Capsule().fill(Theme.blue))
                .shadow(color: Theme.blue.opacity(0.3), radius: 12, x: 0, y: 10)
        }
        .buttonStyle(PressStyle())
    }
}

struct SecondaryPill: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.text(17, .semibold))
                .foregroundColor(Color(hex: 0x3a4860))
                .padding(.horizontal, pt(26))
                .frame(minHeight: pt(56))
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                .shadow(color: Theme.shadow.opacity(0.05), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(PressStyle())
    }
}

struct VedicaLogo: View {
    var size: CGFloat = 28
    var tall = false
    var shadowed = true
    var body: some View {
        let d = pt(size)
        Text("V")
            .font(Theme.round(size * 0.58, .heavy).italic())
            .foregroundColor(.white)
            .frame(width: d, height: d)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: d * 0.32, bottomLeadingRadius: d * 0.11,
                                       bottomTrailingRadius: d * 0.32, topTrailingRadius: d * 0.32,
                                       style: .continuous)
                    .fill(Theme.blue))
            .shadow(color: Theme.blue.opacity(shadowed ? 0.28 : 0), radius: 15, x: 0, y: 14)
            .accessibilityHidden(true)
    }
}

enum IconPath {
    static let close = "M6 6l12 12M18 6 6 18"
    static let back = "m14.5 6-6 6 6 6"
    static let forward = "m9.5 6 6 6-6 6"
    static let replay = "M4 12a8 8 0 1 0 2.3-5.7M4 5v5h5"
    static let restart = "M20 12a8 8 0 1 1-2.3-5.7M20 5v5h-5"
    static let speaker = "M4 9.5h3.2L12 5.5v13l-4.8-4H4z"
    static let wavesOn = "M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11"
    static let wavesOff = "m16 9.5 5 5m0-5-5 5"
    static let info = "M12 12v0"
    static let check = "m5 12.5 4.5 4.5L19 7.5"
}
