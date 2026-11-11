// Handwritten digit recognizer ($P point-cloud) for Vedica answer boxes.
(function () {
  const N = 40, PI = Math.PI;
  const arc = (cx, cy, rx, ry, t0, t1, n = 28) => { const p = []; for (let i = 0; i <= n; i++) { const t = t0 + (t1 - t0) * i / n; p.push([cx + rx * Math.cos(t), cy + ry * Math.sin(t)]); } return p; };
  const line = (...pts) => { const p = []; for (let i = 0; i < pts.length - 1; i++) { const a = pts[i], b = pts[i + 1]; for (let j = 0; j < 12; j++) p.push([a[0] + (b[0] - a[0]) * j / 12, a[1] + (b[1] - a[1]) * j / 12]); } p.push(pts[pts.length - 1]); return p; };
  const RAW = {
    0: [[arc(.5, .5, .32, .5, -PI / 2, 1.5 * PI)], [arc(.5, .5, .42, .5, -PI / 2, 1.5 * PI)]],
    1: [[line([.5, 0], [.5, 1])], [line([.25, .22], [.5, 0], [.5, 1])], [line([.25, .22], [.5, 0], [.5, 1]), line([.25, 1], [.75, 1])]],
    2: [[arc(.5, .3, .36, .3, -2.8, .45).concat(line([.82, .43], [.1, 1], [.9, 1]))], [arc(.5, .28, .34, .28, -2.9, .2).concat(line([.84, .34], [.12, 1], [.92, .98]))]],
    3: [[arc(.5, .26, .3, .26, -2.6, PI / 2).concat(arc(.5, .75, .33, .25, -PI / 2, 2.6))], [line([.15, 0], [.85, 0], [.45, .42]).concat(arc(.5, .7, .32, .3, -PI / 2, 2.6))]],
    4: [[line([.62, 0], [.08, .68], [.92, .68]), line([.66, .35], [.66, 1])], [line([.2, 0], [.12, .62], [.88, .62]), line([.7, 0], [.7, 1])], [line([.2, 0], [.12, .62], [.88, .62]).concat(line([.7, .3], [.7, 1]))]],
    5: [[line([.85, 0], [.28, 0], [.22, .42]).concat(arc(.5, .68, .33, .32, -2.5, 2.5))], [line([.28, 0], [.22, .42]).concat(arc(.5, .68, .33, .32, -2.5, 2.5)), line([.28, 0], [.85, 0])]],
    6: [[line([.72, 0], [.4, .2], [.2, .55]).concat(arc(.5, .7, .3, .3, PI, 3 * PI))], [arc(.6, .55, .4, .55, -1.6, -PI).concat(arc(.5, .72, .3, .28, PI, 3 * PI))]],
    7: [[line([.1, 0], [.9, 0], [.38, 1])], [line([.1, 0], [.9, 0], [.38, 1]), line([.35, .5], [.8, .5])], [line([.1, .15], [.1, 0], [.9, 0], [.45, 1])]],
    8: [[arc(.5, .25, .24, .25, 0, 2 * PI), arc(.5, .73, .29, .27, 0, 2 * PI)]],
    9: [[arc(.5, .3, .3, .3, 0, 2 * PI).concat(line([.8, .3], [.78, 1]))], [arc(.5, .3, .3, .3, 0, 2 * PI).concat(line([.8, .3], [.75, .8], [.5, 1]))]],
  };
  const pathLen = (s) => { let d = 0; for (let i = 1; i < s.length; i++) d += Math.hypot(s[i][0] - s[i - 1][0], s[i][1] - s[i - 1][1]); return d; };
  function resample(strokes, n) {
    const L = strokes.reduce((a, s) => a + pathLen(s), 0), I = L / (n - 1) || 1, out = [];
    let D = 0;
    for (const s0 of strokes) {
      if (!s0.length) continue;
      const s = s0.map(p => [p[0], p[1]]);
      if (!out.length) out.push(s[0]);
      for (let i = 1; i < s.length; i++) {
        const d = Math.hypot(s[i][0] - s[i - 1][0], s[i][1] - s[i - 1][1]);
        if (D + d >= I && d > 0) {
          const t = (I - D) / d, q = [s[i - 1][0] + t * (s[i][0] - s[i - 1][0]), s[i - 1][1] + t * (s[i][1] - s[i - 1][1])];
          out.push(q); s.splice(i, 0, q); D = 0;
        } else D += d;
      }
    }
    while (out.length < n) out.push(out[out.length - 1]);
    return out.slice(0, n);
  }
  function normalize(pts) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    pts.forEach(([x, y]) => { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); });
    const sc = Math.max(x1 - x0, y1 - y0) || 1;
    let p = pts.map(([x, y]) => [(x - x0) / sc, (y - y0) / sc]);
    const cx = p.reduce((a, q) => a + q[0], 0) / p.length, cy = p.reduce((a, q) => a + q[1], 0) / p.length;
    return p.map(([x, y]) => [x - cx, y - cy]);
  }
  const prep = (strokes) => normalize(resample(strokes, N));
  function cloudDist(a, b, start) {
    const n = a.length, used = new Array(n).fill(false); let sum = 0, i = start;
    do {
      let min = Infinity, idx = 0;
      for (let j = 0; j < n; j++) if (!used[j]) { const d = (a[i][0] - b[j][0]) ** 2 + (a[i][1] - b[j][1]) ** 2; if (d < min) { min = d; idx = j; } }
      used[idx] = true; sum += (1 - ((i - start + n) % n) / n) * Math.sqrt(min); i = (i + 1) % n;
    } while (i !== start);
    return sum;
  }
  function match(a, b) { const step = Math.floor(Math.sqrt(N)); let m = Infinity; for (let i = 0; i < N; i += step) m = Math.min(m, cloudDist(a, b, i), cloudDist(b, a, i)); return m; }
  const TPL = []; Object.entries(RAW).forEach(([d, vs]) => vs.forEach(v => TPL.push([d, prep(v)])));

  function bbox(strokes) { let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity; strokes.forEach(s => s.forEach(([x, y]) => { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); })); return { x0, y0, x1, y1, w: x1 - x0, h: y1 - y0 }; }
  function digit(strokes) {
    const b = bbox(strokes);
    if (b.h > 0 && b.w / b.h < 0.28 && strokes.length <= 2) return '1';
    const p = prep(strokes); let best = null, bd = Infinity;
    for (const [d, t] of TPL) { const s = match(p, t); if (s < bd) { bd = s; best = d; } }
    return best;
  }
  function recognize(strokes) {
    strokes = strokes.filter(s => s.length > 1);
    if (!strokes.length) return '';
    const H = bbox(strokes).h || 1, tol = H * 0.08;
    const items = strokes.map(s => ({ s, b: bbox([s]) })).sort((a, c) => a.b.x0 - c.b.x0), groups = [];
    for (const it of items) {
      const g = groups.find(g => Math.min(g.x1, it.b.x1) - Math.max(g.x0, it.b.x0) > -tol);
      if (g) { g.s.push(it.s); g.x0 = Math.min(g.x0, it.b.x0); g.x1 = Math.max(g.x1, it.b.x1); }
      else groups.push({ s: [it.s], x0: it.b.x0, x1: it.b.x1 });
    }
    groups.sort((a, c) => a.x0 - c.x0);
    return groups.map(g => digit(g.s) || '').join('');
  }
  window.VedicaInk = { recognize };
})();
