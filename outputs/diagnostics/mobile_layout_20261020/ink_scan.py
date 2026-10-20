"""Where the ink is in each plot image Shiny sent: a line of text running off the image is cut, so ink in the
outermost 2 px columns or rows of a plot is the signature of a clipped legend, caption or title.
stdlib only (a minimal PNG decoder: 8-bit RGB/RGBA/gray/palette, no interlace).
Usage: ink_scan.py <png dir> [<png dir> ...]   -> one row per image: name, w, h, ink x0-x1, ink y0-y1, EDGE flag
'Ink' = any channel darker than 200 of 255 (plot backgrounds and the lightest grid lines are above that)."""
import sys, os, zlib, struct

def read_png(path):
    d = open(path, 'rb').read(); assert d[:8] == b'\x89PNG\r\n\x1a\n', path
    pos = 8; idat = b''; plte = None
    while pos < len(d):
        n = struct.unpack('>I', d[pos:pos + 4])[0]; t = d[pos + 4:pos + 8]; c = d[pos + 8:pos + 8 + n]; pos += 12 + n
        if t == b'IHDR': w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', c); assert bd == 8 and il == 0, path
        elif t == b'PLTE': plte = c
        elif t == b'IDAT': idat += c
    raw = zlib.decompress(idat); bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]; stride = w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line)); prev = line
    def dark(x, y):
        r = rows[y]
        if ct == 3: k = r[x]; px = plte[3 * k:3 * k + 3]
        elif ct in (2, 6): px = r[x * bpp:x * bpp + 3]
        else: px = r[x * bpp:x * bpp + 1]
        return min(px) < 200
    return w, h, dark

for d in sys.argv[1:]:
    for nm in sorted(os.listdir(d)):
        if not nm.endswith('.png'): continue
        w, h, dark = read_png(os.path.join(d, nm))
        xs, ys = [], []
        for y in range(h):
            for x in range(w):
                if dark(x, y): xs.append(x); ys.append(y)
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        edge = x0 <= 1 or x1 >= w - 2 or y0 <= 1 or y1 >= h - 2
        print(f"{nm:38s} {w:5d} {h:5d}  x {x0:4d}-{x1:4d}  y {y0:4d}-{y1:4d}  {'EDGE' if edge else ''}")
