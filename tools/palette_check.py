#!/usr/bin/env python3
"""OKLab dE between colours, under normal vision and the three dichromacies.

WHY THIS EXISTS. The `dataviz` skill ships a palette validator that needs
`node`, and `node` is NOT installed on this machine (2026-09-24). Rather than
eyeball a pair, the check it performs is reimplemented here: sRGB -> linear ->
LMS, the Vienot-Brettel-Mollon dichromat projection, back to sRGB, then OKLab
dE between the simulated pair. First used for calibration/fig_land_sink_vs_gcb.R
(CHANGELOG 2026-09-24 k), which is where the repo's model pink was re-stepped
after scoring dE 7.9 under protanopia.

Usage:  python3 tools/palette_check.py '#C2185B' '#12395C' [more colours...]
        every PAIR is scored; the minimum over the four vision types is the
        number that matters, and the target is >= DE_TARGET.
"""
import sys, itertools, math

DE_TARGET = 8.0     # OKLab dE below this is not reliably distinguishable

def srgb_to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def lin_to_srgb(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

def hex_to_lin(h):
    h = h.lstrip('#')
    return [srgb_to_lin(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)]

# Hunt-Pointer-Estevez style LMS used by Vienot, Brettel & Mollon (1999)
RGB2LMS = ((17.8824, 43.5161, 4.11935),
           (3.45565, 27.1554, 3.86714),
           (0.0299566, 0.184309, 1.46709))
LMS2RGB = ((0.0809444479, -0.130504409, 0.116721066),
           (-0.0102485335, 0.0540193266, -0.113614708),
           (-0.000365296938, -0.00412161469, 0.693511405))
# the dichromat projection planes (Vienot et al. 1999, Table 1)
PROJ = {
    'protan': ((0, 2.02344, -2.52581), (0, 1, 0), (0, 0, 1)),
    'deutan': ((1, 0, 0), (0.494207, 0, 1.24827), (0, 0, 1)),
    'tritan': ((1, 0, 0), (0, 1, 0), (-0.395913, 0.801109, 0)),
}

def mv(m, v):
    return [sum(m[i][j] * v[j] for j in range(3)) for i in range(3)]

def simulate(lin, kind):
    if kind == 'normal':
        return lin
    lms = mv(RGB2LMS, lin)
    lms = mv(PROJ[kind], lms)
    return mv(LMS2RGB, lms)

def lin_to_oklab(lin):
    l = 0.4122214708 * lin[0] + 0.5363325363 * lin[1] + 0.0514459929 * lin[2]
    m = 0.2119034982 * lin[0] + 0.6806995451 * lin[1] + 0.1073969566 * lin[2]
    s = 0.0883024619 * lin[0] + 0.2817188376 * lin[1] + 0.6299787005 * lin[2]
    l_, m_, s_ = (math.copysign(abs(x) ** (1 / 3), x) for x in (l, m, s))
    return (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)

def de(a, b, kind):
    pa = [srgb_to_lin(lin_to_srgb(x)) for x in simulate(hex_to_lin(a), kind)]
    pb = [srgb_to_lin(lin_to_srgb(x)) for x in simulate(hex_to_lin(b), kind)]
    la, lb = lin_to_oklab(pa), lin_to_oklab(pb)
    return 100 * math.sqrt(sum((la[i] - lb[i]) ** 2 for i in range(3)))

def main(cols):
    kinds = ('normal', 'protan', 'deutan', 'tritan')
    print(f"{'pair':<20}" + "".join(f"{k:>9}" for k in kinds) + f"{'min':>9}  verdict")
    worst = None
    for a, b in itertools.combinations(cols, 2):
        d = [de(a, b, k) for k in kinds]
        lo = min(d)
        worst = lo if worst is None else min(worst, lo)
        print(f"{a}/{b:<12}" + "".join(f"{x:9.1f}" for x in d) + f"{lo:9.1f}  "
              + ("PASS" if lo >= DE_TARGET else "FAIL"))
    print(f"\nminimum over all pairs and vision types: {worst:.1f} (target >= {DE_TARGET})")
    return 0 if worst >= DE_TARGET else 1

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(2)
    sys.exit(main(sys.argv[1:]))
