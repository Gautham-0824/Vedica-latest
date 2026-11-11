import SwiftUI

struct RootView: View {
    @State private var nav = AppNavigator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Group {
                if case .lesson(let id, let start, let review) = nav.route {
                    LessonScreen(id: id, start: start, review: review)
                        .id("lesson-\(id)-\(start)-\(review)")
                } else {
                    CanvasFit(background: nav.route == .profile ? Color(hex: 0xf2f2f7) : Theme.canvas) { ScreenRouter() }
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(x: nav.forward ? 32 : -32)), removal: .opacity))
        }
        .environment(nav)
        .preferredColorScheme(.light)
        .statusBarHidden()
        .onChange(of: scenePhase) { _, p in
            if p == .active && nav.store.s.onboarded { nav.store.scheduleReminder() }
            if p != .active { nav.store.flushActivity() }
        }
    }
}

struct ScreenRouter: View {
    @Environment(AppNavigator.self) private var nav

    private var tabIndex: Int? {
        switch nav.route {
        case .home: return 0
        case .lessons, .tier: return 1
        case .quizzes: return 2
        case .progress: return 3
        default: return nil
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                switch nav.route {
                case .name: NameScreen()
                case .account: AccountScreen()
                case .showcase: ShowcaseScreen()
                case .home: HomeScreen()
                case .lessons: LessonsScreen()
                case .tier(let t): TierScreen(tier: t)
                case .quizzes: QuizzesScreen()
                case .progress: ProgressScreen()
                case .profile: ProfileScreen()
                case .work: WorkScreen()
                case .results: ResultsScreen()
                case .lesson: EmptyView()
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(x: nav.forward ? 40 : -40)), removal: .opacity))

            if let t = tabIndex { TabHeader(index: t) }

            if let id = nav.sheet { ModuleSheet(family: id) }

            if !nav.toast.isEmpty {
                Text(nav.toast)
                    .font(Theme.text(15, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(Capsule().fill(Theme.ink))
                    .frame(width: Canvas.w, alignment: .center)
                    .offset(y: Canvas.h - 78)
                    .transition(.opacity)
            }
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
        .clipped()
    }
}

/// Header shared by the four tabs: logo, tab pill and avatar.
struct TabHeader: View {
    @Environment(AppNavigator.self) private var nav
    let index: Int
    private let labels = ["Home", "Lessons", "Quiz", "Progress"]
    private var routes: [Route] { [.home, .lessons, .quizzes, .progress] }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 12) {
                VedicaLogo(size: 52, shadowed: false)
                if !Canvas.portrait { Text("Vedica").font(Theme.round(38, .heavy)).foregroundColor(Theme.ink) }
            }
            .frame(height: 56)
            .offset(x: 36, y: 24)

            Button { nav.profileFrom = nav.route; nav.go(.profile) } label: {
                AvatarView(size: 52)
            }
            .buttonStyle(PressStyle(scale: 0.94))
            .offset(x: Canvas.w - 36 - 52, y: 26)

            ZStack(alignment: .leading) {
                Capsule().fill(.white).frame(width: 100, height: 38)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
                    .offset(x: CGFloat(index) * 102)
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        Button { nav.sheet = nil; nav.go(routes[i], forward: i >= index) } label: {
                            Text(labels[i])
                                .font(Theme.text(15, i == index ? .semibold : .medium))
                                .foregroundColor(i == index ? Theme.ink : Color(hex: 0x3c3c43))
                                .frame(width: 100, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(3)
            .background(Capsule().fill(Color(hex: 0x767680, alpha: 0.12)))
            .frame(width: Canvas.w, alignment: .center)
            .offset(y: 34)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: index)
    }
}

struct AvatarView: View {
    @Environment(AppNavigator.self) private var nav
    var size: CGFloat
    static let colors: [Color] = [Theme.blue, Theme.green, Theme.orange, Color(hex: 0x7b61ff)]

    var body: some View {
        let s = nav.store.trimmedName.first.map { String($0).uppercased() } ?? "V"
        Text(s)
            .font(Theme.round(size * 0.44, .heavy))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Self.colors[nav.store.s.avatar % 4]))
    }
}

extension View {
    /// Places a view at artifact coordinates inside a top-leading ZStack.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View { offset(x: x, y: y) }

    /// The artifact's standard card shadow.
    func cardShadow() -> some View {
        shadow(color: Theme.shadow.opacity(0.03), radius: 0, x: 0, y: 1)
            .shadow(color: Theme.shadow.opacity(0.06), radius: 15, x: 0, y: 10)
    }
}
