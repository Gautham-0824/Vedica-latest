import SwiftUI

/// The Quizzes tab: one quiz per lesson, grouped by tier.
///
/// A summary card at the top, Apple's segmented control to pick the tier, and a grid of
/// `QuizCard`s (two across when there is room, one on a narrow iPhone).
struct QuizzesScreen: View {
    @Environment(AppNavigator.self) private var nav
    @State private var group = "basics"

    private var layout: Metrics { Metrics.shared }
    /// Two cards across once the window is wide enough for them (both iPad orientations,
    /// and iPhone in landscape); one on a phone held upright.
    private var twoUp: Bool { layout.w >= 700 }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: pt(12)), count: twoUp ? 2 : 1)
    }
    private var shown: QuizData.Group { QuizData.groups.first { $0.id == group } ?? QuizData.groups[0] }
    private var shownQuestions: Int { shown.ids.reduce(0) { $0 + QuizData.questions($1).count } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Quizzes").font(Theme.round(52, .black)).foregroundColor(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Test what you\u{2019}ve learned so far.").font(Theme.text(22, .medium)).foregroundColor(Theme.sub)
                    .padding(.top, pt(8))

                summary.padding(.top, pt(20))

                Picker("Tier", selection: $group) {
                    ForEach(QuizData.groups) { g in Text(g.title).tag(g.id) }
                }
                .pickerStyle(.segmented)
                .padding(.top, pt(20))

                HStack(spacing: pt(8)) {
                    Text("\(shown.ids.count) QUIZZES").font(Theme.text(12, .bold)).tracking(pt(1))
                        .foregroundColor(QuizTint.of(group).strong)
                        .padding(.horizontal, pt(10)).frame(height: pt(22))
                        .background(Capsule().fill(QuizTint.of(group).soft))
                    Text("\(shownQuestions) questions in all").font(Theme.text(13, .semibold))
                        .foregroundColor(Theme.sub)
                    Spacer(minLength: 0)
                }
                .padding(.top, pt(18))
                .accessibilityElement(children: .combine)

                LazyVGrid(columns: columns, spacing: pt(12)) {
                    ForEach(shown.ids, id: \.self) { id in
                        QuizCard(id: id, tint: QuizTint.of(group),
                                 score: nav.store.s.scores[id],
                                 best: nav.store.s.times[id]?.best,
                                 height: twoUp ? 150 : nil) {
                            nav.startQuiz(id, fromQuizzes: true)
                        }
                    }
                }
                .padding(.top, pt(12))
                .animation(.easeOut(duration: 0.2), value: group)
            }
            .padding(.horizontal, pt(36))
            .padding(.top, pt(20))
            .padding(.bottom, pt(30))
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground()
    }

    // MARK: summary

    private var allIDs: [String] { QuizData.ids }
    private var taken: [String] { allIDs.filter { nav.store.s.scores[$0] != nil } }
    private var perfect: Int { taken.filter { nav.store.s.scores[$0] == QuizData.questions($0).count }.count }
    private var right: Int { taken.reduce(0) { $0 + (nav.store.s.scores[$1] ?? 0) } }
    private var fastest: Int? { taken.compactMap { nav.store.s.times[$0]?.best }.min() }
    private var done: Double { allIDs.isEmpty ? 0 : Double(taken.count) / Double(allIDs.count) }

    private var summary: some View {
        HStack(spacing: pt(18)) {
            ZStack {
                Circle().stroke(Color(hex: 0xeef2f6), lineWidth: pt(9))
                Circle().trim(from: 0, to: done)
                    .stroke(Theme.blue, style: StrokeStyle(lineWidth: pt(9), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(taken.count)").font(Theme.round(24, .black)).foregroundColor(Theme.ink)
                    Text("of \(allIDs.count)").font(Theme.text(11, .semibold)).foregroundColor(Theme.sub)
                }
            }
            .frame(width: pt(78), height: pt(78))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(taken.count) of \(allIDs.count) quizzes tried")

            VStack(alignment: .leading, spacing: pt(2)) {
                Text(taken.isEmpty ? "Nothing tried yet" : "Quizzes tried")
                    .font(Theme.round(20, .heavy)).foregroundColor(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(taken.isEmpty ? "Pick any lesson below and start."
                                   : layout.compact ? "Perfect \(perfect) \u{00B7} \(right) right \u{00B7} fastest \(fastest.map { clockText($0) } ?? "\u{2014}")"
                                   : "Keep going \u{2014} every lesson has one.")
                    .font(Theme.text(14, .medium)).foregroundColor(Theme.sub)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            if !layout.compact {
                HStack(spacing: 0) {
                    stat("Perfect", "\(perfect)")
                    stat("Right", "\(right)")
                    stat("Fastest", fastest.map { clockText($0) } ?? "\u{2014}")
                }
                .frame(width: pt(260))
            }
        }
        .padding(EdgeInsets(top: pt(16), leading: pt(18), bottom: pt(16), trailing: pt(18)))
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: pt(24), style: .continuous).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: pt(24), style: .continuous).stroke(Theme.line, lineWidth: 1))
        .cardShadow()
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: pt(2)) {
            Text(value).font(Theme.round(20, .black)).foregroundColor(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(Theme.text(12, .medium)).foregroundColor(Theme.sub)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
