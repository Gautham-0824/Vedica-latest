import SwiftUI

struct HomeScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }
    private let tile = Color(hex: 0xf2f2f7)
    /// Extra height on tall screens goes to the hero card and stats.
    private var extra: CGFloat { max(0, Canvas.h - 768) }
    private var heroH: CGFloat { 256 + extra * (Canvas.portrait ? 0.3 : 0.5) }
    private var statH: CGFloat { 132 + extra * (Canvas.portrait ? 0.15 : 0.3) }

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
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(greeting).font(Theme.round(42, .black)).foregroundColor(Theme.ink)
                Text(subline).font(Theme.text(18, .medium)).foregroundColor(Theme.sub)
            }
            .at(36, 100)

            heroCard.at(36, 196)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: Canvas.portrait ? 2 : 4), spacing: 16) {
                goalCard
                stat("Days in a row", value: "\(store.streak)", unit: store.streak == 1 ? "day" : "days",
                     icon: "M12 3c1 3.2 5 5.4 5 10a5 5 0 0 1-10 0c0-2.2 1-3.6 2.2-4.8.3 1.6 1 2.6 2 3 0-3 .3-5.6.8-8.2z",
                     label: store.streak == 1 ? "Day streak" : "Days in a row")
                stat("", value: store.speed.map { "\($0)" } ?? "\u{2014}", unit: store.speed == nil ? "" : "q / min",
                     icon: "M13 3 5 13.5h6L10 21l8-10.5h-6z", label: store.speed == nil ? "Take a quiz to see it" : "Quiz speed")
                stat("", value: "\(store.basicsDone)", unit: "of \(store.basicsTotal)",
                     icon: "M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z", label: "Sutras completed")
            }
            .frame(width: Canvas.w - 72)
            .at(36, 196 + heroH + 20)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
    }

    private var heroCard: some View {
        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text("Continue learning").font(Theme.text(14, .bold)).foregroundColor(Theme.blue)
                    Text(hero == nil ? "Done" : heroStarted ? "In progress" : "New")
                        .font(Theme.text(12, .semibold)).foregroundColor(Color(hex: 0x636366))
                        .padding(.horizontal, 10).frame(height: 22)
                        .background(Capsule().fill(tile))
                }
                Text(hero?.name ?? "Every Basics sutra done")
                    .font(Theme.round(32, .black)).foregroundColor(Theme.ink)
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .padding(.top, 10)
                Text(hero == nil ? "All \(store.basicsTotal) sutras done \u{00B7} Basics" : "Sutra \(heroIndex + 1) of \(store.basicsTotal) \u{00B7} Basics")
                    .font(Theme.text(16, .medium)).foregroundColor(Theme.muted)
                    .padding(.top, 6)
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xeef2f6))
                            Capsule().fill(Theme.blue).frame(width: g.size.width * heroFrac)
                        }
                    }
                    .frame(maxWidth: 420, maxHeight: 8)
                    Text("\(Int((heroFrac * 100).rounded()))%").font(Theme.text(14, .bold)).foregroundColor(Theme.sub)
                }
                Button { nav.nextLessonTapped() } label: {
                    HStack(spacing: 6) {
                        Text(hero == nil ? "Review lessons" : heroStarted ? "Continue" : "Start").font(Theme.text(17, .bold))
                        Icon(d: IconPath.forward, size: 20, stroke: 2.6, color: .white)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 26).frame(height: 52)
                    .background(Capsule().fill(Theme.blue))
                }
                .buttonStyle(PressStyle())
                // First visit: a finger shows where to tap, until the first lesson is opened.
                .overlay(alignment: .bottomTrailing) {
                    if store.s.showTapHint { TapHint().offset(x: -24, y: 40).allowsHitTesting(false) }
                }
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(hero?.glyph ?? "\u{2713}")
                .font(Theme.round(38, .black)).foregroundColor(Color(hex: 0x1c1c1e))
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, 14)
                .frame(width: 200, height: 200)
                .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(tile))
        }
        .padding(EdgeInsets(top: 28, leading: 32, bottom: 28, trailing: 28))
        .frame(width: Canvas.w - 72, height: heroH)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .cardShadow()
    }

    private var goalCard: some View {
        let goal = store.s.session, m = store.minutesToday
        return HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color(hex: 0xeef2f6), lineWidth: 6)
                Circle().trim(from: 0, to: min(Double(m) / Double(goal), 1))
                    .stroke(Theme.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 50, height: 50)
            .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(m) of \(goal) min").font(Theme.round(20, .black)).foregroundColor(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("Daily goal").font(Theme.text(13, .medium)).foregroundColor(Theme.sub)
            }
            Spacer(minLength: 0)
        }
        .statCard(statH)
    }

    private func stat(_ key: String, value: String, unit: String, icon: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Icon(d: icon, size: 20, stroke: 2, color: Color(hex: 0x636366))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tile))
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(Theme.round(30, .black)).foregroundColor(Theme.ink)
                Text(unit).font(Theme.text(14, .semibold)).foregroundColor(Theme.sub)
            }
            Text(label).font(Theme.text(13, .medium)).foregroundColor(Theme.sub).lineLimit(1).minimumScaleFactor(0.8)
        }
        .statCard(statH)
    }
}

private extension View {
    func statCard(_ h: CGFloat) -> some View {
        padding(.horizontal, 20).padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: h, maxHeight: h, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
            .cardShadow()
    }
}
