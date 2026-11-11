import SwiftUI

/// The lessons' pointing hand, tapping in place with a pulse ring, to show a new user where to start.
struct TapHint: View {
    @State private var down = false
    @State private var ring = false
    private let hand = "M-3 11V-11c0-4 6-4 6 0v11-5c0-4 6-4 6 0v7-4c0-4 6-4 6 0v7-2c0-4 6-4 6 1v8c0 11-7 18-18 18-9 0-14-4-18-11l-6-10c-2-4 3-8 6-4z"

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(Theme.blue.opacity(0.45), lineWidth: 3)
                .frame(width: 48, height: 48)
                .scaleEffect(ring ? 1.8 : 0.35)
                .opacity(ring ? 0 : 0.9)
                .offset(x: 9, y: -20)
            ZStack {
                SVGShape(d: hand, viewBox: CGRect(x: -30, y: -18, width: 60, height: 64)).fill(Color(hex: 0xfff7ee))
                SVGShape(d: hand, viewBox: CGRect(x: -30, y: -18, width: 60, height: 64))
                    .stroke(Color(hex: 0x23324b), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 66, height: 70)
            .shadow(color: Theme.shadow.opacity(0.18), radius: 5, x: 0, y: 6)
            .rotationEffect(.degrees(-14), anchor: UnitPoint(x: 0.5, y: 0.06))
            .scaleEffect(down ? 0.9 : 1, anchor: .top)
            .offset(y: down ? 4 : -6)
        }
        .frame(width: 66, height: 70, alignment: .topLeading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { down = true }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { ring = true }
        }
    }
}
