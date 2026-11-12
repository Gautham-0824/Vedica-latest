import SwiftUI

@main
struct VedicaApp: SwiftUI.App {
    init() {
        // iPhone: Apple's tab bar with its titles a touch smaller than the system default.
        if UIDevice.current.userInterfaceIdiom == .phone {
            let font = UIFont.systemFont(ofSize: 9.5, weight: .medium)
            UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .selected)
        }
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
        }
    }
}
