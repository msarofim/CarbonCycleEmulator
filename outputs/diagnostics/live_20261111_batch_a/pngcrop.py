"""Crop and upscale (nearest) a PNG with zlib only. Usage: pngcrop.py in out x0 y0 x1 y1 scale"""
import sys, zlib, struct
def read(p):
    b = open(p, 'rb').read(); assert b[:8] == b'\x89PNG\r\n\x1a\n'; i = 8; idat = b''
    while i < len(b):
        n, t = struct.unpack('>I4s', b[i:i+8]); d = b[i+8:i+8+n]; i += 12 + n
        if t == b'IHDR': W, H, bd, ct = struct.unpack('>IIBB', d[:10])
        elif t == b'IDAT': idat += d
    assert bd == 8 and ct in (2, 6); bpp = 3 if ct == 2 else 4; raw = zlib.decompress(idat); st = W * bpp; rows = []; prev = bytearray(st); k = 0
    for y in range(H):
        f = raw[k]; line = bytearray(raw[k+1:k+1+st]); k += 1 + st
        for x in range(st):
            a = line[x-bpp] if x >= bpp else 0; c = prev[x-bpp] if x >= bpp else 0; u = prev[x]
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + u) & 255
            elif f == 3: line[x] = (line[x] + (a + u) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(u - c), abs(a - c), abs(a + u - 2 * c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else u if pb <= pc else c)) & 255
        rows.append(line); prev = line
    return W, H, bpp, rows
def write(p, W, H, rows):
    raw = b''.join(b'\x00' + bytes(r) for r in rows)
    ch = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(p, 'wb').write(b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)) + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b''))
src, dst = sys.argv[1], sys.argv[2]; x0, y0, x1, y1, s = map(int, sys.argv[3:8])
W, H, bpp, rows = read(src); out = []
for y in range(y0, y1):
    r = bytearray()
    for x in range(x0, x1): r += bytes(rows[y][x*bpp:x*bpp+3]) * s
    out += [r] * s
write(dst, (x1 - x0) * s, (y1 - y0) * s, out); print(W, H, '->', (x1 - x0) * s, (y1 - y0) * s)
