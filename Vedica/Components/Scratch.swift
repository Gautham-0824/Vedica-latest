import SwiftUI

enum PadMode { case pen, scroll }

/// The scratch pad panel with its toolbar, lined page and "More space below" pill.
struct ScratchPanel: View {
    @Binding var mode: PadMode
    let session: WorkSession

    var body: some View {
        @Bindable var z = session
        VStack(spacing: 0) {
            HStack(spacing: pt(8)) {
                Text("Scratch pad").font(Theme.text(16, .bold)).foregroundColor(Theme.body)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                tool("pencil.tip", "Pen", on: mode == .pen) { mode = .pen }
                tool("hand.draw", "Scroll", on: mode == .scroll) { mode = .scroll }
                tool("arrow.uturn.backward", "Undo", on: false) { if !z.padStrokes.isEmpty { z.padStrokes.removeLast() } }
                tool("eraser", "Clear", on: false) { z.padStrokes = [] }
            }
            .padding(.horizontal, pt(16)).frame(height: pt(56))
            Rectangle().fill(Theme.line).frame(height: 1)
            ZStack {
                ScratchPad(strokes: $z.padStrokes, mode: mode)
                if z.padStrokes.isEmpty {
                    VStack(spacing: pt(4)) {
                        Text("Work it out here").font(Theme.round(20, .heavy)).foregroundColor(Theme.ghost)
                        Text("Apple Pencil or a finger").font(Theme.text(15, .medium)).foregroundColor(Theme.ghost)
                    }
                    .allowsHitTesting(false)
                }
                Text("More space below").font(Theme.text(13, .semibold)).foregroundColor(Theme.sub)
                    .padding(.horizontal, pt(12)).frame(height: pt(28))
                    .background(Capsule().fill(.white))
                    .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, pt(12))
                    .allowsHitTesting(false)
                    .opacity(mode == .pen ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: pt(28), style: .continuous).fill(.white))
        .clipShape(RoundedRectangle(cornerRadius: pt(28), style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: pt(28), style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    private func tool(_ s: String, _ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: s).font(.system(size: pt(16), weight: .semibold))
                .foregroundColor(on ? Theme.blue : Theme.sub)
                .frame(width: pt(38), height: pt(38))
                .background(RoundedRectangle(cornerRadius: pt(12), style: .continuous).fill(on ? Theme.soft : Theme.panel))
        }
        .buttonStyle(PressStyle(scale: 0.92))
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

struct ScratchPad: View {
    @Binding var strokes: [[CGPoint]]
    var mode: PadMode
    @State private var current: [CGPoint] = []

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            SwiftUI.Canvas { ctx, size in
                var y: CGFloat = 50
                while y < size.height {
                    var l = Path()
                    l.move(to: CGPoint(x: 0, y: y))
                    l.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(l, with: .color(Color(hex: 0xeef2f6)), lineWidth: 1)
                    y += 52
                }
                for s in strokes + (current.isEmpty ? [] : [current]) { draw(&ctx, s) }
            }
            .frame(height: 1152)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in current.append(v.location) }
                .onEnded { _ in
                    if !current.isEmpty { strokes.append(current) }
                    current = []
                }, including: mode == .pen ? .all : .none)
        }
        .scrollDisabled(mode == .pen)
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: [CGPoint]) {
        guard let f = s.first else { return }
        var p = Path()
        p.move(to: f)
        if s.count == 1 { p.addLine(to: CGPoint(x: f.x + 0.1, y: f.y)) }
        for pt in s.dropFirst() { p.addLine(to: pt) }
        ctx.stroke(p, with: .color(Color(hex: 0x23324b)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
    }
}

/// Transparent writing layer over an answer box. Pauses for 650 ms, then recognises the digits.
struct InkBox: View {
    var enabled: Bool
    var onTouch: () -> Void
    var onDigits: (String) -> Void
    @State private var strokes: [[CGPoint]] = []
    @State private var current: [CGPoint] = []
    @State private var commit: Task<Void, Never>?

    var body: some View {
        SwiftUI.Canvas { ctx, _ in
            for s in strokes + (current.isEmpty ? [] : [current]) {
                guard let f = s.first else { continue }
                var p = Path(); p.move(to: f)
                for pt in s.dropFirst() { p.addLine(to: pt) }
                ctx.stroke(p, with: .color(Color(hex: 0x23324b)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .padding(-14)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard enabled else { return }
                if current.isEmpty { onTouch(); commit?.cancel() }
                current.append(v.location)
            }
            .onEnded { _ in
                guard enabled else { current = []; return }
                if current.count >= 3 { strokes.append(current) }
                current = []
                guard !strokes.isEmpty else { return }
                commit?.cancel()
                commit = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 650_000_000)
                    if Task.isCancelled { return }
                    let s = InkRecognizer.recognize(strokes)
                    strokes = []
                    if !s.isEmpty { onDigits(s) }
                }
            })
    }
}
