import SwiftUI
import StoreKit

struct ProfileScreen: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.requestReview) private var requestReview
    @State private var editing = false
    @State private var draft = ""
    @State private var deleting = false
    @State private var picker = false
    private var store: ProgressStore { nav.store }
    private let bg = Color(hex: 0xf2f2f7)

    private var joined: String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"
        return f.string(from: store.s.joined)
    }

    var body: some View {
        @Bindable var store = store
        ZStack(alignment: .topLeading) {
            bg
            Text("Profile").font(Theme.text(17, .semibold)).foregroundColor(.black)
                .frame(width: Canvas.w).at(0, 22)
            Button("\u{2039} Back") { nav.go(nav.profileFrom, forward: false) }
                .font(Theme.text(17, .regular)).foregroundColor(Theme.blue).at(24, 22)
            Button(editing ? "Done" : "Edit") {
                if editing {
                    let n = draft.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { store.s.name = n }
                } else { draft = store.s.name }
                editing.toggle()
            }
            .font(Theme.text(17, editing ? .semibold : .regular)).foregroundColor(Theme.blue)
            .frame(width: Canvas.w - 48, alignment: .trailing).at(24, 22)

            if Canvas.portrait {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        left
                        rows
                    }
                }
                .frame(width: Canvas.w - 72, height: Canvas.h - 84).at(36, 84)
            } else {
                left.frame(width: 400).at(36, 84)
                ScrollView(showsIndicators: false) { rows }
                    .frame(width: Canvas.w - 460 - 36, height: Canvas.h - 84).at(460, 84)
            }

            if deleting { deleteAlert }
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
    }

    private var left: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                AvatarView(size: 88)
                if editing {
                    TextField("Name", text: $draft)
                        .font(Theme.text(22, .bold)).multilineTextAlignment(.center)
                        .padding(.horizontal, 12).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(bg))
                        .padding(.top, 12)
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { i in
                            Button { store.s.avatar = i } label: {
                                Circle().fill(AvatarView.colors[i]).frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(.white, lineWidth: 2).padding(2).opacity(store.s.avatar == i ? 1 : 0))
                            }
                        }
                    }
                    .padding(.top, 10)
                } else {
                    Text(store.trimmedName.isEmpty ? "Learner" : store.trimmedName)
                        .font(Theme.text(24, .bold)).foregroundColor(.black).padding(.top, 12)
                }
                HStack {
                    Text("Basics").font(Theme.text(13, .semibold)).foregroundColor(Color(hex: 0x6d6d72))
                    Spacer()
                    Text("\(store.basicsDone) of \(store.basicsTotal) sutras").font(Theme.text(13, .medium)).foregroundColor(Color(hex: 0x6d6d72))
                }
                .padding(.top, 14)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xe5e5ea))
                        Capsule().fill(Theme.blue).frame(width: g.size.width * CGFloat(store.basicsDone) / CGFloat(store.basicsTotal))
                    }
                }
                .frame(height: 6).padding(.top, 6)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    tile("Day streak", "\(store.streak) \(store.streak == 1 ? "day" : "days")", "flame.fill")
                    tile("Badges", "\(store.earned.filter { $0 }.count) of 4", "star.fill")
                    tile("Quizzes taken", "\(store.s.history.count)", "doc.text.fill")
                    tile("Member since", joined, "calendar")
                }
                .padding(.top, 14)
            }
            .padding(EdgeInsets(top: 22, leading: 20, bottom: 18, trailing: 20))
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))

            caption("Badges").padding(.top, 16)
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let got = store.earned[i]
                    Image(systemName: got ? "star.fill" : "lock.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(got ? .white : Color(hex: 0xaeaeb2))
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(got ? Theme.blue : bg))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))

            caption("This week").padding(.top, 16)
            weekBars
        }
    }

    private var weekBars: some View {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let days = (0..<7).map { cal.date(byAdding: .day, value: $0, to: start) ?? start }
        let vals = days.map { store.seconds(on: $0) }, peak = max(vals.max() ?? 1, 60)
        return HStack(alignment: .bottom, spacing: 14) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cal.isDateInToday(days[i]) ? Theme.blue : Color(hex: 0xc7c7cc))
                        .frame(height: max(4, 54 * CGFloat(vals[i]) / CGFloat(peak)))
                    Text(String(Array("MTWTFSS")[i])).font(Theme.text(11, .medium)).foregroundColor(Color(hex: 0x8e8e93))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .frame(height: 92)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
    }

    private func tile(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 15)).foregroundColor(Color(hex: 0x636366))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(.white))
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(Theme.text(15, .bold)).foregroundColor(.black).lineLimit(1).minimumScaleFactor(0.7)
                Text(label).font(Theme.text(12, .medium)).foregroundColor(Color(hex: 0x6d6d72)).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xf5f6f8)))
    }

    private func caption(_ s: String) -> some View {
        Text(s.uppercased()).font(Theme.text(13, .regular)).foregroundColor(Color(hex: 0x6d6d72))
            .padding(.leading, 16).padding(.bottom, 7)
    }

    private var rows: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 0) {
                group("Account") {
                    row("applelogo", .black, "Sign in with Apple", value: store.s.signedIn ? "Signed in" : "Not signed in", chevron: !store.s.signedIn) {
                        guard !store.s.signedIn else { return }
                        AppleSignIn.shared.start { ok in
                            if ok { store.s.signedIn = true } else { nav.flash("Sign in didn\u{2019}t finish.") }
                        }
                    }
                }
                group("iCloud", footer: store.s.icloud ? "Your progress, badges and streak stay in sync on every iPhone and iPad signed in to your Apple Account. Last synced just now." : "Progress is saved on this iPad only.") {
                    toggleRow("icloud.fill", Theme.blue, "Sync with iCloud", $store.s.icloud)
                }
                group("Learning") {
                    toggleRow("speaker.wave.2.fill", Color(hex: 0xff9500), "Narration", $store.s.narrationOn)
                    sep
                    row("globe", Color(hex: 0x34c759), "Language", value: "English", chevron: false) {}
                    sep
                    row("bell.fill", Color(hex: 0xff3b30), "Daily reminder", value: store.s.remOn ? store.clock(store.s.rem) : "Off") { nav.go(.progress, forward: false) }
                    sep
                    toggleRow("iphone.radiowaves.left.and.right", Color(hex: 0xff2d55), "Sounds & Haptics", $store.s.haptics)
                }
                group("Family") {
                    row("person.2.fill", Color(hex: 0x5856d6), "Parent dashboard") { nav.go(.progress, forward: false) }
                }
                group("Support") {
                    row("questionmark", Theme.blue, "Help & Support") { open("https://vedica.app/help") }
                    sep
                    row("star.fill", Color(hex: 0xffcc00), "Rate Vedica") { requestReview() }
                    sep
                    row("hand.raised.fill", Color(hex: 0x8e8e93), "Privacy Policy") { open("https://vedica.app/privacy") }
                    sep
                    row("doc.text.fill", Color(hex: 0x8e8e93), "Terms of Use") { open("https://vedica.app/terms") }
                }
                Button { withAnimation(.easeOut(duration: 0.2)) { deleting = true } } label: {
                    Text("Delete Account").font(Theme.text(17, .regular)).foregroundColor(Color(hex: 0xff3b30))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                }
                .padding(.top, 8)
                Text("Vedica 1.0 (1)").font(Theme.text(13, .regular)).foregroundColor(Color(hex: 0x8e8e93))
                    .frame(maxWidth: .infinity).padding(.top, 14).padding(.bottom, 32)
        }
        .onChange(of: store.s.icloud) { _, on in if on { nav.flash("iCloud sync on") } }
    }

    private func open(_ url: String) { if let u = URL(string: url) { UIApplication.shared.open(u) } }

    private var sep: some View { Rectangle().fill(Color(hex: 0xc6c6c8)).frame(height: 0.5).padding(.leading, 58) }

    private func group<C: View>(_ title: String, footer: String? = nil, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            caption(title)
            VStack(spacing: 0) { content() }
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
            if let footer {
                Text(footer).font(Theme.text(13, .regular)).foregroundColor(Color(hex: 0x6d6d72))
                    .padding(.horizontal, 16).padding(.top, 7)
            }
        }
        .padding(.bottom, 18)
    }

    private func glyph(_ s: String, _ c: Color) -> some View {
        Image(systemName: s).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            .frame(width: 29, height: 29)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(c))
    }

    private func row(_ icon: String, _ c: Color, _ title: String, value: String? = nil, chevron: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                glyph(icon, c)
                Text(title).font(Theme.text(17, .regular)).foregroundColor(.black)
                Spacer()
                if let value { Text(value).font(Theme.text(17, .regular)).foregroundColor(Color(hex: 0x8e8e93)) }
                if chevron { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: 0xc7c7cc)) }
            }
            .padding(.horizontal, 16).frame(height: 48).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ icon: String, _ c: Color, _ title: String, _ on: Binding<Bool>) -> some View {
        HStack(spacing: 13) {
            glyph(icon, c)
            Text(title).font(Theme.text(17, .regular)).foregroundColor(.black)
            Spacer()
            Toggle("", isOn: on).labelsHidden().tint(Color(hex: 0x34c759))
        }
        .padding(.horizontal, 16).frame(height: 48)
    }

    private var deleteAlert: some View {
        ZStack {
            Color.black.opacity(0.28)
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Delete Account?").font(Theme.text(17, .semibold)).foregroundColor(.black)
                    Text("This permanently deletes your name, progress, badges and streak from this iPad and from iCloud. This can\u{2019}t be undone.")
                        .font(Theme.text(13, .regular)).foregroundColor(.black)
                        .multilineTextAlignment(.center).lineSpacing(2)
                }
                .padding(EdgeInsets(top: 20, leading: 16, bottom: 18, trailing: 16))
                Rectangle().fill(Color(hex: 0xc6c6c8)).frame(height: 0.5)
                HStack(spacing: 0) {
                    Button { withAnimation { deleting = false } } label: {
                        Text("Cancel").font(Theme.text(17, .regular)).foregroundColor(Theme.blue).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Rectangle().fill(Color(hex: 0xc6c6c8)).frame(width: 0.5)
                    Button { nav.reset() } label: {
                        Text("Delete").font(Theme.text(17, .semibold)).foregroundColor(Color(hex: 0xff3b30)).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 44)
            }
            .frame(width: 280)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
        }
        .frame(width: Canvas.w, height: Canvas.h)
        .transition(.opacity)
    }
}
