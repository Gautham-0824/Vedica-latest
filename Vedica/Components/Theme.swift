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
        Fonts.font("Nunito", size, weight) ?? .system(size: size, weight: weight, design: .rounded)
    }
    /// DM Sans, the artifact's text face (bundled).
    static func text(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        Fonts.font("DMSans", size, weight) ?? .system(size: size, weight: weight)
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

/// Current design canvas, kept up to date by `CanvasFit` so screens re-lay out on rotation.
@Observable
final class CanvasMetrics {
    static let shared = CanvasMetrics()
    var w: CGFloat = 1024
    var h: CGFloat = 768
    var portrait = false
}

/// Landscape screens start from 1024 x 768 and portrait from 768 x 1024; the longer side then grows to fill the window.
enum Canvas {
    static var w: CGFloat { CanvasMetrics.shared.w }
    static var h: CGFloat { CanvasMetrics.shared.h }
    static var portrait: Bool { CanvasMetrics.shared.portrait }
    /// Space left over around a fixed 1024 x 768 layout, so it can sit in the middle of the screen.
    static var extraX: CGFloat { max(0, (w - 1024) / 2) }
    static var extraY: CGFloat { max(0, (h - 768) / 2) }
}

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
