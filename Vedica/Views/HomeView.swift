import SwiftUI

struct HomeScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }
    private var layout: Metrics { Metrics.shared }
    private let tile = Color(hex: 0xf2f2f7)
    /// Extra height on tall screens goes to the hero card and stats.
    private var extra: CGFloat { layout.compact ? 0 : max(0, layout.h - 768) }
    private var heroH: CGFloat { 256 + extra * (layout.portrait ? 0.3 : 0.5) }
    private var statH: CGFloat { 132 + extra * (layout.portrait ? 0.15 : 0.3) }
    /// The glyph tile beside the hero text; smaller when the window is narrow.
    private var tileSize: CGFloat { layout.compact ? 110 : 200 }

    private var hero: Catalog.Item? { Catalog.basics.first { store.status($0.id) != .done } }
    private var heroIndex: Int { hero.flatMap { h in Catalog.basics.firstIndex { $0.id == h.id } } ?? 0 }
    private var heroFrac: Double { hero.map { store.progress($0.id) } ?? 1 }
    private var heroStarted: Bool { hero.map { store.status($0.id) == .progress } ?? false }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let g = h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
        return store.trimmedName.isEmpty ? g : "\(g), \(store.trimmedName)"
    }
    private var subline: String {
        if store.streak > 1 { return "You\u{2019}re on a \(store.streak)-day streak. Keep it going!" }
        if store.minutesToday > 0 { return "\(store.minutesToday) min of practice today. Nice work." }
        return store.basicsDone > 0 ? "Ready to pick up where you left off?" : "Let\u{2019}s learn your first sutra today."
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(greeting).font(Theme.round(42, .black)).foregroundColor(Theme.ink)
                        .lineLimit(2).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    Text(subline).font(Theme.text(18, .medium)).foregroundColor(Theme.sub)
                }
                .frame(minHeight: pt(96), alignment: .topLeading)

                heroCard

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: pt(16)), count: layout.wide ? 4 : 2), spacing: pt(16)) {
                    goalCard
                    stat(value: "\(store.streak)", unit: store.streak == 1 ? "day" : "days",
                         icon: "M12 3c1 3.2 5 5.4 5 10a5 5 0 0 1-10 0c0-2.2 1-3.6 2.2-4.8.3 1.6 1 2.6 2 3 0-3 .3-5.6.8-8.2z",
                         label: store.streak == 1 ? "Day streak" : "Days in a row")
                    stat(value: store.speed.map { "\($0)" } ?? "\u{2014}", unit: store.speed == nil ? "" : "q / min",
                         icon: "M13 3 5 13.5h6L10 21l8-10.5h-6z", label: store.speed == nil ? "Take a quiz to see it" : "Quiz speed")
                    stat(value: "\(store.basicsDone)", unit: "of \(store.basicsTotal)",
                         icon: "M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z", label: "Sutras completed")
                }
                .padding(.top, pt(20))
            }
            .padding(.horizontal, pt(36))
            .padding(.top, pt(20))
            .padding(.bottom, pt(30))
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground()
    }

    private var heroCard: some View {
        HStack(spacing: pt(layout.compact ? 16 : 28)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: pt(10)) {
                    Text("Continue learning").font(Theme.text(14, .bold)).foregroundColor(Theme.blue)
                    Text(hero == nil ? "Done" : heroStarted ? "In progress" : "New")
                        .font(Theme.text(12, .semibold)).foregroundColor(Color(hex: 0x636366))
                        .padding(.horizontal, pt(10)).frame(height: pt(22))
                        .background(Capsule().fill(tile))
                }
                Text(hero?.name ?? "Every Basics sutra done")
                    .font(Theme.round(32, .black)).foregroundColor(Theme.ink)
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .padding(.top, pt(10))
                Text(hero == nil ? "All \(store.basicsTotal) sutras done \u{00B7} Basics" : "Sutra \(heroIndex + 1) of \(store.basicsTotal) \u{00B7} Basics")
                    .font(Theme.text(16, .medium)).foregroundColor(Theme.muted)
                    .padding(.top, pt(6))
                Spacer(minLength: pt(12))
                HStack(spacing: pt(12)) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xeef2f6))
                            Capsule().fill(Theme.blue).frame(width: g.size.width * heroFrac)
                        }
                    }
                    .frame(maxWidth: pt(420), maxHeight: pt(8))
                    .accessibilityHidden(true)
                    Text("\(Int((heroFrac * 100).rounded()))%").font(Theme.text(14, .bold)).foregroundColor(Theme.sub)
                        .accessibilityLabel("\(Int((heroFrac * 100).rounded())) percent done")
                }
                Button { nav.nextLessonTapped() } label: {
                    HStack(spacing: pt(6)) {
                        Text(hero == nil ? "Review lessons" : heroStarted ? "Continue" : "Start").font(Theme.text(17, .bold))
                        Icon(d: IconPath.forward, size: 20, stroke: 2.6, color: .white)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, pt(26)).frame(height: pt(52))
                    .background(Capsule().fill(Theme.blue))
                }
                .buttonStyle(PressStyle())
                // First visit: a finger shows where to tap, until the first lesson is opened.
                .overlay(alignment: .bottomTrailing) {
                    if store.s.showTapHint { TapHint().offset(x: pt(-24), y: pt(40)).allowsHitTesting(false) }
                }
                .padding(.top, pt(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(hero?.glyph ?? "\u{2713}")
                .font(Theme.round(layout.compact ? 26 : 38, .black)).foregroundColor(Color(hex: 0x1c1c1e))
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, pt(14))
                .frame(width: pt(tileSize), height: pt(tileSize))
                .background(RoundedRectangle(cornerRadius: pt(layout.compact ? 24 : 32), style: .continuous).fill(tile))
                .accessibilityHidden(true)
        }
        .padding(EdgeInsets(top: pt(28), leading: pt(layout.compact ? 22 : 32), bottom: pt(28), trailing: pt(layout.compact ? 20 : 28)))
        .frame(maxWidth: .infinity)
        .frame(height: pt(heroH))
        .background(RoundedRectangle(cornerRadius: pt(24), style: .continuous).fill(.white))
        .cardShadow()
    }

    private var goalCard: some View {
        let goal = store.s.session, m = store.minutesToday
        return HStack(spacing: pt(14)) {
            ZStack {
                Circle().stroke(Color(hex: 0xeef2f6), lineWidth: pt(6))
                Circle().trim(from: 0, to: min(Double(m) / Double(goal), 1))
                    .stroke(Theme.blue, style: StrokeStyle(lineWidth: pt(6), lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: pt(50), height: pt(50))
            .frame(width: pt(60), height: pt(60))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: pt(2)) {
                Text("\(m) of \(goal) min").font(Theme.round(20, .black)).foregroundColor(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("Daily goal").font(Theme.text(13, .medium)).foregroundColor(Theme.sub)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .statCard(statH)
    }

    private func stat(value: String, unit: String, icon: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Icon(d: icon, size: 20, stroke: 2, color: Color(hex: 0x636366))
                .frame(width: pt(34), height: pt(34))
                .background(RoundedRectangle(cornerRadius: pt(10), style: .continuous).fill(tile))
                .accessibilityHidden(true)
            Spacer(minLength: pt(8))
            HStack(alignment: .firstTextBaseline, spacing: pt(4)) {
                Text(value).font(Theme.round(30, .black)).foregroundColor(Theme.ink)
                Text(unit).font(Theme.text(14, .semibold)).foregroundColor(Theme.sub)
            }
            Text(label).font(Theme.text(13, .medium)).foregroundColor(Theme.sub).lineLimit(1).minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
        .statCard(statH)
    }
}

private extension View {
    func statCard(_ h: CGFloat) -> some View {
        padding(.horizontal, pt(20)).padding(.vertical, pt(18))
            .frame(maxWidth: .infinity, minHeight: pt(h), maxHeight: pt(h), alignment: .leading)
            .background(RoundedRectangle(cornerRadius: pt(24), style: .continuous).fill(.white))
            .cardShadow()
    }
}
