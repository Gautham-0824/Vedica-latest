import SwiftUI

/// Vertical space left over around the design's 768-point-tall layout, so a screen can sit in the middle.
private var extraY: CGFloat { max(0, (Metrics.shared.h - 768) / 2) }
/// Width of the name field and its button: 400 design points, never wider than the window allows.
private var columnW: CGFloat { min(pt(400), Metrics.shared.size.width - pt(48)) }

struct NameScreen: View {
    @Environment(AppNavigator.self) private var nav
    @State private var name = ""
    @FocusState private var focused: Bool

    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            VedicaLogo(size: 76, tall: true)
            Text("What should we call you?")
                .font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, pt(40))
            TextField("", text: $name, prompt: Text("Your name").foregroundColor(Theme.ghost))
                .font(Theme.round(24, .heavy))
                .foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)
                .focused($focused)
                .textContentType(.givenName)
                .submitLabel(.continue)
                .onSubmit(next)
                .accessibilityLabel("Your name")
                .padding(.horizontal, pt(20))
                .frame(width: columnW, height: pt(64))
                .background(RoundedRectangle(cornerRadius: pt(20), style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: pt(20), style: .continuous)
                    .stroke(focused ? Theme.blue : Theme.line, lineWidth: 2))
                .padding(.top, pt(44))
            Button(action: next) {
                Text("Continue")
                    .font(Theme.text(18, .bold))
                    .foregroundColor(valid ? .white : Theme.muted)
                    .frame(width: columnW, height: pt(56))
                    .background(Capsule().fill(valid ? Theme.blue : Color(hex: 0xeef2f6)))
            }
            .buttonStyle(PressStyle(scale: 0.97))
            .disabled(!valid)
            .padding(.top, pt(24))
        }
        .frame(maxWidth: .infinity)
        // On a short (landscape iPhone) window the keyboard would cover the field, so it moves up.
        .padding(.top, pt(focused && Metrics.shared.short ? 20 : 168 + extraY))
        .animation(.easeOut(duration: 0.25), value: focused)
        .screenBackground()
        .ignoresSafeArea(.keyboard)
        .onAppear { name = nav.store.s.name }
    }

    private func next() {
        guard valid else { return }
        focused = false
        nav.store.s.name = name.trimmingCharacters(in: .whitespaces)
        nav.onboardingPath.append(.account)
    }
}

struct AccountScreen: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Nice to meet you, \(nav.store.trimmedName).")
                .font(Theme.text(18, .medium)).foregroundColor(Theme.sub)
            Text("Save your progress")
                .font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, pt(12))
            Text("Sign in so you never lose your streak.")
                .font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
                .padding(.top, pt(14))
            Button {
                AppleSignIn.shared.start { ok in
                    if ok { nav.store.s.signedIn = true; nav.onboardingPath.append(.showcase) } else { nav.flash("Sign in didn\u{2019}t finish. You can skip for now.") }
                }
            } label: {
                HStack(spacing: pt(8)) {
                    Image(systemName: "applelogo").font(.system(size: pt(19), weight: .medium))
                    Text("Sign in with Apple").font(Theme.text(19, .semibold))
                }
                .foregroundColor(.white)
                .frame(width: pt(320), height: pt(56))
                .background(RoundedRectangle(cornerRadius: pt(14), style: .continuous).fill(.black))
            }
            .buttonStyle(PressStyle(scale: 0.97))
            .padding(.top, pt(52))
            Button("Skip for now") { nav.onboardingPath.append(.showcase) }
                .font(Theme.text(17, .semibold))
                .foregroundColor(Theme.blue)
                .padding(.top, pt(14))
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, pt(24))
        .padding(.top, pt(Metrics.shared.short ? 60 : 200 + extraY))
        .screenBackground()
        .overlay(alignment: .bottomLeading) {
            RoundIconButton(d: IconPath.back, size: 56, icon: 26) { dismiss() }
                .accessibilityLabel("Back")
                .padding(.leading, pt(36))
                .padding(.bottom, pt(30))
        }
    }
}

/// The four intro slides on a native paged `TabView`.
struct ShowcaseScreen: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    private let slides = [("Learn interactively", "Watch every trick come alive, step by step.", "play.rectangle.fill"),
                          ("Practice at your pace", "No clock. No pressure. Just you getting better.", "pencil.and.scribble"),
                          ("Speed up your calculations", "Do in your head what others need a calculator for.", "bolt.fill"),
                          ("Track your progress", "Watch yourself grow, one sutra at a time.", "chart.bar.fill")]
    private var imageH: CGFloat { Metrics.shared.short ? Metrics.shared.h * 0.42 : 440 + extraY * 2 }

    var body: some View {
        TabView(selection: $page) {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 0) {
                    ZStack {
                        Color(hex: 0xf2f6fa)
                        Image(systemName: slides[i].2)
                            .font(.system(size: pt(Metrics.shared.short ? 90 : 132), weight: .semibold))
                            .foregroundStyle(Theme.blue)
                            .accessibilityHidden(true)
                    }
                    .frame(height: pt(imageH))
                    VStack(spacing: pt(14)) {
                        Text(slides[i].0).font(Theme.round(44, .black)).foregroundColor(Theme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(slides[i].1).font(Theme.text(20, .medium)).foregroundColor(Theme.sub)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, pt(24))
                    .padding(.top, pt(60))
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            ZStack {
                HStack(spacing: pt(6)) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule().fill(i <= page ? Theme.blue : Theme.line).frame(width: pt(42), height: pt(5))
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Slide \(page + 1) of 4")
                HStack {
                    RoundIconButton(d: IconPath.back, size: 56, icon: 26, action: back)
                        .accessibilityLabel("Back")
                    Spacer()
                    PrimaryPill(title: page == 3 ? "Start Learning" : "Next", action: next)
                }
            }
            .frame(height: pt(56))
            .padding(.horizontal, pt(36))
            .padding(.bottom, pt(30))
        }
        .screenBackground()
        .animation(.easeOut(duration: 0.3), value: page)
    }

    private func back() {
        if page > 0 { withAnimation { page -= 1 } } else { dismiss() }
    }

    private func next() {
        if page < 3 { withAnimation { page += 1 }; return }
        nav.finishOnboarding()
    }
}
