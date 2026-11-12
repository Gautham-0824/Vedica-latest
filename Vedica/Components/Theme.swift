import SwiftUI
import CoreText
import Observation

extension Color {
    /// 0xRRGGBB
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// Design tokens shared by the shell and every lesson.
/// Blue = the thing being read, orange = the thing being worked out, green = the finished answer.
enum Theme {
    static let ink    = Color(hex: 0x17233a)
    static let blue   = Color(hex: 0x0a84ff)
    static let orange = Color(hex: 0xe86f00)
    static let green  = Color(hex: 0x1a9e62)
    static let muted  = Color(hex: 0x8391a6)
    static let canvas = Color(hex: 0xfffefa)
    static let page   = Color(hex: 0xe8edf2)
    static let line   = Color(hex: 0xe1e8ef)
    static let dash   = Color(hex: 0xcbd7e3)
    static let ghost  = Color(hex: 0xc0ccd8)
    static let body   = Color(hex: 0x34425a)
    static let sub    = Color(hex: 0x6b7a90)
    static let soft   = Color(hex: 0xeaf3ff)
    static let panel  = Color(hex: 0xf5f8fb)
    static let shadow = Color(hex: 0x17233a)

    /// Nunito, the artifact's display face (bundled).
    static func round(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        let s = pt(size)
        return Fonts.font("Nunito", s, weight) ?? .system(size: s, weight: weight, design: .rounded)
    }
    /// DM Sans, the artifact's text face (bundled).
    static func text(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        let s = pt(size)
        return Fonts.font("DMSans", s, weight) ?? .system(size: s, weight: weight)
    }
    static func weight(_ w: Int) -> Font.Weight {
        switch w {
        case ...400: return .regular
        case 401...500: return .medium
        case 501...600: return .semibold
        case 601...700: return .bold
        case 701...800: return .heavy
        default: return .black
        }
    }
}

/// Live window metrics, kept up to date by `AdaptiveRoot` so screens re-lay out on rotation and resizing.
/// `k` is the size the design is drawn at: on iPad it is exactly the scale the old fixed 1024 x 768 canvas
/// had, so iPad looks the same as before. iPhone gets a floor of 0.75 so text stays readable.
@Observable
final class Metrics {
    static let shared = Metrics()
    /// Window size in points.
    var size = CGSize(width: 1024, height: 768)
    var k: CGFloat = 1

    /// Window size in design points (what the old canvas size was).
    var w: CGFloat { size.width / k }
    var h: CGFloat { size.height / k }
    var portrait: Bool { size.height > size.width }
    /// Narrow window: iPhone in portrait or a slim iPad split view.
    var compact: Bool { w < 700 }
    /// Short window: iPhone in landscape.
    var short: Bool { h < 700 }
    /// Room for the side-by-side (landscape) arrangement of a screen.
    var wide: Bool { !portrait && !compact }

    func update(_ s: CGSize) {
        guard s != size, s.width > 0, s.height > 0 else { return }
        let long = max(s.width, s.height), side = min(s.width, s.height)
        k = max(0.75, min(long / 1024, side / 768))
        size = s
    }
}

/// Design size scaled for the current window: `pt(36)` is 36 points on iPad.
func pt(_ v: CGFloat) -> CGFloat { v * Metrics.shared.k }

/// Loads the bundled variable fonts. Weight is set through the font's wght axis, as the web build does.
enum Fonts {
    private static let wght = 0x77676874 // 'wght'
    private static let base: [String: CTFontDescriptor] = {
        var out: [String: CTFontDescriptor] = [:]
        for name in ["Nunito", "DMSans"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "woff2"),
                  let data = try? Data(contentsOf: url),
                  let list = CTFontManagerCreateFontDescriptorsFromData(data as CFData) as? [CTFontDescriptor],
                  let d = list.first else { continue }
            out[name] = d
        }
        return out
    }()

    static func font(_ name: String, _ size: CGFloat, _ weight: Font.Weight) -> Font? {
        guard let d = base[name] else { return nil }
        let w: Int = weight == .black ? 900 : weight == .heavy ? 800 : weight == .bold ? 700 : weight == .semibold ? 600 : weight == .medium ? 500 : 400
        let attrs = [kCTFontVariationAttribute: [wght: w]] as CFDictionary
        return Font(CTFontCreateWithFontDescriptor(CTFontDescriptorCreateCopyWithAttributes(d, attrs), size, nil))
    }
}
