import CoreGraphics
import Foundation

/// Handwritten digit recogniser ($P point cloud). Straight port of vedica-ink.js.
enum InkRecognizer {
    typealias P = (x: Double, y: Double)
    private static let N = 40

    private static func arc(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double,
                            _ t0: Double, _ t1: Double, _ n: Int = 28) -> [P] {
        (0...n).map { i in
            let t = t0 + (t1 - t0) * Double(i) / Double(n)
            return (cx + rx * cos(t), cy + ry * sin(t))
        }
    }

    private static func line(_ pts: P...) -> [P] {
        var p: [P] = []
        for i in 0..<(pts.count - 1) {
            let a = pts[i], b = pts[i + 1]
            for j in 0..<12 {
                let f = Double(j) / 12
                p.append((a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f))
            }
        }
        p.append(pts[pts.count - 1])
        return p
    }

    // digit -> variants -> strokes -> points
    private static let RAW: [(Character, [[[P]]])] = {
        let pi = Double.pi
        var r: [(Character, [[[P]]])] = []

        r.append(("0", [
            [arc(0.5, 0.5, 0.32, 0.5, -pi / 2, 1.5 * pi)],
            [arc(0.5, 0.5, 0.42, 0.5, -pi / 2, 1.5 * pi)]
        ]))

        let one1: [P] = line((0.5, 0), (0.5, 1))
        let one2: [P] = line((0.25, 0.22), (0.5, 0), (0.5, 1))
        let one3: [P] = one2 + line((0.25, 1), (0.75, 1))
        r.append(("1", [[one1], [one2], [one3]]))

        let two1: [P] = arc(0.5, 0.3, 0.36, 0.3, -2.8, 0.45) + line((0.82, 0.43), (0.1, 1), (0.9, 1))
        let two2: [P] = arc(0.5, 0.28, 0.34, 0.28, -2.9, 0.2) + line((0.84, 0.34), (0.12, 1), (0.92, 0.98))
        r.append(("2", [[two1], [two2]]))

        let three1: [P] = arc(0.5, 0.26, 0.3, 0.26, -2.6, pi / 2) + arc(0.5, 0.75, 0.33, 0.25, -pi / 2, 2.6)
        let three2: [P] = line((0.15, 0), (0.85, 0), (0.45, 0.42)) + arc(0.5, 0.7, 0.32, 0.3, -pi / 2, 2.6)
        r.append(("3", [[three1], [three2]]))

        let four1a: [P] = line((0.62, 0), (0.08, 0.68), (0.92, 0.68))
        let four1b: [P] = line((0.66, 0.35), (0.66, 1))
        let four2a: [P] = line((0.2, 0), (0.12, 0.62), (0.88, 0.62))
        let four2b: [P] = line((0.7, 0), (0.7, 1))
        let four3: [P] = four2a + line((0.7, 0.3), (0.7, 1))
        r.append(("4", [[four1a, four1b], [four2a, four2b], [four3]]))

        let five1: [P] = line((0.85, 0), (0.28, 0), (0.22, 0.42)) + arc(0.5, 0.68, 0.33, 0.32, -2.5, 2.5)
        let five2a: [P] = line((0.28, 0), (0.22, 0.42)) + arc(0.5, 0.68, 0.33, 0.32, -2.5, 2.5)
        let five2b: [P] = line((0.28, 0), (0.85, 0))
        r.append(("5", [[five1], [five2a, five2b]]))

        let six1: [P] = line((0.72, 0), (0.4, 0.2), (0.2, 0.55)) + arc(0.5, 0.7, 0.3, 0.3, pi, 3 * pi)
        let six2: [P] = arc(0.6, 0.55, 0.4, 0.55, -1.6, -pi) + arc(0.5, 0.72, 0.3, 0.28, pi, 3 * pi)
        r.append(("6", [[six1], [six2]]))

        let seven1: [P] = line((0.1, 0), (0.9, 0), (0.38, 1))
        let seven2b: [P] = line((0.35, 0.5), (0.8, 0.5))
        let seven3: [P] = line((0.1, 0.15), (0.1, 0), (0.9, 0), (0.45, 1))
        r.append(("7", [[seven1], [seven1, seven2b], [seven3]]))

        let eightTop: [P] = arc(0.5, 0.25, 0.24, 0.25, 0, 2 * pi)
        let eightBot: [P] = arc(0.5, 0.73, 0.29, 0.27, 0, 2 * pi)
        r.append(("8", [[eightTop, eightBot]]))

        let nineLoop: [P] = arc(0.5, 0.3, 0.3, 0.3, 0, 2 * pi)
        let nine1: [P] = nineLoop + line((0.8, 0.3), (0.78, 1))
        let nine2: [P] = nineLoop + line((0.8, 0.3), (0.75, 0.8), (0.5, 1))
        r.append(("9", [[nine1], [nine2]]))

        return r
    }()

    private static func pathLen(_ s: [P]) -> Double {
        var d = 0.0
        if s.count > 1 { for i in 1..<s.count { d += hypot(s[i].x - s[i - 1].x, s[i].y - s[i - 1].y) } }
        return d
    }

