import SwiftUI
import StoreKit

/// Profile: a native navigation bar and an inset-grouped `List`, in the design's fonts.
struct ProfileScreen: View {
    @Environment(AppNavigator.self) private var nav
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var editing = false
    @State private var draft = ""
    @State private var deleting = false
    private var store: ProgressStore { nav.store }
    private var layout: Metrics { Metrics.shared }
    private let bg = Color(hex: 0xf2f2f7)
    private let caption = Color(hex: 0x6d6d72)
    private var device: String { UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone" }

    private var joined: String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"
        return f.string(from: store.s.joined)
    }

    var body: some View {
        NavigationStack {
            Group {
                if layout.wide {
                    HStack(alignment: .top, spacing: pt(24)) {
                        ScrollView(showsIndicators: false) { left.padding(.bottom, pt(32)) }
                            .frame(width: pt(400))
                            .padding(.leading, pt(36))
                        list
                    }
                } else {
                    list
                }
            }
            .padding(.top, pt(12))
            .background(bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { nav.closeFlow() } label: {
                        Text("\u{2039} Back").font(Theme.text(17, .regular)).foregroundColor(Theme.blue)
                    }
                    .accessibilityLabel("Back")
                }
                ToolbarItem(placement: .principal) {
                    Text("Profile").font(Theme.text(17, .semibold)).foregroundColor(.black)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleEditing) {
                        Text(editing ? "Done" : "Edit").font(Theme.text(17, editing ? .semibold : .regular)).foregroundColor(Theme.blue)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Account?", isPresented: $deleting) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { nav.reset() }
            } message: {
                Text("This permanently deletes your name, progress, badges and streak from this \(device) and from iCloud. This can\u{2019}t be undone.")
            }
        }
        .onChange(of: store.s.icloud) { _, on in if on { nav.flash("iCloud sync on") } }
    }

    private func toggleEditing() {
        if editing {
            let n = draft.trimmingCharacters(in: .whitespaces)
            if !n.isEmpty { store.s.name = n }
        } else { draft = store.s.name }
        editing.toggle()
    }

    // MARK: summary (avatar, stats, badges, week)

