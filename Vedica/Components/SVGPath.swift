import SwiftUI

/// Minimal SVG path-data parser so the web build's icon paths and the pointing-hand
/// outline can be reused verbatim. Supports M m L l H h V v C c S s Q q T t A a Z z.
enum SVGPath {
    private enum Token { case cmd(Character); case num(Double) }

    private static func tokenize(_ d: String) -> [Token] {
        var out: [Token] = []
        let chars = Array(d)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch.isLetter && ch != "e" && ch != "E" {
                out.append(.cmd(ch)); i += 1
            } else if ch == "-" || ch == "+" || ch == "." || ch.isNumber {
                var s = ""
                var seenDot = false
                var seenExp = false
                var j = i
                if chars[j] == "-" || chars[j] == "+" { s.append(chars[j]); j += 1 }
                while j < chars.count {
                    let c = chars[j]
                    if c.isNumber { s.append(c); j += 1 }
                    else if c == "." && !seenDot && !seenExp { seenDot = true; s.append(c); j += 1 }
                    else if (c == "e" || c == "E") && !seenExp && j + 1 < chars.count {
                        seenExp = true; s.append(c); j += 1
                        if chars[j] == "-" || chars[j] == "+" { s.append(chars[j]); j += 1 }
                    } else { break }
                }
                if let v = Double(s) { out.append(.num(v)) }
                i = max(j, i + 1)
            } else {
                i += 1
            }
        }
        return out
    }

    static func parse(_ d: String) -> Path {
        let toks = tokenize(d)
        var path = Path()
        var idx = 0
        var cur = CGPoint.zero
        var start = CGPoint.zero
        var lastCtl: CGPoint? = nil      // last cubic control (for S)
        var lastQ: CGPoint? = nil        // last quad control (for T)
        var cmd: Character = "M"

        func hasNum() -> Bool { if idx < toks.count, case .num = toks[idx] { return true }; return false }
        func num() -> Double {
            if idx < toks.count, case .num(let v) = toks[idx] { idx += 1; return v }
            return 0
        }
        func flag() -> Bool { return num() != 0 }

        while idx < toks.count {
            if case .cmd(let c) = toks[idx] { cmd = c; idx += 1 }
            else if !hasNum() { idx += 1; continue }
            let rel = cmd.isLowercase
            let up = Character(cmd.uppercased())
            switch up {
            case "M":
                let x = num(), y = num()
                cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                start = cur
                path.move(to: cur)
                cmd = rel ? "l" : "L"
                lastCtl = nil; lastQ = nil
            case "L":
                let x = num(), y = num()
                cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                path.addLine(to: cur); lastCtl = nil; lastQ = nil
            case "H":
                let x = num()
                cur = CGPoint(x: rel ? cur.x + x : x, y: cur.y)
                path.addLine(to: cur); lastCtl = nil; lastQ = nil
            case "V":
                let y = num()
                cur = CGPoint(x: cur.x, y: rel ? cur.y + y : y)
                path.addLine(to: cur); lastCtl = nil; lastQ = nil
            case "C":
                let x1 = num(), y1 = num(), x2 = num(), y2 = num(), x = num(), y = num()
                let o = rel ? cur : .zero
                let c1 = CGPoint(x: o.x + x1, y: o.y + y1)
                let c2 = CGPoint(x: o.x + x2, y: o.y + y2)
                let e = CGPoint(x: o.x + x, y: o.y + y)
                path.addCurve(to: e, control1: c1, control2: c2)
                cur = e; lastCtl = c2; lastQ = nil
            case "S":
                let x2 = num(), y2 = num(), x = num(), y = num()
                let o = rel ? cur : .zero
                let c1 = lastCtl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: o.x + x2, y: o.y + y2)
                let e = CGPoint(x: o.x + x, y: o.y + y)
                path.addCurve(to: e, control1: c1, control2: c2)
                cur = e; lastCtl = c2; lastQ = nil
            case "Q":
                let x1 = num(), y1 = num(), x = num(), y = num()
                let o = rel ? cur : .zero
                let c1 = CGPoint(x: o.x + x1, y: o.y + y1)
                let e = CGPoint(x: o.x + x, y: o.y + y)
                path.addQuadCurve(to: e, control: c1)
                cur = e; lastQ = c1; lastCtl = nil
            case "T":
                let x = num(), y = num()
                let o = rel ? cur : .zero
                let c1 = lastQ.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let e = CGPoint(x: o.x + x, y: o.y + y)
                path.addQuadCurve(to: e, control: c1)
                cur = e; lastQ = c1; lastCtl = nil
            case "A":
                let rx = num(), ry = num(), rot = num()
                let large = flag(), sweep = flag()
                let x = num(), y = num()
                let e = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                addArc(&path, from: cur, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep, to: e)
                cur = e; lastCtl = nil; lastQ = nil
            case "Z":
                path.closeSubpath(); cur = start; lastCtl = nil; lastQ = nil
            default:
                idx += 1
            }
        }
        return path
    }

    private static func addArc(_ path: inout Path, from p1: CGPoint, rx rxIn: Double, ry ryIn: Double,
                               rotation: Double, large: Bool, sweep: Bool, to p2: CGPoint) {
        if p1 == p2 { return }
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 { path.addLine(to: p2); return }
        let phi = rotation * Double.pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx2 = Double(p1.x - p2.x) / 2, dy2 = Double(p1.y - p2.y) / 2
        let x1p = cosP * dx2 + sinP * dy2
        let y1p = -sinP * dx2 + cosP * dy2
        let lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lam > 1 { let s = lam.squareRoot(); rx *= s; ry *= s }
        let sign: Double = (large == sweep) ? -1 : 1
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        let coef = sign * (max(0, num / den)).squareRoot()
        let cxp = coef * (rx * y1p / ry)
        let cyp = coef * (-ry * x1p / rx)
        let cx = cosP * cxp - sinP * cyp + Double(p1.x + p2.x) / 2
        let cy = sinP * cxp + cosP * cyp + Double(p1.y + p2.y) / 2
        func ang(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let dot = ux * vx + uy * vy
            let len = (ux * ux + uy * uy).squareRoot() * (vx * vx + vy * vy).squareRoot()
            var a = acos(max(-1, min(1, dot / len)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }
        let theta1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var dtheta = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && dtheta > 0 { dtheta -= 2 * Double.pi }
        if sweep && dtheta < 0 { dtheta += 2 * Double.pi }
        let segs = max(1, Int(ceil(abs(dtheta) / (Double.pi / 2) - 1e-9)))
        let delta = dtheta / Double(segs)
        let t = 4.0 / 3.0 * tan(delta / 4)
        var a = theta1
        func pt(_ ang: Double) -> (Double, Double, Double, Double) {
            let ca = cos(ang), sa = sin(ang)
            let x = cx + rx * ca * cosP - ry * sa * sinP
            let y = cy + rx * ca * sinP + ry * sa * cosP
            let dxv = -rx * sa * cosP - ry * ca * sinP
            let dyv = -rx * sa * sinP + ry * ca * cosP
            return (x, y, dxv, dyv)
        }
        for _ in 0..<segs {
            let s = pt(a), e = pt(a + delta)
            let c1 = CGPoint(x: s.0 + t * s.2, y: s.1 + t * s.3)
            let c2 = CGPoint(x: e.0 - t * e.2, y: e.1 - t * e.3)
            path.addCurve(to: CGPoint(x: e.0, y: e.1), control1: c1, control2: c2)
            a += delta
        }
    }
}

/// A SwiftUI shape for an SVG path drawn in a viewBox, scaled to the frame it is given.
struct SVGShape: Shape {
    let d: String
    var viewBox: CGRect = CGRect(x: 0, y: 0, width: 24, height: 24)
    func path(in rect: CGRect) -> Path {
        let p = SVGPath.parse(d)
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        let t = CGAffineTransform(translationX: -viewBox.minX, y: -viewBox.minY)
            .concatenating(CGAffineTransform(scaleX: sx, y: sy))
        return p.applying(t)
    }
}

/// Stroked 24x24 icon with the web build's round caps/joins.
struct Icon: View {
    let d: String
    var size: CGFloat = 24
    var stroke: CGFloat = 2.4
    var color: Color = Theme.ink
    var filled: Bool = false
    var body: some View {
        Group {
            if filled {
                SVGShape(d: d).fill(color)
            } else {
                SVGShape(d: d).stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }
}
