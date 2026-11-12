import SwiftUI

/// Height of `TabHeader` in design points on regular-width windows; the lesson map is placed relative to the full window.
private let headerH: CGFloat = 80

struct LessonsScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }
    private var layout: Metrics { Metrics.shared }
    /// Height of this screen (below the header, above the tab bar), in points.
    @State private var screenH: CGFloat = 0

    /// Where the 1024 x 768 map drawing sits, and how much it is shrunk, for the current window.
    private var placement: (x: CGFloat, y: CGFloat, scale: CGFloat) {
        let extraX = max(0, (layout.w - 1024) / 2), extraY = max(0, (layout.h - 768) / 2)
        if layout.compact {
            // Narrow windows: shrink the drawn part of the map (x 290...930, y 150...640) to the width.
            let m = min(1, (layout.w - 36) / 640)
            return (18 - 290 * m, 110 - 150 * m, m)
        }
        // The path is authored for landscape; portrait slides it onto the narrower page.
        if layout.portrait { return (-190, 130 + extraY / 2 - headerH, 1) }
        return (extraX, extraY - headerH, 1)
    }

    var body: some View {
        let p = placement
        VStack(alignment: .leading, spacing: pt(10)) {
            Text("Lessons").font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Start with the basics.").font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
        }
        .padding(.leading, pt(36))
        .padding(.top, pt(32))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // The map is a fixed drawing behind the title; as a background it never changes the screen's size.
        .background(alignment: .topLeading) {
            if layout.compact {
                compactMap
            } else {
                map
                    .scaleEffect(p.scale, anchor: .topLeading)
                    .at(p.x, p.y)
            }
        }
        .clipped()
        .screenBackground()
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { screenH = $0 }
    }

    /// Narrow windows (iPhone portrait): the same circles, labels and path, shrunk to the width and spread
    /// down the free height below the title, so nothing overlaps the title and the screen is not empty below.
    private var compactMap: some View {
        // The drawn part of the map is x 290...930, y 150...640 in map coordinates.
        let m = min(1, (layout.w - 36) / 640)
        let top: CGFloat = 175   // design points below the top of this screen; clears the title and subtitle
        let free = max(0, screenH / layout.k - top - 40)
        let sy = min(max(m, free / 490), m * 1.7)
        let X = { (x: CGFloat) in 18 + (x - 290) * m }
        let Y = { (y: CGFloat) in top + (y - 150) * sy }
        let P = { (x: CGFloat, y: CGFloat) in CGPoint(x: pt(X(x)), y: pt(Y(y))) }
        // Node centres in map coordinates match the path's end points.
        let spot = { (cx: CGFloat, cy: CGFloat, size: CGFloat) in (X(cx) - size / 2 * m, Y(cy) - size / 2 * m) }
        let b = spot(380, 575, 148), i = spot(660, 400, 116), a = spot(500, 215, 116)
        return ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: P(380, 575))
                p.addCurve(to: P(660, 400), control1: P(380, 470), control2: P(660, 510))
                p.addCurve(to: P(500, 215), control1: P(660, 300), control2: P(500, 320))
            }
            .stroke(Color(hex: 0xdfe7ef), style: StrokeStyle(lineWidth: pt(5 * m), lineCap: .round, dash: [0.1, pt(16 * m)]))
            .accessibilityHidden(true)

            node(.basics, "1", 148, 60, x: 0, y: 0, filled: true, labelX: 172, labelY: 47, title: "Basics", titleSize: 24, sub: nil)
                .scaleEffect(m, anchor: .topLeading).at(b.0, b.1)
            node(.inter, "2", 116, 48, x: 0, y: 0, filled: false, labelX: 138, labelY: 18, title: "Intermediate", titleSize: 22, sub: "Decimals and division")
                .scaleEffect(m, anchor: .topLeading).at(i.0, i.1)
            node(.adv, "3", 116, 48, x: 0, y: 0, filled: false, labelX: 138, labelY: 18, title: "Advanced", titleSize: 22, sub: "Algebra")
                .scaleEffect(m, anchor: .topLeading).at(a.0, a.1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var map: some View {
        ZStack(alignment: .topLeading) {
            SVGShape(d: "M380 575 C380 470 660 510 660 400 C660 300 500 320 500 215", viewBox: CGRect(x: 0, y: 0, width: 1024, height: 768))
                .stroke(Color(hex: 0xdfe7ef), style: StrokeStyle(lineWidth: pt(5), lineCap: .round, dash: [0.1, pt(16)]))
                .frame(width: pt(1024), height: pt(768))
                .accessibilityHidden(true)

            node(.basics, "1", 148, 60, x: 306, y: 501, filled: true, labelX: 478, labelY: 548, title: "Basics", titleSize: 24, sub: nil)
            node(.inter, "2", 116, 48, x: 602, y: 342, filled: false, labelX: 740, labelY: 360, title: "Intermediate", titleSize: 22, sub: "Decimals and division")
            node(.adv, "3", 116, 48, x: 442, y: 157, filled: false, labelX: 580, labelY: 175, title: "Advanced", titleSize: 22, sub: "Algebra")
        }
        .frame(width: pt(1024), height: pt(768), alignment: .topLeading)
    }

    private func node(_ t: Tier, _ n: String, _ size: CGFloat, _ font: CGFloat, x: CGFloat, y: CGFloat, filled: Bool,
                      labelX: CGFloat, labelY: CGFloat, title: String, titleSize: CGFloat, sub: String?) -> some View {
        let done = store.doneCount(t), total = Catalog.items(t).count
        let c = done == total ? Theme.green : Theme.blue
        return ZStack(alignment: .topLeading) {
            NavigationLink(value: t) {
                Text(n).font(Theme.round(font, .black)).foregroundColor(filled ? .white : c)
                    .frame(width: pt(size), height: pt(size))
                    .background(Circle().fill(filled ? c : .white))
                    .overlay(Circle().stroke(c, lineWidth: filled ? 0 : pt(3)))
                    .shadow(color: c.opacity(filled ? 0.35 : 0), radius: 20, x: 0, y: 18)
            }
            .buttonStyle(PressStyle())
            .at(x, y)
            .accessibilityHidden(true)

            NavigationLink(value: t) {
                VStack(alignment: .leading, spacing: pt(2)) {
                    Text(title).font(Theme.round(titleSize, .heavy)).foregroundColor(Theme.ink)
                    if let sub { Text(sub).font(Theme.text(15, .semibold)).foregroundColor(Theme.sub) }
                    Text("\(done) of \(total) done").font(Theme.text(15, .semibold)).foregroundColor(c)
                }
                .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            .at(labelX, labelY)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(n). \(title), \(done) of \(total) done")
        }
    }
}

struct StatusDot: View {
    let status: Status
    var body: some View {
        Group {
            switch status {
            case .done:
                Icon(d: IconPath.check, size: 16, stroke: 3, color: .white)
                    .frame(width: pt(24), height: pt(24)).background(Circle().fill(Theme.green))
            case .progress:
                ZStack {
                    Circle().stroke(Theme.blue, lineWidth: pt(2.5))
                    Circle().trim(from: 0, to: 0.5).fill(Theme.blue).rotationEffect(.degrees(90)).padding(pt(4))
                }
                .frame(width: pt(24), height: pt(24))
            case .new:
                Circle().stroke(Color(hex: 0xdfe7ef), lineWidth: pt(2.5)).frame(width: pt(24), height: pt(24))
            }
        }
        .accessibilityHidden(true)
    }
}

private func statusText(_ s: Status) -> String { s == .done ? "Done" : s == .progress ? "In progress" : "Not started" }

struct TierScreen: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.dismiss) private var dismiss
    let tier: Tier
    private var layout: Metrics { Metrics.shared }
    private var items: [Catalog.Item] { Catalog.items(tier) }
    private var title: String { tier == .basics ? "Basics" : tier == .inter ? "Intermediate" : "Advanced" }
    private var focus: String? { items.first { nav.store.status($0.id) != .done }?.id }
    private var columns: Int {
        if layout.compact { return 2 }
        if layout.portrait { return items.count > 6 ? 3 : 2 }
        return items.count > 6 ? 4 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: pt(12)) {
                Text(title).font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("\(items.count) sutras \u{00B7} \(nav.store.doneCount(tier)) done").font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
            }
            .padding(.leading, pt(36))
            .padding(.top, pt(32))
            .frame(height: pt(134), alignment: .topLeading)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: pt(16)), count: columns), spacing: pt(16)) {
                    ForEach(items) { card($0) }
                }
                .padding(EdgeInsets(top: pt(4), leading: pt(36), bottom: pt(124), trailing: pt(36)))
            }
        }
        .overlay(alignment: .bottomLeading) {
            RoundIconButton(d: IconPath.back, size: 56, icon: 26) { dismiss() }
                .accessibilityLabel("Back to lessons")
                .padding(.leading, pt(36))
                .padding(.bottom, pt(30))
        }
        .screenBackground()
    }

    private func card(_ it: Catalog.Item) -> some View {
        let st = nav.store.status(it.id), on = it.id == focus
        return Button { nav.tapCard(it.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(it.glyph)
                    .font(Theme.round(28, .heavy)).tracking(pt(-0.8)).foregroundColor(Color(hex: 0x3a4860))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, pt(10))
                    .frame(maxWidth: .infinity).frame(height: pt(92))
                    .background(RoundedRectangle(cornerRadius: pt(20), style: .continuous).fill(Theme.panel))
                    .accessibilityHidden(true)
                Text(it.name).font(Theme.round(22, .heavy)).foregroundColor(Theme.ink)
                    .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.8)
                    .padding(.top, pt(14))
                Spacer(minLength: 0)
                HStack(spacing: pt(10)) {
                    StatusDot(status: st)
                    Text(statusText(st)).font(Theme.text(15, .semibold)).foregroundColor(st == .done ? Theme.green : st == .progress ? Theme.blue : Theme.muted)
                }
            }
            .padding(pt(16))
            .frame(maxWidth: .infinity).frame(height: pt(214))
            .background(RoundedRectangle(cornerRadius: pt(28), style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: pt(28), style: .continuous)
                .stroke(on ? Theme.blue : Color(hex: 0xedf1f5), lineWidth: on ? 2 : 1))
            .shadow(color: Theme.blue.opacity(on ? 0.16 : 0), radius: 17, x: 0, y: 14)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(PressStyle(scale: 0.98))
    }
}

