import SwiftUI

struct RootView: View {
    @State private var nav = AppNavigator()
    @Environment(\.scenePhase) private var scenePhase

    private var flowShown: Binding<Bool> {
        Binding(get: { nav.flow != nil }, set: { if !$0 { nav.flow = nil } })
    }

    var body: some View {
        AdaptiveRoot {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                if nav.store.s.onboarded {
                    MainTabs().transition(.opacity.combined(with: .offset(x: 40)))
                } else {
                    OnboardingFlow().transition(.opacity.combined(with: .offset(x: -40)))
                }
            }
            .animation(AppNavigator.slide, value: nav.store.s.onboarded)
            .overlay(alignment: .bottom) { ToastView() }
            .fullScreenCover(isPresented: flowShown) {
                FlowView()
                    .environment(nav)
                    .preferredColorScheme(.light)
                    .statusBarHidden()
            }
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

/// The four tabs in a native `TabView` with the system tab bar.
struct MainTabs: View {
    @Environment(AppNavigator.self) private var nav

    private var moduleSheet: Binding<ModuleSheetID?> {
        Binding(get: { nav.sheet.map(ModuleSheetID.init) }, set: { nav.sheet = $0?.id })
    }

    var body: some View {
        @Bindable var nav = nav
        // The system tab bar is shown (HIG): at the bottom on iPhone, iPadOS's standard tab bar on iPad.
        TabView(selection: $nav.tab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.symbol, value: AppTab.home) {
                withHeader { HomeScreen() }
            }
            Tab(AppTab.lessons.title, systemImage: AppTab.lessons.symbol, value: AppTab.lessons) {
                withHeader {
                    NavigationStack(path: $nav.lessonsPath) {
                        LessonsScreen()
                            .hiddenNavBar()
                            .navigationDestination(for: Tier.self) { TierScreen(tier: $0).hiddenNavBar() }
                    }
                }
            }
            Tab(AppTab.quizzes.title, systemImage: AppTab.quizzes.symbol, value: AppTab.quizzes) {
                withHeader { QuizzesScreen() }
            }
            Tab(AppTab.progress.title, systemImage: AppTab.progress.symbol, value: AppTab.progress) {
                withHeader { ProgressScreen() }
            }
        }
        .tint(Theme.blue)
        .background(Theme.canvas.ignoresSafeArea())
        .sheet(item: moduleSheet) { ModuleSheet(family: $0.id) }
    }

    /// Logo and avatar above a tab's screen.
    private func withHeader<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) {
            TabHeader()
            content()
        }
        .background(Theme.canvas.ignoresSafeArea())
    }
}

/// Onboarding in a native `NavigationStack`: name, then sign-in, then the intro slides.
struct OnboardingFlow: View {
    @Environment(AppNavigator.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        NavigationStack(path: $nav.onboardingPath) {
            NameScreen()
                .hiddenNavBar()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .account: AccountScreen().hiddenNavBar()
                    case .showcase: ShowcaseScreen().hiddenNavBar()
                    }
                }
        }
    }
}

/// Lesson, Practice/Quiz, Results and Profile, shown in one full-screen cover.
/// Moving between them inside the cover keeps the original sideways slide.
struct FlowView: View {
    @Environment(AppNavigator.self) private var nav

    var body: some View {
        ZStack {
            (nav.shownFlow == .profile ? Color(hex: 0xf2f2f7) : Theme.canvas).ignoresSafeArea()
            Group {
                switch nav.shownFlow {
                case .lesson(let id, let start, let review):
                    LessonScreen(id: id, start: start, review: review)
                        .id("lesson-\(id)-\(start)-\(review)")
                case .work: WorkScreen()
                case .results: ResultsScreen()
                case .profile: ProfileScreen()
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(x: nav.forward ? 40 : -40)), removal: .opacity))
        }
        .overlay(alignment: .bottom) { ToastView() }
    }
}

/// Short message at the bottom of the screen.
struct ToastView: View {
    @Environment(AppNavigator.self) private var nav

    var body: some View {
        if !nav.toast.isEmpty {
            Text(nav.toast)
                .font(Theme.text(15, .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, pt(20))
                .frame(height: pt(44))
                .background(Capsule().fill(Theme.ink))
                .padding(.bottom, pt(34))
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }
}

/// Header shared by the four tabs: logo and avatar.
struct TabHeader: View {
    @Environment(AppNavigator.self) private var nav
    private var layout: Metrics { Metrics.shared }

    var body: some View {
        // Tabs are switched with the system tab bar, so the header only holds the logo and the avatar.
        HStack { logo; Spacer(); avatar }
            .padding(.horizontal, pt(36))
            .padding(.top, pt(layout.compact ? 12 : 24))
    }

    private var logo: some View {
        HStack(spacing: pt(12)) {
            VedicaLogo(size: 52, shadowed: false)
            if !layout.portrait { Text("Vedica").font(Theme.round(38, .heavy)).foregroundColor(Theme.ink) }
        }
        .frame(height: pt(56))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vedica")
    }

    private var avatar: some View {
        Button { nav.openProfile() } label: { AvatarView(size: 52) }
            .buttonStyle(PressStyle(scale: 0.94))
            .padding(.top, pt(2))
            .accessibilityLabel("Profile")
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
            .frame(width: pt(size), height: pt(size))
            .background(Circle().fill(Self.colors[nav.store.s.avatar % 4]))
    }
}

extension View {
    /// Places a view at design coordinates inside a top-leading ZStack (used by fixed drawings such as the lesson map).
    func at(_ x: CGFloat, _ y: CGFloat) -> some View { offset(x: pt(x), y: pt(y)) }

    /// The artifact's standard card shadow.
    func cardShadow() -> some View {
        shadow(color: Theme.shadow.opacity(0.03), radius: 0, x: 0, y: 1)
            .shadow(color: Theme.shadow.opacity(0.06), radius: 15, x: 0, y: 10)
    }

    /// The design draws its own tab pill, so the system tab bar stays hidden.
    func hiddenTabBar() -> some View { toolbar(.hidden, for: .tabBar) }

    /// The design draws its own back buttons, so the system navigation bar stays hidden.
    func hiddenNavBar() -> some View { toolbar(.hidden, for: .navigationBar) }

    /// Fills the window with a screen colour behind its content.
    func screenBackground(_ c: Color = Theme.canvas) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(c.ignoresSafeArea())
    }
}
