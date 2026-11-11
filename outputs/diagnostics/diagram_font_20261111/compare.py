"""Pixel comparison of PNG pairs (zlib only). Usage: python3 -I compare.py a.png b.png [a2.png b2.png ...]"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "pngtools.py")).read().split("src, dst = sys.argv[1]")[0])
def compare(a, b):
    Wa, Ha, ba, ra = read(a); Wb, Hb, bb, rb = read(b)
    if (Wa, Ha) != (Wb, Hb): return f"size differs {Wa}x{Ha} vs {Wb}x{Hb}"
    n = mx = 0
    for y in range(Ha):
        for x in range(Wa):
            d = max(abs(ra[y][x*ba+c] - rb[y][x*bb+c]) for c in range(3))
            if d: n += 1; mx = max(mx, d)
    return f"{n} of {Wa*Ha} pixels differ ({100*n/(Wa*Ha):.2f} %), max {mx}"
p = sys.argv[1:]
for a, b in zip(p[::2], p[1::2]): print(os.path.basename(a)[:34].ljust(34), "vs", os.path.basename(b).ljust(26), compare(a, b))