    private static func resample(_ strokes: [[P]], _ n: Int) -> [P] {
        let L = strokes.reduce(0) { $0 + pathLen($1) }
        let I = (L / Double(n - 1)).isZero ? 1 : L / Double(n - 1)
        var out: [P] = []
        var D = 0.0
        for s0 in strokes {
            if s0.isEmpty { continue }
            var s = s0
            if out.isEmpty { out.append(s[0]) }
            var i = 1
            while i < s.count {
                let d = hypot(s[i].x - s[i - 1].x, s[i].y - s[i - 1].y)
                if D + d >= I && d > 0 {
                    let t = (I - D) / d
                    let q: P = (s[i - 1].x + t * (s[i].x - s[i - 1].x), s[i - 1].y + t * (s[i].y - s[i - 1].y))
                    out.append(q)
                    s.insert(q, at: i)
                    D = 0
                } else {
                    D += d
                }
                i += 1
            }
        }
        while out.count < n { out.append(out[out.count - 1]) }
        return Array(out.prefix(n))
    }

    private static func normalize(_ pts: [P]) -> [P] {
        var x0 = Double.infinity, y0 = Double.infinity, x1 = -Double.infinity, y1 = -Double.infinity
        for p in pts { x0 = min(x0, p.x); y0 = min(y0, p.y); x1 = max(x1, p.x); y1 = max(y1, p.y) }
        var sc = max(x1 - x0, y1 - y0)
        if sc == 0 { sc = 1 }
        let q = pts.map { (($0.x - x0) / sc, ($0.y - y0) / sc) as P }
        let cx = q.reduce(0) { $0 + $1.x } / Double(q.count)
        let cy = q.reduce(0) { $0 + $1.y } / Double(q.count)
        return q.map { ($0.x - cx, $0.y - cy) as P }
    }

    private static func prep(_ strokes: [[P]]) -> [P] { normalize(resample(strokes, N)) }

    private static func cloudDist(_ a: [P], _ b: [P], _ start: Int) -> Double {
        let n = a.count
        var used = [Bool](repeating: false, count: n)
        var sum = 0.0
        var i = start
        repeat {
            var mn = Double.infinity, idx = 0
            for j in 0..<n where !used[j] {
                let dx = a[i].x - b[j].x, dy = a[i].y - b[j].y
                let d = dx * dx + dy * dy
                if d < mn { mn = d; idx = j }
            }
            used[idx] = true
            sum += (1 - Double((i - start + n) % n) / Double(n)) * mn.squareRoot()
            i = (i + 1) % n
        } while i != start
        return sum
    }

    private static func match(_ a: [P], _ b: [P]) -> Double {
        let step = Int(Double(N).squareRoot())
        var m = Double.infinity
        var i = 0
        while i < N { m = min(m, cloudDist(a, b, i), cloudDist(b, a, i)); i += step }
        return m
    }

    private static let TPL: [(Character, [P])] = {
        var t: [(Character, [P])] = []
        for (d, variants) in RAW {
            for v in variants { t.append((d, prep(v))) }
        }
        return t
    }()

    private struct Box {
        var x0: Double, y0: Double, x1: Double, y1: Double
        var w: Double { x1 - x0 }
        var h: Double { y1 - y0 }
    }

    private static func bbox(_ strokes: [[P]]) -> Box {
        var b = Box(x0: .infinity, y0: .infinity, x1: -.infinity, y1: -.infinity)
        for s in strokes {
            for p in s {
                b.x0 = min(b.x0, p.x); b.y0 = min(b.y0, p.y)
                b.x1 = max(b.x1, p.x); b.y1 = max(b.y1, p.y)
            }
        }
        return b
    }

    private static func digit(_ strokes: [[P]]) -> String {
        let b = bbox(strokes)
        if b.h > 0 && b.w / b.h < 0.28 && strokes.count <= 2 { return "1" }
        let p = prep(strokes)
        var best: Character = "0", bd = Double.infinity
        for (d, t) in TPL {
            let s = match(p, t)
            if s < bd { bd = s; best = d }
        }
        return String(best)
    }

    /// Strokes are in any consistent coordinate space; returns the digits written left to right.
    static func recognize(_ input: [[CGPoint]]) -> String {
        var strokes: [[P]] = []
        for s in input where s.count > 1 {
            strokes.append(s.map { (x: Double($0.x), y: Double($0.y)) })
        }
        if strokes.isEmpty { return "" }
        var H = bbox(strokes).h
        if H == 0 { H = 1 }
        let tol = H * 0.08

        struct Item { var s: [P]; var b: Box }
        struct Group { var s: [[P]]; var x0: Double; var x1: Double }

        let items = strokes.map { Item(s: $0, b: bbox([$0])) }.sorted { $0.b.x0 < $1.b.x0 }
        var groups: [Group] = []
        for it in items {
            if let gi = groups.firstIndex(where: { min($0.x1, it.b.x1) - max($0.x0, it.b.x0) > -tol }) {
                groups[gi].s.append(it.s)
                groups[gi].x0 = min(groups[gi].x0, it.b.x0)
                groups[gi].x1 = max(groups[gi].x1, it.b.x1)
            } else {
                groups.append(Group(s: [it.s], x0: it.b.x0, x1: it.b.x1))
            }
        }
        groups.sort { $0.x0 < $1.x0 }
        return groups.map { digit($0.s) }.joined()
    }
}