/// "Choose a module" for the x11 and x9 families, as a native sheet sized to its content.
struct ModuleSheet: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.dismiss) private var dismiss
    let family: String
    @State private var height: CGFloat = 400
    private var title: String { Catalog.basics.first { $0.id == family }?.name ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CHOOSE A MODULE").font(Theme.text(13, .bold)).foregroundColor(Theme.blue)
            Text(title).font(Theme.round(30, .black)).foregroundColor(Theme.ink).padding(.top, pt(6))
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: pt(10)) {
                ForEach(Catalog.subs[family] ?? []) { row($0) }
            }
            .padding(.top, pt(20))
        }
        .padding(EdgeInsets(top: pt(30), leading: pt(28), bottom: pt(28), trailing: pt(28)))
        .frame(width: Metrics.shared.compact ? nil : pt(520), alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            RoundIconButton(d: IconPath.close, size: 40, icon: 20, bg: Color(hex: 0xf1f4f8), border: .clear, shadowOn: false) { dismiss() }
                .accessibilityLabel("Close")
                .padding(pt(18))
        }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height = $0 }
        .presentationDetents([.height(height)])
        .presentationSizing(.fitted)
        .presentationCornerRadius(pt(32))
        .presentationBackground(.white)
        .presentationDragIndicator(.hidden)
    }

    private func row(_ s: Catalog.Sub) -> some View {
        let st = nav.store.status(s.id)
        return Button { nav.openLesson(s.id) } label: {
            HStack(spacing: pt(14)) {
                Text(s.glyph).font(Theme.round(20, .black)).foregroundColor(Theme.blue)
                    .frame(width: pt(80), height: pt(56))
                    .background(RoundedRectangle(cornerRadius: pt(16), style: .continuous).fill(Theme.soft))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: pt(2)) {
                    Text(s.name).font(Theme.round(20, .heavy)).foregroundColor(Theme.ink)
                    Text(s.example).font(Theme.text(15, .medium)).foregroundColor(Theme.sub)
                }
                Spacer(minLength: 0)
                StatusDot(status: st)
                Icon(d: IconPath.forward, size: 22, stroke: 2.4, color: Theme.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, pt(16)).padding(.vertical, pt(14))
            .background(RoundedRectangle(cornerRadius: pt(22), style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: pt(22), style: .continuous).stroke(Color(hex: 0xe6ecf2), lineWidth: 1))
            .accessibilityElement(children: .combine)
            .accessibilityValue(statusText(st))
        }
        .buttonStyle(PressStyle(scale: 0.98))
    }
}
