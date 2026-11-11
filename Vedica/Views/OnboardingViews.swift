import SwiftUI

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
                .padding(.top, 40)
            TextField("", text: $name, prompt: Text("Your name").foregroundColor(Theme.ghost))
                .font(Theme.round(24, .heavy))
                .foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)
                .focused($focused)
                .submitLabel(.continue)
                .onSubmit(next)
                .padding(.horizontal, 20)
                .frame(width: 400, height: 64)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(focused ? Theme.blue : Theme.line, lineWidth: 2))
                .padding(.top, 44)
            Button(action: next) {
                Text("Continue")
                    .font(Theme.text(18, .bold))
                    .foregroundColor(valid ? .white : Theme.muted)
                    .frame(width: 400, height: 56)
                    .background(Capsule().fill(valid ? Theme.blue : Color(hex: 0xeef2f6)))
            }
            .buttonStyle(PressStyle(scale: 0.97))
            .disabled(!valid)
            .padding(.top, 24)
        }
        .frame(width: Canvas.w)
        // On a landscape iPhone the keyboard would cover the field, so it moves up.
        .offset(y: focused && !Canvas.portrait && UIDevice.current.userInterfaceIdiom == .phone ? 20 : 168 + Canvas.extraY)
        .animation(.easeOut(duration: 0.25), value: focused)
        .frame(width: Canvas.w, height: Canvas.h, alignment: .top)
        .background(Theme.canvas)
        .onAppear { name = nav.store.s.name }
    }

    private func next() {
        guard valid else { return }
        focused = false
        nav.store.s.name = name.trimmingCharacters(in: .whitespaces)
        nav.go(.account)
    }
}

struct AccountScreen: View {
    @Environment(AppNavigator.self) private var nav

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text("Nice to meet you, \(nav.store.trimmedName).")
                    .font(Theme.text(18, .medium)).foregroundColor(Theme.sub)
                Text("Save your progress")
                    .font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                    .padding(.top, 12)
                Text("Sign in so you never lose your streak.")
                    .font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
                    .padding(.top, 14)
                Button {
                    AppleSignIn.shared.start { ok in
                        if ok { nav.store.s.signedIn = true; nav.go(.showcase(0)) } else { nav.flash("Sign in didn\u{2019}t finish. You can skip for now.") }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo").font(.system(size: 19, weight: .medium))
                        Text("Sign in with Apple").font(Theme.text(19, .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 320, height: 56)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.black))
                }
                .buttonStyle(PressStyle(scale: 0.97))
                .padding(.top, 52)
                Button("Skip for now") { nav.go(.showcase(0)) }
                    .font(Theme.text(17, .semibold))
                    .foregroundColor(Theme.blue)
                    .padding(.top, 14)
            }
            .frame(width: Canvas.w)
            .at(0, 200 + Canvas.extraY)

            RoundIconButton(d: IconPath.back, size: 56, icon: 26) { nav.go(.name, forward: false) }
                .at(36, Canvas.h - 30 - 56)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
    }
}

/// The four intro slides on a swipeable track.
struct ShowcaseScreen: View {
    @Environment(AppNavigator.self) private var nav
    @State private var page = 0
    private let slides = [("Learn interactively", "Watch every trick come alive, step by step.", "play.rectangle.fill"),
                          ("Practice at your pace", "No clock. No pressure. Just you getting better.", "pencil.and.scribble"),
                          ("Speed up your calculations", "Do in your head what others need a calculator for.", "bolt.fill"),
                          ("Track your progress", "Watch yourself grow, one sutra at a time.", "chart.bar.fill")]

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $page) {
                ForEach(0..<4, id: \.self) { i in
                    ZStack(alignment: .topLeading) {
                        ZStack {
                            Color(hex: 0xf2f6fa)
                            Image(systemName: slides[i].2)
                                .font(.system(size: 132, weight: .semibold))
                                .foregroundStyle(Theme.blue)
                        }
                        .frame(width: Canvas.w, height: 440 + Canvas.extraY * 2)
                        VStack(spacing: 14) {
                            Text(slides[i].0).font(Theme.round(44, .black)).foregroundColor(Theme.ink)
                            Text(slides[i].1).font(Theme.text(20, .medium)).foregroundColor(Theme.sub)
                        }
                        .frame(width: Canvas.w)
                        .at(0, 500 + Canvas.extraY * 2)
                    }
                    .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: Canvas.w, height: Canvas.h)

            ZStack {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule().fill(i <= page ? Theme.blue : Theme.line).frame(width: 42, height: 5)
                    }
                }
                HStack {
                    RoundIconButton(d: IconPath.back, size: 56, icon: 26, action: back)
                    Spacer()
                    PrimaryPill(title: page == 3 ? "Start Learning" : "Next", action: next)
                }
            }
            .frame(width: Canvas.w - 72, height: 56)
            .at(36, Canvas.h - 30 - 56)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
        .animation(.easeOut(duration: 0.3), value: page)
    }

    private func back() {
        if page > 0 { withAnimation { page -= 1 } } else { nav.go(.account, forward: false) }
    }

    private func next() {
        if page < 3 { withAnimation { page += 1 }; return }
        nav.store.s.onboarded = true
        nav.store.s.showTapHint = true
        nav.store.s.joined = Date()
        // Start Learning goes to Home, where a finger shows the new user where to tap.
        nav.go(.home)
    }
}