    private var left: some View {
        @Bindable var store = store
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                AvatarView(size: 88)
                if editing {
                    TextField("Name", text: $draft)
                        .font(Theme.text(22, .bold)).multilineTextAlignment(.center)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .onSubmit(toggleEditing)
                        .padding(.horizontal, pt(12)).frame(height: pt(44))
                        .background(RoundedRectangle(cornerRadius: pt(10)).fill(bg))
                        .padding(.top, pt(12))
                    HStack(spacing: pt(12)) {
                        ForEach(0..<4, id: \.self) { i in
                            Button { store.s.avatar = i } label: {
                                Circle().fill(AvatarView.colors[i]).frame(width: pt(30), height: pt(30))
                                    .overlay(Circle().stroke(.white, lineWidth: 2).padding(2).opacity(store.s.avatar == i ? 1 : 0))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Avatar colour \(i + 1)")
                            .accessibilityAddTraits(store.s.avatar == i ? .isSelected : [])
                        }
                    }
                    .padding(.top, pt(10))
                } else {
                    Text(store.trimmedName.isEmpty ? "Learner" : store.trimmedName)
                        .font(Theme.text(24, .bold)).foregroundColor(.black).padding(.top, pt(12))
                }
                HStack {
                    Text("Basics").font(Theme.text(13, .semibold)).foregroundColor(caption)
                    Spacer()
                    Text("\(store.basicsDone) of \(store.basicsTotal) sutras").font(Theme.text(13, .medium)).foregroundColor(caption)
                }
                .padding(.top, pt(14))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xe5e5ea))
                        Capsule().fill(Theme.blue).frame(width: g.size.width * CGFloat(store.basicsDone) / CGFloat(store.basicsTotal))
                    }
                }
                .frame(height: pt(6)).padding(.top, pt(6))
                .accessibilityHidden(true)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: pt(10)), GridItem(.flexible())], spacing: pt(10)) {
                    tile("Day streak", "\(store.streak) \(store.streak == 1 ? "day" : "days")", "flame.fill")
                    tile("Badges", "\(store.earned.filter { $0 }.count) of 4", "star.fill")
                    tile("Quizzes taken", "\(store.s.history.count)", "doc.text.fill")
                    tile("Member since", joined, "calendar")
                }
                .padding(.top, pt(14))
            }
            .padding(EdgeInsets(top: pt(22), leading: pt(20), bottom: pt(18), trailing: pt(20)))
            .background(RoundedRectangle(cornerRadius: pt(16), style: .continuous).fill(.white))

            captionText("Badges").padding(.top, pt(16))
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let got = store.earned[i]
                    Image(systemName: got ? "star.fill" : "lock.fill")
                        .font(.system(size: pt(20), weight: .semibold))
                        .foregroundColor(got ? .white : Color(hex: 0xaeaeb2))
                        .frame(width: pt(52), height: pt(52))
                        .background(Circle().fill(got ? Theme.blue : bg))
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(got ? "Badge earned" : "Badge locked")
                }
            }
            .padding(.vertical, pt(12))
            .background(RoundedRectangle(cornerRadius: pt(16), style: .continuous).fill(.white))

            captionText("This week").padding(.top, pt(16))
            weekBars
        }
    }

    private var weekBars: some View {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let days = (0..<7).map { cal.date(byAdding: .day, value: $0, to: start) ?? start }
        let vals = days.map { store.seconds(on: $0) }, peak = max(vals.max() ?? 1, 60)
        return HStack(alignment: .bottom, spacing: pt(14)) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: pt(4)) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: pt(4))
                        .fill(cal.isDateInToday(days[i]) ? Theme.blue : Color(hex: 0xc7c7cc))
                        .frame(height: pt(max(4, 54 * CGFloat(vals[i]) / CGFloat(peak))))
                    Text(String(Array("MTWTFSS")[i])).font(Theme.text(11, .medium)).foregroundColor(Color(hex: 0x8e8e93))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
        .padding(.horizontal, pt(16)).padding(.vertical, pt(8))
        .frame(height: pt(92))
        .background(RoundedRectangle(cornerRadius: pt(16), style: .continuous).fill(.white))
    }

    private func tile(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: pt(10)) {
            Image(systemName: icon).font(.system(size: pt(15))).foregroundColor(Color(hex: 0x636366))
                .frame(width: pt(34), height: pt(34))
                .background(RoundedRectangle(cornerRadius: pt(9)).fill(.white))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(Theme.text(15, .bold)).foregroundColor(.black).lineLimit(1).minimumScaleFactor(0.7)
                Text(label).font(Theme.text(12, .medium)).foregroundColor(caption).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(pt(8))
        .background(RoundedRectangle(cornerRadius: pt(12)).fill(Color(hex: 0xf5f6f8)))
        .accessibilityElement(children: .combine)
    }

    private func captionText(_ s: String) -> some View {
        Text(s.uppercased()).font(Theme.text(13, .regular)).foregroundColor(caption)
            .padding(.leading, pt(16)).padding(.bottom, pt(7))
    }

    // MARK: settings list

    private var list: some View {
        @Bindable var store = store
        return List {
            if !layout.wide {
                Section {
                    left
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                row("applelogo", .black, "Sign in with Apple", value: store.s.signedIn ? "Signed in" : "Not signed in", chevron: !store.s.signedIn) {
                    guard !store.s.signedIn else { return }
                    AppleSignIn.shared.start { ok in
                        if ok { store.s.signedIn = true } else { nav.flash("Sign in didn\u{2019}t finish.") }
                    }
                }
            } header: { header("Account") }

            Section {
                toggleRow("icloud.fill", Theme.blue, "Sync with iCloud", $store.s.icloud)
            } header: { header("iCloud") } footer: {
                footer(store.s.icloud ? "Your progress, badges and streak stay in sync on every iPhone and iPad signed in to your Apple Account. Last synced just now." : "Progress is saved on this \(device) only.")
            }

            Section {
                toggleRow("speaker.wave.2.fill", Color(hex: 0xff9500), "Narration", $store.s.narrationOn)
                row("globe", Color(hex: 0x34c759), "Language", value: "English", chevron: false) {}
                row("bell.fill", Color(hex: 0xff3b30), "Daily reminder", value: store.s.remOn ? store.clock(store.s.rem) : "Off") { showProgress() }
                toggleRow("iphone.radiowaves.left.and.right", Color(hex: 0xff2d55), "Sounds & Haptics", $store.s.haptics)
            } header: { header("Learning") }

            Section {
                row("person.2.fill", Color(hex: 0x5856d6), "Parent dashboard") { showProgress() }
            } header: { header("Family") }

            Section {
                row("questionmark", Theme.blue, "Help & Support") { open("https://vedica.app/help") }
                row("star.fill", Color(hex: 0xffcc00), "Rate Vedica") { requestReview() }
                row("hand.raised.fill", Color(hex: 0x8e8e93), "Privacy Policy") { open("https://vedica.app/privacy") }
                row("doc.text.fill", Color(hex: 0x8e8e93), "Terms of Use") { open("https://vedica.app/terms") }
            } header: { header("Support") }

            Section {
                Button { deleting = true } label: {
                    Text("Delete Account").font(Theme.text(17, .regular)).foregroundColor(Color(hex: 0xff3b30))
                        .frame(maxWidth: .infinity)
                }
            } footer: {
                Text("Vedica 1.0 (1)").font(Theme.text(13, .regular)).foregroundColor(Color(hex: 0x8e8e93))
                    .frame(maxWidth: .infinity).padding(.top, pt(6))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .environment(\.defaultMinListRowHeight, pt(48))
        .listSectionSpacing(.custom(pt(18)))
    }

    private func showProgress() {
        nav.closeFlow()
        nav.select(.progress)
    }

    private func open(_ url: String) { if let u = URL(string: url) { openURL(u) } }

    private func header(_ s: String) -> some View {
        Text(s).font(Theme.text(13, .regular)).foregroundColor(caption)
    }

    private func footer(_ s: String) -> some View {
        Text(s).font(Theme.text(13, .regular)).foregroundColor(caption)
    }

    private func glyph(_ s: String, _ c: Color) -> some View {
        Image(systemName: s).font(.system(size: pt(15), weight: .semibold)).foregroundColor(.white)
            .frame(width: pt(29), height: pt(29))
            .background(RoundedRectangle(cornerRadius: pt(7), style: .continuous).fill(c))
            .accessibilityHidden(true)
    }

    private func row(_ icon: String, _ c: Color, _ title: String, value: String? = nil, chevron: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: pt(13)) {
                glyph(icon, c)
                Text(title).font(Theme.text(17, .regular)).foregroundColor(.black)
                    .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                Spacer()
                if let value { Text(value).font(Theme.text(17, .regular)).foregroundColor(Color(hex: 0x8e8e93)) }
                if chevron {
                    Image(systemName: "chevron.right").font(.system(size: pt(13), weight: .semibold)).foregroundColor(Color(hex: 0xc7c7cc))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .listRowBackground(Color.white)
    }

    private func toggleRow(_ icon: String, _ c: Color, _ title: String, _ on: Binding<Bool>) -> some View {
        Toggle(isOn: on) {
            HStack(spacing: pt(13)) {
                glyph(icon, c)
                Text(title).font(Theme.text(17, .regular)).foregroundColor(.black)
                    .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            }
        }
        .tint(Color(hex: 0x34c759))
        .listRowBackground(Color.white)
    }
}
